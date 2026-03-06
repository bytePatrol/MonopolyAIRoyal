import Foundation

// MARK: - Card Action

enum CardAction: Codable {
    case collectFromBank(amount: Int)
    case payToBank(amount: Int)
    case collectFromEachPlayer(amount: Int)
    case payEachPlayer(amount: Int)
    case moveToSpace(spaceIndex: Int)
    case moveBack(spaces: Int)
    case getOutOfJail
    case goToJail
    case streetRepairs(houseCost: Int, hotelCost: Int)
    case generalRepairs(houseCost: Int, hotelCost: Int)
    case advanceToGo
    case payPercentage(percent: Double)
}

// MARK: - Card

struct MonopolyCard: Identifiable, Codable {
    var id: String = UUID().uuidString
    var type: CardDeckType
    var text: String
    var action: CardAction
}

enum CardDeckType: String, Codable {
    case chance          = "Chance"
    case communityChest  = "Community Chest"
}

// MARK: - All Cards

extension MonopolyCard {
    // MARK: Chance (16 cards)
    static let chanceCards: [MonopolyCard] = [
        MonopolyCard(type: .chance, text: "Advance to Boardwalk.",
                     action: .moveToSpace(spaceIndex: 39)),
        MonopolyCard(type: .chance, text: "Advance to Go. Collect $200.",
                     action: .advanceToGo),
        MonopolyCard(type: .chance, text: "Advance to Illinois Avenue. If you pass Go, collect $200.",
                     action: .moveToSpace(spaceIndex: 24)),
        MonopolyCard(type: .chance, text: "Advance to St. Charles Place. If you pass Go, collect $200.",
                     action: .moveToSpace(spaceIndex: 11)),
        MonopolyCard(type: .chance, text: "Advance token to the nearest Railroad. If unowned, buy it.",
                     action: .moveToSpace(spaceIndex: 5)),  // simplified
        MonopolyCard(type: .chance, text: "Advance token to the nearest Utility. If unowned, buy it.",
                     action: .moveToSpace(spaceIndex: 12)), // simplified
        MonopolyCard(type: .chance, text: "Bank pays you dividend of $50.",
                     action: .collectFromBank(amount: 50)),
        MonopolyCard(type: .chance, text: "Get out of Jail Free.",
                     action: .getOutOfJail),
        MonopolyCard(type: .chance, text: "Go Back Three Spaces.",
                     action: .moveBack(spaces: 3)),
        MonopolyCard(type: .chance, text: "Go to Jail. Do not pass Go.",
                     action: .goToJail),
        MonopolyCard(type: .chance, text: "Make general repairs on all your property. $25 per house, $100 per hotel.",
                     action: .generalRepairs(houseCost: 25, hotelCost: 100)),
        MonopolyCard(type: .chance, text: "Pay poor tax of $15.",
                     action: .payToBank(amount: 15)),
        MonopolyCard(type: .chance, text: "Take a trip to Reading Railroad.",
                     action: .moveToSpace(spaceIndex: 5)),
        MonopolyCard(type: .chance, text: "Take a walk on the Boardwalk.",
                     action: .moveToSpace(spaceIndex: 39)),
        MonopolyCard(type: .chance, text: "You have been elected Chairman of the Board. Pay each player $50.",
                     action: .payEachPlayer(amount: 50)),
        MonopolyCard(type: .chance, text: "Your building loan matures. Collect $150.",
                     action: .collectFromBank(amount: 150)),
    ]

    // MARK: Community Chest (16 cards)
    static let communityChestCards: [MonopolyCard] = [
        MonopolyCard(type: .communityChest, text: "Advance to Go. Collect $200.",
                     action: .advanceToGo),
        MonopolyCard(type: .communityChest, text: "Bank error in your favor. Collect $200.",
                     action: .collectFromBank(amount: 200)),
        MonopolyCard(type: .communityChest, text: "Doctor's fees. Pay $50.",
                     action: .payToBank(amount: 50)),
        MonopolyCard(type: .communityChest, text: "From sale of stock you get $50.",
                     action: .collectFromBank(amount: 50)),
        MonopolyCard(type: .communityChest, text: "Get out of Jail Free.",
                     action: .getOutOfJail),
        MonopolyCard(type: .communityChest, text: "Go to Jail. Do not pass Go.",
                     action: .goToJail),
        MonopolyCard(type: .communityChest, text: "Grand Opera Night. Collect $50 from every player.",
                     action: .collectFromEachPlayer(amount: 50)),
        MonopolyCard(type: .communityChest, text: "Holiday Fund matures. Receive $100.",
                     action: .collectFromBank(amount: 100)),
        MonopolyCard(type: .communityChest, text: "Income tax refund. Collect $20.",
                     action: .collectFromBank(amount: 20)),
        MonopolyCard(type: .communityChest, text: "It is your birthday. Collect $10 from each player.",
                     action: .collectFromEachPlayer(amount: 10)),
        MonopolyCard(type: .communityChest, text: "Life insurance matures. Collect $100.",
                     action: .collectFromBank(amount: 100)),
        MonopolyCard(type: .communityChest, text: "Pay hospital fees of $100.",
                     action: .payToBank(amount: 100)),
        MonopolyCard(type: .communityChest, text: "Pay school fees of $150.",
                     action: .payToBank(amount: 150)),
        MonopolyCard(type: .communityChest, text: "Receive $25 consultancy fee.",
                     action: .collectFromBank(amount: 25)),
        MonopolyCard(type: .communityChest, text: "You are assessed for street repairs: $40/house, $115/hotel.",
                     action: .streetRepairs(houseCost: 40, hotelCost: 115)),
        MonopolyCard(type: .communityChest, text: "You have won second prize in a beauty contest. Collect $10.",
                     action: .collectFromBank(amount: 10)),
    ]
}
