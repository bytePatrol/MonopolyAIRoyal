import Foundation

// MARK: - MonopolyRules (Pure Functions, No State)

enum MonopolyRules {

    // MARK: - Rent Calculation

    static func rent(for space: BoardSpace, in state: GameState, diceTotal: Int = 7) -> Int {
        guard let ownerID = space.ownerID, !space.isMortgaged else { return 0 }

        switch space.type {
        case .property:
            let baseRent = space.currentRent
            if space.houses == 0 && !space.hasHotel {
                // Check for monopoly (double rent with no houses)
                if state.hasMonopoly(playerID: ownerID, group: space.colorGroup!) {
                    return baseRent * 2
                }
            }
            return baseRent

        case .railroad:
            let count = state.railroadCount(for: ownerID)
            switch count {
            case 1: return 25
            case 2: return 50
            case 3: return 100
            case 4: return 200
            default: return 25
            }

        case .utility:
            let count = state.utilityCount(for: ownerID)
            return diceTotal * (count == 2 ? 10 : 4)

        default:
            return 0
        }
    }

    // MARK: - Build Validation

    static func canBuildHouse(on space: BoardSpace, for playerID: String, in state: GameState) -> Bool {
        guard let group = space.colorGroup else { return false }
        guard space.ownerID == playerID else { return false }
        guard state.hasMonopoly(playerID: playerID, group: group) else { return false }
        guard !space.isMortgaged else { return false }
        guard space.houses < 4 && !space.hasHotel else { return false }

        // Even building rule
        let groupSpaces = state.board.filter { $0.colorGroup == group }
        let minHouses = groupSpaces.map { $0.houses }.min() ?? 0
        return space.houses <= minHouses
    }

    static func canBuildHotel(on space: BoardSpace, for playerID: String, in state: GameState) -> Bool {
        guard let group = space.colorGroup else { return false }
        guard space.ownerID == playerID else { return false }
        guard state.hasMonopoly(playerID: playerID, group: group) else { return false }
        guard !space.isMortgaged && space.houses == 4 && !space.hasHotel else { return false }
        return true
    }

    static func houseCost(for space: BoardSpace) -> Int {
        return space.colorGroup?.houseCost ?? 0
    }

    // MARK: - Mortgage Math

    static func mortgageValue(for space: BoardSpace) -> Int {
        return space.mortgageValue ?? ((space.price ?? 0) / 2)
    }

    static func unmortgageCost(for space: BoardSpace) -> Int {
        return Int(Double(mortgageValue(for: space)) * 1.1)
    }

    // MARK: - Bankruptcy Check

    static func isBankrupt(player: AIPlayer, in state: GameState) -> Bool {
        if player.cash >= 0 { return false }
        let assets = state.ownedSpaces(for: player.id).reduce(0) { acc, space in
            let mv = mortgageValue(for: space)
            let houseValue = (space.hasHotel ? 5 : space.houses) * (space.colorGroup?.houseCost ?? 0) / 2
            return acc + mv + houseValue
        }
        return player.cash + assets < 0
    }

    // MARK: - Liquidation Value

    static func liquidationValue(for playerID: String, in state: GameState) -> Int {
        state.ownedSpaces(for: playerID).reduce(0) { acc, space in
            mortgageValue(for: space)
        }
    }

    // MARK: - Tax Amounts

    static func incomeTax(for player: AIPlayer, in state: GameState) -> Int {
        let percent = Int(Double(state.calculateNetWorth(for: player.id)) * 0.1)
        return min(percent, BoardSpace.incomeTaxAmount)
    }

    // MARK: - Auction Logic

    static func minimumBid(for space: BoardSpace) -> Int {
        return 1
    }

    // MARK: - Go Salary

    static func passesGo(oldPosition: Int, newPosition: Int) -> Bool {
        return newPosition < oldPosition || (oldPosition == 0 && newPosition == 0)
    }

    // MARK: - Jail

    static func jailPosition() -> Int { 10 }
    static func goToJailPosition() -> Int { 30 }

    // MARK: - Card Deck Shuffling

    static func shuffledChance() -> [MonopolyCard] {
        MonopolyCard.chanceCards.shuffled()
    }

    static func shuffledCommunityChest() -> [MonopolyCard] {
        MonopolyCard.communityChestCards.shuffled()
    }
}
