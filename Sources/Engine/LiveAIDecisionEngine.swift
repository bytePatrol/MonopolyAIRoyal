import Foundation

// MARK: - LiveAIDecisionEngine

/// Calls OpenRouter to get real AI decisions for Monopoly gameplay.
struct LiveAIDecisionEngine {

    // MARK: - Primary Decision Method

    static func decide(
        player: AIPlayer,
        state: GameState,
        context: DecisionContext
    ) async -> AIReasoning {
        let systemPrompt = OpenRouterService.monopolySystemPrompt(for: player)
        let userPrompt = buildUserPrompt(player: player, state: state, context: context)

        do {
            let response = try await OpenRouterService.shared.complete(
                model: player.model,
                systemPrompt: systemPrompt,
                userPrompt: userPrompt
            )
            let parsed = parseResponse(response, player: player, state: state, context: context)
            return validateDecision(parsed, player: player, state: state, context: context)
        } catch {
            // Fallback to mock if API call fails
            print("[LiveAI] API call failed for \(player.name): \(error.localizedDescription). Falling back to mock.")
            return await MockAIDecisionEngine.decide(player: player, state: state, context: context)
        }
    }

    // MARK: - Personality Hint

    /// One-line guidance string per personality per situation type, injected into user prompts.
    private static func personalityHint(for player: AIPlayer, situation: DecisionContext.Situation) -> String {
        switch situation {
        case .landedOnUnowned:
            switch player.personality {
            case .aggressive:   return "You buy aggressively — even at 50% cash ratio. Dominate the board."
            case .conservative: return "You only buy when cash >= 2x price. Preserve your safety margin."
            case .mathematical: return "Buy if expected rent over 15 turns exceeds 80% of price. Compute the EV."
            case .tradeShark:   return "Buy for trade leverage — every property is a negotiation chip."
            case .chaoticEvil:  return "Buy everything. Risk is fun. Caution is boring."
            case .balanced:     return "Buy when cash >= 1.3x price. Steady and sensible."
            }

        case .inJail:
            switch player.personality {
            case .aggressive:   return "Pay bail to stay active — unless late game with monopolies (jail = safe harbor)."
            case .conservative: return "Roll for doubles to save $50. Frugality wins games."
            case .mathematical: return "Compute EV: board rent exposure vs $50 bail cost. Choose the +EV option."
            case .tradeShark:   return "Pay bail to circulate and create deal opportunities."
            case .chaoticEvil:  return "Flip a mental coin. Chaos doesn't plan jail strategy."
            case .balanced:     return "Pay bail early game, roll late game."
            }

        case .buildOpportunity:
            switch player.personality {
            case .aggressive:   return "Build aggressively on highest-rent properties. Keep only 1.2x cost in reserve."
            case .conservative: return "Build on cheapest-cost properties. Keep 3x build cost in reserve."
            case .mathematical: return "Build on the property with the best rent-increase-per-dollar ratio. Keep 2x reserve."
            case .tradeShark:   return "Prioritize orange/red groups (high traffic). Keep 2.5x reserve."
            case .chaoticEvil:  return "Build on the most expensive property. Reserve? What reserve?!"
            case .balanced:     return "Build on cheapest-cost property. Keep 2x reserve."
            }

        case .needsLiquidation:
            switch player.personality {
            case .aggressive:   return "Mortgage your lowest-rent property — protect your rent machines."
            case .conservative: return "Mortgage cheapest property — minimize equity loss."
            case .mathematical: return "Mortgage the property with the worst rent-to-mortgage-value ratio."
            case .tradeShark:   return "Mortgage properties NOT near completing color groups — keep trade leverage."
            case .chaoticEvil:  return "Mortgage the most expensive property. Maximum chaos."
            case .balanced:     return "Mortgage non-monopoly properties first — protect completed groups."
            }

        default:
            return ""
        }
    }

    // MARK: - Prompt Builder

    private static func buildUserPrompt(player: AIPlayer, state: GameState, context: DecisionContext) -> String {
        var prompt = """
        Turn \(state.turn) | You have $\(player.cash) cash | \(player.ownedPropertyIDs.count) properties owned.
        """

        let hint = personalityHint(for: player, situation: context.situation)

        switch context.situation {
        case .landedOnUnowned(let space):
            prompt += """

            You landed on \(space.name) (unowned).
            Price: $\(space.price ?? 0) | Base rent: $\(space.baseRent ?? 0)
            Color group: \(space.colorGroup?.rawValue ?? "N/A")

            Personality guidance: \(hint)

            Should you BUY or PASS?
            Reply with EXACTLY one line starting with "DECISION: BUY" or "DECISION: PASS"
            Then explain your reasoning in 1-2 sentences.
            """

        case .mustPayRent(let amount, let ownerID):
            prompt += """

            You must pay $\(amount) rent to \(ownerID).
            Your cash after payment: $\(player.cash - amount)

            DECISION: PAY_RENT
            React to this in character in 1-2 sentences.
            """

        case .inJail:
            var options = "Options: ROLL_FOR_DOUBLES"
            if player.cash >= 50 { options += ", PAY_BAIL ($50)" }
            if player.getOutOfJailCards > 0 { options += ", USE_CARD" }
            prompt += """

            You are in jail (turn \(player.jailTurns + 1) of 3).
            \(options)

            Personality guidance: \(hint)

            Reply with EXACTLY one line starting with "DECISION: ROLL_FOR_DOUBLES", "DECISION: PAY_BAIL", or "DECISION: USE_CARD"
            Then explain your reasoning in 1-2 sentences.
            """

        case .buildOpportunity:
            let buildable = state.board.filter { MonopolyRules.canBuildHouse(on: $0, for: player.id, in: state) }
            let buildList = buildable.map { "\($0.name) (houses: \($0.houses), cost: $\(MonopolyRules.houseCost(for: $0)))" }.joined(separator: "\n  ")
            prompt += """

            You can build houses on:
              \(buildList)

            Personality guidance: \(hint)

            Reply with "DECISION: BUILD <property_name>" or "DECISION: PASS"
            Then explain in 1-2 sentences.
            """

        case .tradeOpportunity:
            prompt += """

            Consider if you want to propose any trades.
            Reply with "DECISION: PASS" (trading is complex — pass for now).
            """

        case .needsLiquidation:
            let owned = state.ownedSpaces(for: player.id)
            let mortgageable = owned.filter { !$0.isMortgaged }
            let list = mortgageable.map { "\($0.name) (mortgage value: $\(MonopolyRules.mortgageValue(for: $0)))" }.joined(separator: "\n  ")
            prompt += """

            You need cash! You can mortgage:
              \(list)

            Personality guidance: \(hint)

            Reply with "DECISION: MORTGAGE <property_name>" or "DECISION: BANKRUPT"
            Then explain in 1-2 sentences.
            """
        }

        return prompt
    }

    // MARK: - Response Parser

    private static func parseResponse(_ response: String, player: AIPlayer, state: GameState, context: DecisionContext) -> AIReasoning {
        let upper = response.uppercased()

        switch context.situation {
        case .landedOnUnowned(let space):
            if upper.contains("DECISION: BUY") || upper.contains("DECISION:BUY") {
                return AIReasoning(
                    decision: .buyProperty(spaceID: space.id),
                    reasoning: response,
                    confidence: 0.85,
                    tokensUsed: estimateTokens(response),
                    costUSD: 0.001
                )
            } else {
                return AIReasoning(
                    decision: .pass,
                    reasoning: response,
                    confidence: 0.8,
                    tokensUsed: estimateTokens(response),
                    costUSD: 0.001
                )
            }

        case .mustPayRent(let amount, let ownerID):
            return AIReasoning(
                decision: .payRent(to: ownerID, amount: amount),
                reasoning: response,
                confidence: 1.0,
                tokensUsed: estimateTokens(response),
                costUSD: 0.001
            )

        case .inJail:
            if upper.contains("PAY_BAIL") || upper.contains("PAY BAIL") {
                return AIReasoning(decision: .payBail, reasoning: response, confidence: 0.85,
                                   tokensUsed: estimateTokens(response), costUSD: 0.001)
            } else if upper.contains("USE_CARD") || upper.contains("USE CARD") {
                return AIReasoning(decision: .useGetOutOfJailCard, reasoning: response, confidence: 0.9,
                                   tokensUsed: estimateTokens(response), costUSD: 0.001)
            } else {
                return AIReasoning(decision: .rollForJail, reasoning: response, confidence: 0.75,
                                   tokensUsed: estimateTokens(response), costUSD: 0.001)
            }

        case .buildOpportunity:
            if upper.contains("DECISION: BUILD") || upper.contains("DECISION:BUILD") {
                let buildable = state.board.filter { MonopolyRules.canBuildHouse(on: $0, for: player.id, in: state) }
                // Find best match from AI response, or default to first buildable
                let match = buildable.first { space in upper.contains(space.name.uppercased()) } ?? buildable.first
                if let space = match {
                    return AIReasoning(decision: .buildHouse(spaceID: space.id), reasoning: response, confidence: 0.8,
                                       tokensUsed: estimateTokens(response), costUSD: 0.001)
                }
            }
            return AIReasoning(decision: .pass, reasoning: response, confidence: 0.7,
                               tokensUsed: estimateTokens(response), costUSD: 0.001)

        case .tradeOpportunity:
            return AIReasoning(decision: .pass, reasoning: response, confidence: 0.7,
                               tokensUsed: estimateTokens(response), costUSD: 0.001)

        case .needsLiquidation:
            if upper.contains("BANKRUPT") {
                return AIReasoning(decision: .declareBankruptcy, reasoning: response, confidence: 1.0,
                                   tokensUsed: estimateTokens(response), costUSD: 0.001)
            }
            // Try to match property name from LLM response (like build parser does)
            let owned = state.ownedSpaces(for: player.id).filter { !$0.isMortgaged }
            let nameMatch = owned.first { space in upper.contains(space.name.uppercased()) }
            if let matched = nameMatch {
                return AIReasoning(decision: .mortgageProperty(spaceID: matched.id), reasoning: response, confidence: 0.85,
                                   tokensUsed: estimateTokens(response), costUSD: 0.001)
            }
            // Fallback: mortgage cheapest property
            if let cheapest = owned.sorted(by: { ($0.price ?? 0) < ($1.price ?? 0) }).first {
                return AIReasoning(decision: .mortgageProperty(spaceID: cheapest.id), reasoning: response, confidence: 0.7,
                                   tokensUsed: estimateTokens(response), costUSD: 0.001)
            }
            return AIReasoning(decision: .declareBankruptcy, reasoning: response, confidence: 1.0,
                               tokensUsed: estimateTokens(response), costUSD: 0.001)
        }
    }

    // MARK: - Decision Validation

    /// Lightweight post-parse overrides to enforce personality guardrails when the LLM drifts out of character.
    private static func validateDecision(_ reasoning: AIReasoning, player: AIPlayer, state: GameState, context: DecisionContext) -> AIReasoning {
        var result = reasoning

        switch context.situation {
        case .landedOnUnowned(let space):
            guard let price = space.price else { return result }
            let ratio = Double(player.cash) / Double(price)

            switch (player.personality, result.decision) {
            case (.chaoticEvil, .pass) where ratio > 2.0:
                // Chaotic Evil with >2x cash passing → override to buy
                result.decision = .buyProperty(spaceID: space.id)
                result.reasoning = "[Override] \(result.reasoning)\n— Chaotic Evil override: too much cash to pass. BUYING!"
            case (.aggressive, .pass) where ratio > 3.0:
                // Aggressive with >3x cash passing → override to buy
                result.decision = .buyProperty(spaceID: space.id)
                result.reasoning = "[Override] \(result.reasoning)\n— Aggressive override: sitting on cash is not our style. BUYING!"
            case (.conservative, .buyProperty) where ratio < 2.0:
                // Conservative buying when cash < 2x price → override to pass
                result.decision = .pass
                result.reasoning = "[Override] \(result.reasoning)\n— Conservative override: cash ratio \(String(format: "%.1f", ratio))x is below 2.0x threshold. Passing."
            default:
                break
            }

        case .inJail:
            switch (player.personality, result.decision) {
            case (.conservative, .payBail) where player.cash < 200:
                // Conservative paying bail with cash < $200 → override to roll
                result.decision = .rollForJail
                result.reasoning = "[Override] \(result.reasoning)\n— Conservative override: $\(player.cash) cash too low to spend $50 on bail. Rolling."
            default:
                break
            }

        case .buildOpportunity:
            if case .buildHouse(let spaceID) = result.decision, player.personality == .conservative {
                let space = state.board.first { $0.id == spaceID }
                let cost = space.map { MonopolyRules.houseCost(for: $0) } ?? 0
                if player.cash < cost * 3 {
                    // Conservative building when cash < 3x cost → override to pass
                    result.decision = .pass
                    result.reasoning = "[Override] \(result.reasoning)\n— Conservative override: $\(player.cash) < 3x build cost $\(cost * 3). Passing."
                }
            }

        case .needsLiquidation:
            if case .mortgageProperty(let spaceID) = result.decision {
                let targetSpace = state.board.first { $0.id == spaceID }
                // Balanced/Trade Shark mortgaging a monopoly property when non-monopoly alternatives exist → override target
                if [.balanced, .tradeShark].contains(player.personality),
                   let space = targetSpace,
                   let group = space.colorGroup,
                   state.hasMonopoly(playerID: player.id, group: group) {
                    let owned = state.ownedSpaces(for: player.id).filter { !$0.isMortgaged }
                    let nonMonopoly = owned.filter { s in
                        guard let g = s.colorGroup else { return true }
                        return !state.hasMonopoly(playerID: player.id, group: g)
                    }
                    if let alt = nonMonopoly.sorted(by: { ($0.price ?? 0) < ($1.price ?? 0) }).first {
                        result.decision = .mortgageProperty(spaceID: alt.id)
                        result.reasoning = "[Override] \(result.reasoning)\n— \(player.personality.rawValue) override: protecting monopoly on \(group.rawValue). Mortgaging \(alt.name) instead."
                    }
                }
            }

        default:
            break
        }

        return result
    }

    private static func estimateTokens(_ text: String) -> Int {
        text.count / 4  // Rough approximation
    }
}
