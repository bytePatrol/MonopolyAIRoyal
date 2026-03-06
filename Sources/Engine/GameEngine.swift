import Foundation
import Observation

// MARK: - Game Engine Delegate

protocol GameEngineDelegate: AnyObject {
    func gameEngine(_ engine: GameEngine, didUpdateState state: GameState)
    func gameEngine(_ engine: GameEngine, didProduceReasoning reasoning: AIReasoning, for playerID: String)
    func gameEngine(_ engine: GameEngine, didEndGame state: GameState)
    func gameEngine(_ engine: GameEngine, didNeedNarration text: String, type: GameEventType)
}

// MARK: - GameEngine

@MainActor
@Observable
final class GameEngine {
    var state: GameState
    var isRunning: Bool = false
    var isPaused: Bool = false
    var speed: GameSpeed = .normal
    var lastReasoning: AIReasoning?
    var lastNarration: String = ""

    weak var delegate: GameEngineDelegate?

    private var chanceCards: [MonopolyCard]
    private var communityChestCards: [MonopolyCard]
    private var chanceIndex = 0
    private var communityChestIndex = 0
    private var gameLoopTask: Task<Void, Never>?

    var settings: AppSettings
    private let commentaryEngine = CommentaryEngine.shared

    enum GameSpeed: Double {
        case slow   = 5.0
        case normal = 2.5
        case fast   = 0.8
        case instant = 0.0

        /// Shorter delay for sub-phases within a turn (dice roll, landing, etc.)
        var phaseDelay: Double {
            switch self {
            case .slow:    return 2.5
            case .normal:  return 1.2
            case .fast:    return 0.3
            case .instant: return 0.0
            }
        }
    }

    // MARK: - Init

    init(players: [AIPlayer], settings: AppSettings = .default) {
        self.settings = settings
        self.state = GameState.newGame(players: players)
        self.chanceCards = MonopolyRules.shuffledChance()
        self.communityChestCards = MonopolyRules.shuffledCommunityChest()
    }

    // MARK: - Game Control

    func startGame() {
        guard !isRunning else { return }
        isRunning = true
        isPaused = false
        gameLoopTask = Task { await runGameLoop() }
    }

    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
    }

    func stopGame() {
        isRunning = false
        gameLoopTask?.cancel()
        gameLoopTask = nil
    }

    // MARK: - Main Game Loop

    private func runGameLoop() async {
        while isRunning && !state.isGameOver {
            guard !Task.isCancelled else { break }

            // Pause handling
            while isPaused {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard !Task.isCancelled else { return }
            }

            await executeTurn()
            await waitForSpeed()

            // Color commentary between turns
            if let colorText = await commentaryEngine.generateColorCommentary(state: state, speed: speed) {
                await narrate(colorText, type: .roll)
            }

            // Inter-turn delay so narrator can finish and viewers can follow
            guard !Task.isCancelled else { break }
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        }

        if state.isGameOver {
            finishGame()
        }
    }

    private func waitForSpeed() async {
        let delay = UInt64(speed.rawValue * 1_000_000_000)
        if delay > 0 {
            try? await Task.sleep(nanoseconds: delay)
        }
    }

    /// Shorter delay between sub-phases within a single turn.
    private func waitForPhase() async {
        let delay = UInt64(speed.phaseDelay * 1_000_000_000)
        if delay > 0 {
            try? await Task.sleep(nanoseconds: delay)
        }
    }

    // MARK: - Turn Execution

    private func executeTurn() async {
        guard var currentPlayer = state.currentPlayer else { return }

        currentPlayer.status = .thinking
        updatePlayer(currentPlayer)
        notifyDelegateUpdate()
        await waitForPhase()

        // 1. Handle jail
        if currentPlayer.isInJail {
            await handleJailTurn(player: &currentPlayer)
            updatePlayer(currentPlayer)
            if currentPlayer.isInJail {
                state.advanceToNextPlayer()
                notifyDelegateUpdate()
                return
            }
        }

        // 2. Roll dice
        let roll = DiceRoll.random()
        state.lastDiceRoll = roll
        state.phase = .moving

        addEvent(type: .roll,
                 description: "\(currentPlayer.name) rolled \(roll.die1) + \(roll.die2) = \(roll.total)",
                 playerID: currentPlayer.id, playerName: currentPlayer.name)
        notifyDelegateUpdate()
        await waitForPhase()

        // 3. Handle doubles
        if roll.isDoubles {
            state.doublesCount += 1
            if state.doublesCount >= 3 {
                // Three doubles → go to jail
                sendToJail(player: &currentPlayer)
                updatePlayer(currentPlayer)
                state.advanceToNextPlayer()
                notifyDelegateUpdate()
                return
            }
        }

        // 4. Move player
        let oldPosition = currentPlayer.boardPosition
        let newPosition = (oldPosition + roll.total) % 40
        let passedGo = newPosition < oldPosition || (oldPosition + roll.total >= 40)

        currentPlayer.boardPosition = newPosition

        if passedGo && newPosition != 0 {
            currentPlayer.cash += BoardSpace.goSalary
            addEvent(type: .roll, description: "\(currentPlayer.name) passed GO! Collected $\(BoardSpace.goSalary)",
                     playerID: currentPlayer.id, playerName: currentPlayer.name, amount: BoardSpace.goSalary)
        }

        updatePlayer(currentPlayer)
        state.phase = .action
        notifyDelegateUpdate()

        await waitForPhase()

        // 5. Land on space
        await handleLanding(player: &currentPlayer, spaceIndex: newPosition, diceTotal: roll.total)
        updatePlayer(currentPlayer)
        notifyDelegateUpdate()
        await waitForPhase()

        // 6. AI decision (build, trade, mortgage)
        state.phase = .aiDeciding
        notifyDelegateUpdate()
        await performPostMoveDecisions(player: &currentPlayer)
        updatePlayer(currentPlayer)

        // 7. Check bankruptcy
        if currentPlayer.cash < 0 {
            if MonopolyRules.isBankrupt(player: currentPlayer, in: state) {
                await declareBankruptcy(player: &currentPlayer)
            }
        }

        updatePlayer(currentPlayer)

        // 8. Check win condition
        if checkWinCondition() {
            state.phase = .gameOver
            notifyDelegateEnd()
            return
        }

        // 9. Advance turn (unless doubles)
        if roll.isDoubles && !currentPlayer.isInJail && state.doublesCount < 3 {
            // Same player rolls again
        } else {
            state.advanceToNextPlayer()
        }

        notifyDelegateUpdate()
    }

    // MARK: - Space Landing

    private func handleLanding(player: inout AIPlayer, spaceIndex: Int, diceTotal: Int) async {
        let space = state.board[spaceIndex]

        switch space.type {
        case .property, .railroad, .utility:
            if let ownerID = space.ownerID, ownerID != player.id, !space.isMortgaged {
                let rent = MonopolyRules.rent(for: space, in: state, diceTotal: diceTotal)
                let context = DecisionContext(situation: .mustPayRent(amount: rent, ownerID: ownerID))
                let reasoning = await getAIDecision(player: player, context: context)

                // Transfer rent
                player.cash -= rent
                if var owner = state.player(withID: ownerID),
                   let idx = state.playerIndex(withID: ownerID) {
                    owner.cash += rent
                    state.players[idx] = owner
                }
                addEvent(type: .rent,
                         description: "\(player.name) paid $\(rent) rent to \(ownerID.uppercased())",
                         playerID: player.id, playerName: player.name, amount: rent, targetID: ownerID)
                let ownerName = state.player(withID: ownerID)?.name ?? ownerID.uppercased()
                await narrateEvent(
                    type: .rent,
                    event: .rent(playerName: player.name, amount: rent, ownerName: ownerName, spaceName: space.name)
                )

            } else if space.ownerID == nil {
                // Unowned — offer to buy
                let context = DecisionContext(situation: .landedOnUnowned(space))
                let reasoning = await getAIDecision(player: player, context: context)
                lastNarration = reasoning.reasoning

                switch reasoning.decision {
                case .buyProperty(let spaceID):
                    if let price = space.price, player.cash >= price {
                        player.cash -= price
                        state.board[spaceID].ownerID = player.id
                        player.ownedPropertyIDs.append(spaceID)
                        addEvent(type: .buy, description: "\(player.name) bought \(space.name) for $\(price)",
                                 playerID: player.id, playerName: player.name, amount: price)
                        await narrateEvent(
                            type: .buy,
                            event: .buy(playerName: player.name, spaceName: space.name, amount: price)
                        )
                    }
                default:
                    addEvent(type: .roll, description: "\(player.name) passed on \(space.name)",
                             playerID: player.id, playerName: player.name)
                }
            }

        case .corner:
            if space.id == 30 { // Go To Jail
                sendToJail(player: &player)
                await narrateEvent(
                    type: .jail,
                    event: .jail(playerName: player.name)
                )
            }
            // GO (0) and Free Parking (20) and Just Visiting/Jail (10) — no action

        case .tax:
            let taxAmount: Int
            if space.id == 4 { // Income Tax
                taxAmount = MonopolyRules.incomeTax(for: player, in: state)
            } else { // Luxury Tax
                taxAmount = BoardSpace.luxuryTaxAmount
            }
            player.cash -= taxAmount
            addEvent(type: .tax, description: "\(player.name) paid $\(taxAmount) \(space.name)",
                     playerID: player.id, playerName: player.name, amount: taxAmount)
            await narrateEvent(
                type: .tax,
                event: .tax(playerName: player.name, amount: taxAmount, spaceName: space.name)
            )

        case .card:
            if space.name.contains("Chance") {
                let card = drawChanceCard()
                await applyCard(card, to: &player)
            } else {
                let card = drawCommunityChestCard()
                await applyCard(card, to: &player)
            }
        }
    }

    // MARK: - Card Application

    private func applyCard(_ card: MonopolyCard, to player: inout AIPlayer) async {
        addEvent(type: .card, description: "\(player.name): \"\(card.text)\"",
                 playerID: player.id, playerName: player.name)
        await narrateEvent(
            type: .card,
            event: .card(playerName: player.name, cardText: card.text)
        )

        switch card.action {
        case .collectFromBank(let amount):
            player.cash += amount

        case .payToBank(let amount):
            player.cash -= amount

        case .collectFromEachPlayer(let amount):
            for i in state.players.indices where state.players[i].id != player.id && !state.players[i].isBankrupt {
                state.players[i].cash -= amount
                player.cash += amount
            }

        case .payEachPlayer(let amount):
            for i in state.players.indices where state.players[i].id != player.id && !state.players[i].isBankrupt {
                state.players[i].cash += amount
                player.cash -= amount
            }

        case .moveToSpace(let index):
            let passedGo = index < player.boardPosition
            player.boardPosition = index
            if passedGo { player.cash += BoardSpace.goSalary }
            await handleLanding(player: &player, spaceIndex: index, diceTotal: 7)

        case .moveBack(let spaces):
            player.boardPosition = max(0, player.boardPosition - spaces)
            await handleLanding(player: &player, spaceIndex: player.boardPosition, diceTotal: 7)

        case .getOutOfJail:
            player.getOutOfJailCards += 1

        case .goToJail:
            sendToJail(player: &player)

        case .advanceToGo:
            player.boardPosition = 0
            player.cash += BoardSpace.goSalary

        case .generalRepairs(let houseCost, let hotelCost):
            let spaces = state.ownedSpaces(for: player.id)
            let total = spaces.reduce(0) { acc, space in
                acc + (space.hasHotel ? hotelCost : space.houses * houseCost)
            }
            player.cash -= total

        case .streetRepairs(let houseCost, let hotelCost):
            let spaces = state.ownedSpaces(for: player.id)
            let total = spaces.reduce(0) { acc, space in
                acc + (space.hasHotel ? hotelCost : space.houses * houseCost)
            }
            player.cash -= total

        case .payPercentage(let percent):
            let amount = Int(Double(player.cash) * percent)
            player.cash -= amount
        }
    }

    // MARK: - Post-Move Decisions

    private func performPostMoveDecisions(player: inout AIPlayer) async {
        // Check build opportunity
        let buildable = state.board.filter { MonopolyRules.canBuildHouse(on: $0, for: player.id, in: state) }
        if !buildable.isEmpty {
            let context = DecisionContext(situation: .buildOpportunity)
            let reasoning = await getAIDecision(player: player, context: context)
            if case .buildHouse(let spaceID) = reasoning.decision {
                let cost = MonopolyRules.houseCost(for: state.board[spaceID])
                if player.cash >= cost {
                    player.cash -= cost
                    state.board[spaceID].houses += 1
                    let builtSpaceName = state.board[spaceID].name
                    addEvent(type: .build, description: "\(player.name) built house on \(builtSpaceName)",
                             playerID: player.id, playerName: player.name, amount: cost)
                    await narrateEvent(
                        type: .build,
                        event: .build(playerName: player.name, spaceName: builtSpaceName, cost: cost)
                    )
                }
            }
        }
    }

    // MARK: - Jail Handling

    private func handleJailTurn(player: inout AIPlayer) async {
        let context = DecisionContext(situation: .inJail)
        let reasoning = await getAIDecision(player: player, context: context)

        switch reasoning.decision {
        case .payBail:
            if player.cash >= 50 {
                player.cash -= 50
                player.isInJail = false
                player.jailTurns = 0
                addEvent(type: .jail, description: "\(player.name) paid $50 bail",
                         playerID: player.id, playerName: player.name, amount: 50)
            }
        case .useGetOutOfJailCard:
            if player.getOutOfJailCards > 0 {
                player.getOutOfJailCards -= 1
                player.isInJail = false
                player.jailTurns = 0
                addEvent(type: .jail, description: "\(player.name) used Get Out of Jail Free card",
                         playerID: player.id, playerName: player.name)
            }
        case .rollForJail:
            let roll = DiceRoll.random()
            if roll.isDoubles {
                player.isInJail = false
                player.jailTurns = 0
                player.boardPosition = (player.boardPosition + roll.total) % 40
            } else {
                player.jailTurns += 1
                if player.jailTurns >= 3 {
                    // Force pay bail after 3 turns
                    player.cash -= 50
                    player.isInJail = false
                    player.jailTurns = 0
                }
            }
        default:
            break
        }
    }

    private func sendToJail(player: inout AIPlayer) {
        player.isInJail = true
        player.jailTurns = 0
        player.boardPosition = MonopolyRules.jailPosition()
        addEvent(type: .jail, description: "\(player.name) went to JAIL",
                 playerID: player.id, playerName: player.name)
    }

    // MARK: - Bankruptcy

    private func declareBankruptcy(player: inout AIPlayer) async {
        player.isBankrupt = true
        player.status = .bankrupt
        // Transfer properties to bank (or creditor — simplified)
        for i in state.board.indices where state.board[i].ownerID == player.id {
            state.board[i].ownerID = nil
            state.board[i].houses = 0
            state.board[i].hasHotel = false
        }
        addEvent(type: .bankrupt, description: "\(player.name) is BANKRUPT!",
                 playerID: player.id, playerName: player.name)
        await narrateEvent(
            type: .bankrupt,
            event: .bankrupt(playerName: player.name)
        )
    }

    // MARK: - Win Condition

    private func checkWinCondition() -> Bool {
        let active = state.activePlayers
        if active.count <= 1 {
            state.winnerID = active.first?.id
            return true
        }
        if state.turn >= settings.maxTurns {
            // Net worth win
            state.winnerID = active.max(by: { state.calculateNetWorth(for: $0.id) < state.calculateNetWorth(for: $1.id) })?.id
            return true
        }
        return false
    }

    // MARK: - Card Decks

    private func drawChanceCard() -> MonopolyCard {
        let card = chanceCards[chanceIndex % chanceCards.count]
        chanceIndex += 1
        return card
    }

    private func drawCommunityChestCard() -> MonopolyCard {
        let card = communityChestCards[communityChestIndex % communityChestCards.count]
        communityChestIndex += 1
        return card
    }

    // MARK: - AI Decision Dispatch

    private func getAIDecision(player: AIPlayer, context: DecisionContext) async -> AIReasoning {
        let reasoning: AIReasoning
        if settings.mockMode {
            reasoning = await MockAIDecisionEngine.decide(player: player, state: state, context: context)
        } else {
            reasoning = await LiveAIDecisionEngine.decide(player: player, state: state, context: context)
        }
        lastReasoning = reasoning
        delegate?.gameEngine(self, didProduceReasoning: reasoning, for: player.id)
        return reasoning
    }

    // MARK: - Helpers

    private func updatePlayer(_ player: AIPlayer) {
        if let idx = state.playerIndex(withID: player.id) {
            state.players[idx] = player
        }
    }

    private func addEvent(type: GameEventType, description: String, playerID: String, playerName: String,
                           amount: Int? = nil, targetID: String? = nil) {
        let event = GameEvent.make(
            gameID: state.id, turn: state.turn, type: type,
            description: description, playerID: playerID, playerName: playerName,
            amount: amount, targetPlayerID: targetID
        )
        state.events.append(event)
    }

    private func narrate(_ text: String, type: GameEventType = .roll) async {
        lastNarration = text
        delegate?.gameEngine(self, didNeedNarration: text, type: type)
        // Wait for the narrator to finish speaking before continuing
        await NarratorService.shared.narrate(text)
    }

    /// Generate AI/template commentary for an event, then narrate it.
    private func narrateEvent(type: GameEventType, event: CommentaryEventType, reasoning: String? = nil) async {
        if let text = await commentaryEngine.generateCommentary(for: event, state: state, reasoning: reasoning, speed: speed) {
            await narrate(text, type: type)
        }
    }

    private func notifyDelegateUpdate() {
        delegate?.gameEngine(self, didUpdateState: state)
    }

    private func notifyDelegateEnd() {
        isRunning = false
        delegate?.gameEngine(self, didEndGame: state)
    }

    private func finishGame() {
        state.endDate = Date()
        state.phase = .gameOver
        notifyDelegateEnd()
    }
}
