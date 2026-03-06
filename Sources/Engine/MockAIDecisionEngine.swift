import Foundation

// MARK: - AI Decision Types

enum AIDecision {
    case buyProperty(spaceID: Int)
    case pass                           // Don't buy
    case payRent(to: String, amount: Int)
    case buildHouse(spaceID: Int)
    case buildHotel(spaceID: Int)
    case mortgageProperty(spaceID: Int)
    case proposeTrade(TradeProposal)
    case acceptTrade(TradeProposal)
    case rejectTrade(TradeProposal)
    case payBail
    case rollForJail
    case useGetOutOfJailCard
    case declareBankruptcy
}

// MARK: - Decision Reasoning

struct AIReasoning {
    var decision: AIDecision
    var reasoning: String
    var confidence: Double      // 0.0 - 1.0
    var tokensUsed: Int = 0
    var costUSD: Double = 0.0
}

// MARK: - MockAIDecisionEngine

/// Provides personality-scripted AI decisions without any API calls.
/// Used in Mock Mode for instant, deterministic-ish gameplay.
struct MockAIDecisionEngine {

    // MARK: - Primary Decision Method

    static func decide(
        player: AIPlayer,
        state: GameState,
        context: DecisionContext
    ) async -> AIReasoning {
        // Simulated thinking delay for realism (1-3 seconds)
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...3_000_000_000))

        switch context.situation {
        case .landedOnUnowned(let space):
            return decideToBuy(player: player, space: space, state: state)
        case .mustPayRent(let amount, let ownerID):
            return AIReasoning(
                decision: .payRent(to: ownerID, amount: amount),
                reasoning: rentResponseText(player: player, amount: amount),
                confidence: 1.0
            )
        case .inJail:
            return decideJailAction(player: player, state: state)
        case .buildOpportunity:
            return decideToBuild(player: player, state: state)
        case .tradeOpportunity:
            return decideToTrade(player: player, state: state)
        case .needsLiquidation:
            return decideLiquidation(player: player, state: state)
        }
    }

    // MARK: - Buy Decision

    private static func decideToBuy(player: AIPlayer, space: BoardSpace, state: GameState) -> AIReasoning {
        guard let price = space.price else {
            return AIReasoning(decision: .pass, reasoning: "No price — free space.", confidence: 1.0)
        }

        let affordabilityRatio = Double(player.cash) / Double(price)
        let shouldBuy: Bool

        switch player.personality {
        case .aggressive:
            shouldBuy = player.cash >= price && affordabilityRatio > 0.5
        case .conservative:
            shouldBuy = player.cash >= price * 2
        case .mathematical:
            // Buy if expected return is positive within 15 turns
            let expectedRent = Double(space.baseRent ?? 0) * 2.5
            shouldBuy = player.cash >= price && expectedRent * 15 > Double(price) * 0.8
        case .tradeShark:
            // Always buy for trading leverage
            shouldBuy = player.cash >= price
        case .chaoticEvil:
            // Almost always buy, even if risky
            shouldBuy = player.cash >= price || Bool.random()
        case .balanced:
            shouldBuy = player.cash >= Int(Double(price) * 1.3)
        }

        if shouldBuy {
            return AIReasoning(
                decision: .buyProperty(spaceID: space.id),
                reasoning: buyReasoningText(player: player, space: space, state: state),
                confidence: Double.random(in: 0.7...0.97)
            )
        } else {
            return AIReasoning(
                decision: .pass,
                reasoning: passReasoningText(player: player, space: space),
                confidence: Double.random(in: 0.6...0.9)
            )
        }
    }

    // MARK: - Jail Decision

    private static func decideJailAction(player: AIPlayer, state: GameState) -> AIReasoning {
        // Always use card if available
        if player.getOutOfJailCards > 0 {
            return AIReasoning(
                decision: .useGetOutOfJailCard,
                reasoning: "\(player.name) uses Get Out of Jail Free card immediately.",
                confidence: 0.95
            )
        }

        let isLateGame = state.turn > 80
        let ownsMonopoly = ColorGroup.allCases.contains { state.hasMonopoly(playerID: player.id, group: $0) }
        let ownedCount = player.ownedPropertyIDs.count
        // Late game + monopolies = jail is a safe harbor (collect rent, avoid landing on others)
        let jailIsDesirable = isLateGame && ownsMonopoly && ownedCount >= 6

        let decision: AIDecision
        let reasoning: String

        switch player.personality {
        case .aggressive:
            if jailIsDesirable {
                decision = .rollForJail
                reasoning = jailReasoningText(player: player, action: "stay",
                    detail: "Late game with monopolies — jail is a fortress. Collecting rent while opponents hit my properties.")
            } else if player.cash >= 50 {
                decision = .payBail
                reasoning = jailReasoningText(player: player, action: "bail",
                    detail: "Need to be out there acquiring territory. $50 is nothing.")
            } else {
                decision = .rollForJail
                reasoning = jailReasoningText(player: player, action: "roll", detail: "Can't afford bail — rolling for doubles.")
            }

        case .conservative:
            // Always roll to save $50 unless late game makes jail bad (few properties)
            decision = .rollForJail
            reasoning = jailReasoningText(player: player, action: "roll",
                detail: "$50 saved is $50 earned. Patience pays dividends.")

        case .mathematical:
            // EV calculation: paying $50 vs expected landing costs
            let avgRentExposure = state.board.compactMap { space -> Int? in
                guard space.ownerID != nil, space.ownerID != player.id, !space.isMortgaged else { return nil }
                return MonopolyRules.rent(for: space, in: state)
            }
            let expectedRent = avgRentExposure.isEmpty ? 0 : avgRentExposure.reduce(0, +) / max(avgRentExposure.count, 1)
            let boardDanger = Double(expectedRent) * 0.3 // ~30% chance of landing on any given owned property in next few moves

            if jailIsDesirable || boardDanger > 50 {
                decision = .rollForJail
                reasoning = jailReasoningText(player: player, action: "stay",
                    detail: "EV analysis: avg rent exposure $\(expectedRent), board danger score \(String(format: "%.0f", boardDanger)). Jail is +EV.")
            } else if player.cash >= 50 && boardDanger < 30 {
                decision = .payBail
                reasoning = jailReasoningText(player: player, action: "bail",
                    detail: "EV analysis: board danger \(String(format: "%.0f", boardDanger)) < 30. Paying $50 bail to pursue acquisitions.")
            } else {
                decision = .rollForJail
                reasoning = jailReasoningText(player: player, action: "roll",
                    detail: "Marginal EV — rolling to conserve the $50 optionality.")
            }

        case .tradeShark:
            // Wants board presence for trades
            if player.cash >= 50 && !jailIsDesirable {
                decision = .payBail
                reasoning = jailReasoningText(player: player, action: "bail",
                    detail: "Need to be circling the board — can't negotiate from behind bars.")
            } else {
                decision = .rollForJail
                reasoning = jailReasoningText(player: player, action: "roll",
                    detail: jailIsDesirable ? "Sitting tight — let them come to me for deals." : "Saving cash for future leverage.")
            }

        case .chaoticEvil:
            // Risk-weighted coin flip using risk trait
            let riskBias = Double(player.risk) / 100.0
            let payChance = riskBias * 0.7 // Higher risk trait = more likely to pay bail
            if player.cash >= 50 && Double.random(in: 0...1) < payChance {
                decision = .payBail
                reasoning = jailReasoningText(player: player, action: "bail",
                    detail: "BREAKING OUT! Can't contain this chaos behind bars! 🔥")
            } else {
                decision = .rollForJail
                reasoning = jailReasoningText(player: player, action: "roll",
                    detail: "Rolling the dice — literally. Let fate decide! 🎲")
            }

        case .balanced:
            // Pay early in the game, roll later
            if !isLateGame && player.cash >= 100 {
                decision = .payBail
                reasoning = jailReasoningText(player: player, action: "bail",
                    detail: "Early/mid game — worth $50 to stay active and acquire properties.")
            } else {
                decision = .rollForJail
                reasoning = jailReasoningText(player: player, action: "roll",
                    detail: isLateGame ? "Late game — rolling to save cash and avoid danger zones." : "Conserving cash — rolling for doubles.")
            }
        }

        return AIReasoning(decision: decision, reasoning: reasoning, confidence: Double.random(in: 0.7...0.92))
    }

    // MARK: - Build Decision

    private static func decideToBuild(player: AIPlayer, state: GameState) -> AIReasoning {
        let buildableSpaces = state.board.filter { space in
            MonopolyRules.canBuildHouse(on: space, for: player.id, in: state)
        }
        guard !buildableSpaces.isEmpty else {
            return AIReasoning(decision: .pass, reasoning: "No buildable properties.", confidence: 0.9)
        }

        // Personality-specific cash reserve multiplier
        let baseMultiplier: Double
        switch player.personality {
        case .aggressive:   baseMultiplier = 1.2
        case .conservative: baseMultiplier = 3.0
        case .mathematical: baseMultiplier = 2.0
        case .tradeShark:   baseMultiplier = 2.5
        case .chaoticEvil:  baseMultiplier = 0.8
        case .balanced:     baseMultiplier = 2.0
        }
        // Higher efficiency trait = slightly lower reserve needed
        let efficiencyDiscount = Double(player.efficiency) / 100.0 * 0.3 // up to 30% discount
        let reserveMultiplier = max(baseMultiplier * (1.0 - efficiencyDiscount), 0.5)

        // Personality-specific property selection
        let space: BoardSpace
        switch player.personality {
        case .aggressive, .chaoticEvil:
            // Build on highest-rent property first
            space = buildableSpaces.sorted { ($0.currentRent) > ($1.currentRent) }.first!
        case .conservative, .balanced:
            // Build on cheapest-cost property first (minimize outlay)
            space = buildableSpaces.sorted { MonopolyRules.houseCost(for: $0) < MonopolyRules.houseCost(for: $1) }.first!
        case .mathematical:
            // Best rent-increase-per-cost ratio
            space = buildableSpaces.sorted { a, b in
                let aRatio = rentIncreasePerDollar(space: a, state: state)
                let bRatio = rentIncreasePerDollar(space: b, state: state)
                return aRatio > bRatio
            }.first!
        case .tradeShark:
            // Prefer orange/red groups (high traffic), then by rent
            let preferred: [ColorGroup] = [.orange, .red]
            let prioritized = buildableSpaces.filter { preferred.contains($0.colorGroup ?? .brown) }
            space = (prioritized.isEmpty ? buildableSpaces : prioritized)
                .sorted { ($0.currentRent) > ($1.currentRent) }.first!
        }

        let cost = MonopolyRules.houseCost(for: space)
        let requiredCash = Int(Double(cost) * reserveMultiplier)

        if player.cash >= requiredCash {
            return AIReasoning(
                decision: .buildHouse(spaceID: space.id),
                reasoning: buildReasoningText(player: player, space: space, cost: cost),
                confidence: Double.random(in: 0.75...0.95)
            )
        }
        return AIReasoning(
            decision: .pass,
            reasoning: buildPassReasoningText(player: player, cost: cost, required: requiredCash),
            confidence: Double.random(in: 0.6...0.8)
        )
    }

    /// Rent increase per dollar spent on the next house
    private static func rentIncreasePerDollar(space: BoardSpace, state: GameState) -> Double {
        let currentRent = Double(MonopolyRules.rent(for: space, in: state))
        // Estimate next rent tier
        let nextRent: Double
        switch space.houses {
        case 0: nextRent = Double(space.rent1 ?? space.baseRent ?? 0)
        case 1: nextRent = Double(space.rent2 ?? space.rent1 ?? 0)
        case 2: nextRent = Double(space.rent3 ?? space.rent2 ?? 0)
        case 3: nextRent = Double(space.rent4 ?? space.rent3 ?? 0)
        default: nextRent = currentRent
        }
        let cost = Double(MonopolyRules.houseCost(for: space))
        guard cost > 0 else { return 0 }
        return (nextRent - currentRent) / cost
    }

    // MARK: - Trade Decision

    private static func decideToTrade(player: AIPlayer, state: GameState) -> AIReasoning {
        // Trade probability driven by trading trait score
        let tradeChance = Double(player.trading) / 100.0 * 0.8
        if Double.random(in: 0...1) < tradeChance {
            return AIReasoning(
                decision: .pass, // Simplified: no actual trade proposals in mock mode
                reasoning: tradeReasoningText(player: player, considering: true),
                confidence: 0.6
            )
        }
        return AIReasoning(
            decision: .pass,
            reasoning: tradeReasoningText(player: player, considering: false),
            confidence: 0.7
        )
    }

    // MARK: - Liquidation Decision

    private static func decideLiquidation(player: AIPlayer, state: GameState) -> AIReasoning {
        let ownedSpaces = state.ownedSpaces(for: player.id).filter { !$0.isMortgaged }
        guard !ownedSpaces.isEmpty else {
            return AIReasoning(decision: .declareBankruptcy, reasoning: "No assets remain. Declaring bankruptcy.", confidence: 1.0)
        }

        let target: BoardSpace
        switch player.personality {
        case .aggressive:
            // Mortgage lowest-rent property (protect rent machines)
            target = ownedSpaces.sorted { MonopolyRules.rent(for: $0, in: state) < MonopolyRules.rent(for: $1, in: state) }.first!

        case .conservative:
            // Mortgage cheapest property (minimize equity loss)
            target = ownedSpaces.sorted { ($0.price ?? 0) < ($1.price ?? 0) }.first!

        case .mathematical:
            // Mortgage worst rent-to-mortgage-value ratio
            target = ownedSpaces.sorted { a, b in
                rentToMortgageRatio(space: a, state: state) < rentToMortgageRatio(space: b, state: state)
            }.first!

        case .tradeShark:
            // Mortgage properties NOT near completing color groups (keep trade leverage)
            let nonLeverage = ownedSpaces.filter { space in
                guard let group = space.colorGroup else { return true }
                let groupSpaces = state.board.filter { $0.colorGroup == group }
                let ownedInGroup = groupSpaces.filter { $0.ownerID == player.id }.count
                // If we own 2+ of a 3-group or 1+ of a 2-group, keep it
                return ownedInGroup < group.groupSize - 1
            }
            target = (nonLeverage.isEmpty ? ownedSpaces : nonLeverage)
                .sorted { ($0.price ?? 0) < ($1.price ?? 0) }.first!

        case .chaoticEvil:
            // Mortgage most expensive property (maximum chaos)
            target = ownedSpaces.sorted { ($0.price ?? 0) > ($1.price ?? 0) }.first!

        case .balanced:
            // Mortgage cheapest non-monopoly property
            let nonMonopoly = ownedSpaces.filter { space in
                guard let group = space.colorGroup else { return true }
                return !state.hasMonopoly(playerID: player.id, group: group)
            }
            target = (nonMonopoly.isEmpty ? ownedSpaces : nonMonopoly)
                .sorted { ($0.price ?? 0) < ($1.price ?? 0) }.first!
        }

        let mortgageVal = MonopolyRules.mortgageValue(for: target)
        return AIReasoning(
            decision: .mortgageProperty(spaceID: target.id),
            reasoning: liquidationReasoningText(player: player, space: target, value: mortgageVal),
            confidence: Double.random(in: 0.7...0.9)
        )
    }

    /// Rent-to-mortgage-value ratio for liquidation priority
    private static func rentToMortgageRatio(space: BoardSpace, state: GameState) -> Double {
        let rent = Double(MonopolyRules.rent(for: space, in: state))
        let mortgageVal = Double(MonopolyRules.mortgageValue(for: space))
        guard mortgageVal > 0 else { return 0 }
        return rent / mortgageVal
    }

    // MARK: - Reasoning Text Generators

    private static func buyReasoningText(player: AIPlayer, space: BoardSpace, state: GameState) -> String {
        let texts: [AIPersonality: [String]] = [
            .aggressive: [
                "Acquiring \(space.name) for aggressive board control. This is a key position.",
                "\(space.name) purchased. Expanding my empire. No mercy.",
                "BOUGHT. \(space.name) is now mine. ROI looks exceptional.",
            ],
            .conservative: [
                "Purchasing \(space.name). Conservative analysis shows positive expected value at $\(space.price ?? 0).",
                "Risk-adjusted metrics favor this acquisition. Proceeding with \(space.name).",
                "Kelly criterion suggests \(space.name) is within acceptable risk threshold.",
            ],
            .mathematical: [
                "Monte Carlo confirms \(space.name) acquisition: +\(Int.random(in: 15...45))% win probability improvement.",
                "Expected value positive over \(Int.random(in: 8...18)) turns. Purchasing \(space.name).",
                "Statistical analysis: \(space.name) appears in \(Int.random(in: 72...89))% of optimal strategies.",
            ],
            .tradeShark: [
                "Buying \(space.name) for future trading leverage. Everyone needs this color group.",
                "Strategic acquisition. \(space.name) will be valuable in negotiations.",
                "I know what you want. Acquiring \(space.name) first.",
            ],
            .chaoticEvil: [
                "BUYING EVERYTHING. \(space.name) IS MINE NOW. 🔥",
                "Who needs strategy?! \(space.name) ACQUIRED!",
                "CHAOS MODE: \(space.name) purchased. More! MORE!",
            ],
            .balanced: [
                "Balanced assessment: \(space.name) provides solid portfolio diversification.",
                "Purchasing \(space.name). Even-handed approach continues.",
                "\(space.name) fits the balanced strategy. Good acquisition.",
            ],
        ]
        let options = texts[player.personality] ?? ["Buying \(space.name)."]
        return options.randomElement() ?? "Purchasing \(space.name)."
    }

    private static func passReasoningText(player: AIPlayer, space: BoardSpace) -> String {
        switch player.personality {
        case .conservative:
            return "Passing on \(space.name). Cash reserves must remain above 2× purchase price."
        case .mathematical:
            return "ROI analysis negative for \(space.name) at current game stage. Passing."
        case .aggressive:
            return "Strategically passing \(space.name) — preserving cash for better targets."
        case .tradeShark:
            return "Passing on \(space.name) — limited trade leverage potential."
        case .chaoticEvil:
            return "Even chaos has limits... passing on \(space.name). For now. 😈"
        case .balanced:
            return "Passing on \(space.name) — maintaining balanced cash reserves."
        }
    }

    private static func rentResponseText(player: AIPlayer, amount: Int) -> String {
        switch player.personality {
        case .chaoticEvil:
            return "NOOOOO! Paying $\(amount) rent! This WILL be avenged! 😤"
        case .aggressive:
            return "Paying $\(amount). Noted. You'll regret having that property."
        case .mathematical:
            return "Rent payment $\(amount) processed. Adjusting win probability estimates."
        case .balanced:
            return "Paying $\(amount) rent. Part of the game — onwards."
        case .conservative:
            return "Paying $\(amount) rent. Reserves remain adequate."
        case .tradeShark:
            return "Paying $\(amount). Remember this when I come to negotiate."
        }
    }

    // MARK: - Build Reasoning Text

    private static func buildReasoningText(player: AIPlayer, space: BoardSpace, cost: Int) -> String {
        switch player.personality {
        case .aggressive:
            return "Building on \(space.name) for $\(cost). Maximizing rent pressure — highest-rent property gets the house first."
        case .conservative:
            return "Investing $\(cost) in \(space.name) — lowest build cost in the group. Conservative growth, steady returns."
        case .mathematical:
            return "Building on \(space.name): best rent-increase-per-dollar ratio at $\(cost). Optimal ROI allocation."
        case .tradeShark:
            return "Developing \(space.name) for $\(cost). Orange/red corridor is prime real estate — high traffic, high value."
        case .chaoticEvil:
            return "BUILDING on \(space.name)! $\(cost)?! WHO CARES! MORE HOUSES! 🏠🔥"
        case .balanced:
            return "Building on \(space.name) for $\(cost). Steady improvement — cheapest cost, balanced approach."
        }
    }

    private static func buildPassReasoningText(player: AIPlayer, cost: Int, required: Int) -> String {
        switch player.personality {
        case .aggressive:
            return "Holding off on building ($\(cost) cost, need $\(required) reserve). Even aggression needs fuel."
        case .conservative:
            return "Insufficient safety margin — need $\(required) but building costs $\(cost). Preserving cash reserves."
        case .mathematical:
            return "Build cost $\(cost) vs required reserve $\(required). Negative EV at current cash levels. Passing."
        case .tradeShark:
            return "Keeping cash liquid at $\(cost) build cost — need flexibility for upcoming deals."
        case .chaoticEvil:
            return "Can't build?! Only $\(cost) but need $\(required)?! This is OUTRAGEOUS! 😤"
        case .balanced:
            return "Passing on building — $\(cost) cost exceeds comfortable threshold of $\(required)."
        }
    }

    // MARK: - Jail Reasoning Text

    private static func jailReasoningText(player: AIPlayer, action: String, detail: String) -> String {
        let prefix: String
        switch player.personality {
        case .aggressive:
            prefix = action == "bail" ? "Posting bail immediately." : "Staying put for now."
        case .conservative:
            prefix = action == "roll" ? "Rolling for doubles — the frugal approach." : "Paying bail — unusual but warranted."
        case .mathematical:
            prefix = "Jail decision computed."
        case .tradeShark:
            prefix = action == "bail" ? "Paying to get back to the negotiating table." : "Biding time in jail."
        case .chaoticEvil:
            prefix = action == "bail" ? "BUSTING OUT!" : "Rolling dice from behind bars!"
        case .balanced:
            prefix = action == "bail" ? "Paying $50 bail." : "Rolling for doubles."
        }
        return "\(prefix) \(detail)"
    }

    // MARK: - Trade Reasoning Text

    private static func tradeReasoningText(player: AIPlayer, considering: Bool) -> String {
        if considering {
            switch player.personality {
            case .aggressive:
                return "Scanning the board for weak players to pressure into trades..."
            case .conservative:
                return "Evaluating potential trades — only fair-value exchanges considered."
            case .mathematical:
                return "Running trade simulations... identifying positive-EV swap opportunities."
            case .tradeShark:
                return "This is what I live for. Analyzing every player's needs for maximum leverage."
            case .chaoticEvil:
                return "Looking for someone to SWINDLE! Who wants to make a 'deal'? 😈"
            case .balanced:
                return "Considering trade options — looking for mutually beneficial exchanges."
            }
        } else {
            switch player.personality {
            case .aggressive:
                return "No one has anything worth taking right now."
            case .conservative:
                return "No trades meet risk-adjusted return thresholds. Holding position."
            case .mathematical:
                return "Trade analysis complete: no positive-EV opportunities detected."
            case .tradeShark:
                return "Biding my time — the right deal will present itself."
            case .chaoticEvil:
                return "Nobody wants to play?! FINE. I'll get you all later! 🔥"
            case .balanced:
                return "No beneficial trade found this turn. Patience."
            }
        }
    }

    // MARK: - Liquidation Reasoning Text

    private static func liquidationReasoningText(player: AIPlayer, space: BoardSpace, value: Int) -> String {
        switch player.personality {
        case .aggressive:
            return "Mortgaging \(space.name) (lowest rent earner) for $\(value). Protecting my rent machines — they'll pay this back tenfold."
        case .conservative:
            return "Mortgaging \(space.name) for $\(value) — cheapest property, minimal equity loss. Preserving core portfolio."
        case .mathematical:
            return "Mortgaging \(space.name): worst rent-to-value ratio at $\(value) recovery. Optimal liquidation target."
        case .tradeShark:
            return "Mortgaging \(space.name) for $\(value) — not near any monopoly completion. Keeping my trade leverage intact."
        case .chaoticEvil:
            return "MORTGAGING \(space.name)?! The most expensive one?! MAXIMUM CHAOS! $\(value) cash! 🔥💰"
        case .balanced:
            return "Mortgaging \(space.name) for $\(value). Non-monopoly property — protecting completed color groups."
        }
    }
}

// MARK: - Decision Context

struct DecisionContext {
    enum Situation {
        case landedOnUnowned(BoardSpace)
        case mustPayRent(amount: Int, ownerID: String)
        case inJail
        case buildOpportunity
        case tradeOpportunity
        case needsLiquidation
    }
    var situation: Situation
    var availableActions: [String] = []
}
