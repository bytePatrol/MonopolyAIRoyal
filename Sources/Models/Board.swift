import Foundation
import SwiftUI

// MARK: - Board Space Type

enum SpaceType: String, Codable {
    case property    = "property"
    case railroad    = "railroad"
    case utility     = "utility"
    case corner      = "corner"
    case tax         = "tax"
    case card        = "card"   // Chance or Community Chest
}

// MARK: - Color Group

enum ColorGroup: String, Codable, CaseIterable {
    case brown     = "brown"
    case lightBlue = "lightblue"
    case pink      = "pink"
    case orange    = "orange"
    case red       = "red"
    case yellow    = "yellow"
    case green     = "green"
    case darkBlue  = "darkblue"

    var groupSize: Int {
        switch self {
        case .brown, .darkBlue: return 2
        default:                return 3
        }
    }

    var color: Color { boardGroupColor(for: rawValue) }

    var houseCost: Int {
        switch self {
        case .brown, .lightBlue:     return 50
        case .pink, .orange:         return 100
        case .red, .yellow:          return 150
        case .green, .darkBlue:      return 200
        }
    }
}

// MARK: - Board Space

struct BoardSpace: Identifiable, Codable, Equatable {
    var id: Int              // 0-39
    var name: String
    var type: SpaceType
    var colorGroup: ColorGroup?
    var price: Int?
    var baseRent: Int?       // No houses
    var rent1: Int?
    var rent2: Int?
    var rent3: Int?
    var rent4: Int?
    var hotelRent: Int?
    var mortgageValue: Int?  // = price / 2
    var isMortgaged: Bool = false
    var ownerID: String? = nil
    var houses: Int = 0
    var hasHotel: Bool = false

    // For railroads: rent scales with number owned
    // For utilities: rent is dice × multiplier

    var currentRent: Int {
        guard type == .property else { return 0 }
        if hasHotel { return hotelRent ?? baseRent ?? 0 }
        switch houses {
        case 1: return rent1 ?? baseRent ?? 0
        case 2: return rent2 ?? baseRent ?? 0
        case 3: return rent3 ?? baseRent ?? 0
        case 4: return rent4 ?? baseRent ?? 0
        default: return baseRent ?? 0
        }
    }

    var isCorner: Bool { type == .corner }
    var isChance: Bool { type == .card && (name.contains("Chance")) }
    var isCommunityChest: Bool { type == .card && (name.contains("Community")) }
}

// MARK: - Full Board Definition (40 spaces)

extension BoardSpace {
    static let allSpaces: [BoardSpace] = [
        // 0 - GO
        BoardSpace(id: 0, name: "GO", type: .corner),
        // 1 - Mediterranean Ave (Brown)
        BoardSpace(id: 1, name: "Mediterranean Ave", type: .property, colorGroup: .brown,
                   price: 60, baseRent: 2, rent1: 10, rent2: 30, rent3: 90, rent4: 160, hotelRent: 250, mortgageValue: 30),
        // 2 - Community Chest
        BoardSpace(id: 2, name: "Community Chest", type: .card),
        // 3 - Baltic Ave (Brown)
        BoardSpace(id: 3, name: "Baltic Ave", type: .property, colorGroup: .brown,
                   price: 60, baseRent: 4, rent1: 20, rent2: 60, rent3: 180, rent4: 320, hotelRent: 450, mortgageValue: 30),
        // 4 - Income Tax
        BoardSpace(id: 4, name: "Income Tax", type: .tax),
        // 5 - Reading Railroad
        BoardSpace(id: 5, name: "Reading Railroad", type: .railroad, price: 200, baseRent: 25, mortgageValue: 100),
        // 6 - Oriental Ave (Light Blue)
        BoardSpace(id: 6, name: "Oriental Ave", type: .property, colorGroup: .lightBlue,
                   price: 100, baseRent: 6, rent1: 30, rent2: 90, rent3: 270, rent4: 400, hotelRent: 550, mortgageValue: 50),
        // 7 - Chance
        BoardSpace(id: 7, name: "Chance", type: .card),
        // 8 - Vermont Ave (Light Blue)
        BoardSpace(id: 8, name: "Vermont Ave", type: .property, colorGroup: .lightBlue,
                   price: 100, baseRent: 6, rent1: 30, rent2: 90, rent3: 270, rent4: 400, hotelRent: 550, mortgageValue: 50),
        // 9 - Connecticut Ave (Light Blue)
        BoardSpace(id: 9, name: "Connecticut Ave", type: .property, colorGroup: .lightBlue,
                   price: 120, baseRent: 8, rent1: 40, rent2: 100, rent3: 300, rent4: 450, hotelRent: 600, mortgageValue: 60),
        // 10 - Jail (Just Visiting)
        BoardSpace(id: 10, name: "JAIL", type: .corner),
        // 11 - St. Charles Place (Pink)
        BoardSpace(id: 11, name: "St. Charles Place", type: .property, colorGroup: .pink,
                   price: 140, baseRent: 10, rent1: 50, rent2: 150, rent3: 450, rent4: 625, hotelRent: 750, mortgageValue: 70),
        // 12 - Electric Company
        BoardSpace(id: 12, name: "Electric Company", type: .utility, price: 150, mortgageValue: 75),
        // 13 - States Ave (Pink)
        BoardSpace(id: 13, name: "States Ave", type: .property, colorGroup: .pink,
                   price: 140, baseRent: 10, rent1: 50, rent2: 150, rent3: 450, rent4: 625, hotelRent: 750, mortgageValue: 70),
        // 14 - Virginia Ave (Pink)
        BoardSpace(id: 14, name: "Virginia Ave", type: .property, colorGroup: .pink,
                   price: 160, baseRent: 12, rent1: 60, rent2: 180, rent3: 500, rent4: 700, hotelRent: 900, mortgageValue: 80),
        // 15 - Pennsylvania Railroad
        BoardSpace(id: 15, name: "Pennsylvania Railroad", type: .railroad, price: 200, baseRent: 25, mortgageValue: 100),
        // 16 - St. James Place (Orange)
        BoardSpace(id: 16, name: "St. James Place", type: .property, colorGroup: .orange,
                   price: 180, baseRent: 14, rent1: 70, rent2: 200, rent3: 550, rent4: 750, hotelRent: 950, mortgageValue: 90),
        // 17 - Community Chest
        BoardSpace(id: 17, name: "Community Chest", type: .card),
        // 18 - Tennessee Ave (Orange)
        BoardSpace(id: 18, name: "Tennessee Ave", type: .property, colorGroup: .orange,
                   price: 180, baseRent: 14, rent1: 70, rent2: 200, rent3: 550, rent4: 750, hotelRent: 950, mortgageValue: 90),
        // 19 - New York Ave (Orange)
        BoardSpace(id: 19, name: "New York Ave", type: .property, colorGroup: .orange,
                   price: 200, baseRent: 16, rent1: 80, rent2: 220, rent3: 600, rent4: 800, hotelRent: 1000, mortgageValue: 100),
        // 20 - Free Parking
        BoardSpace(id: 20, name: "Free Parking", type: .corner),
        // 21 - Kentucky Ave (Red)
        BoardSpace(id: 21, name: "Kentucky Ave", type: .property, colorGroup: .red,
                   price: 220, baseRent: 18, rent1: 90, rent2: 250, rent3: 700, rent4: 875, hotelRent: 1050, mortgageValue: 110),
        // 22 - Chance
        BoardSpace(id: 22, name: "Chance", type: .card),
        // 23 - Indiana Ave (Red)
        BoardSpace(id: 23, name: "Indiana Ave", type: .property, colorGroup: .red,
                   price: 220, baseRent: 18, rent1: 90, rent2: 250, rent3: 700, rent4: 875, hotelRent: 1050, mortgageValue: 110),
        // 24 - Illinois Ave (Red)
        BoardSpace(id: 24, name: "Illinois Ave", type: .property, colorGroup: .red,
                   price: 240, baseRent: 20, rent1: 100, rent2: 300, rent3: 750, rent4: 925, hotelRent: 1100, mortgageValue: 120),
        // 25 - B&O Railroad
        BoardSpace(id: 25, name: "B&O Railroad", type: .railroad, price: 200, baseRent: 25, mortgageValue: 100),
        // 26 - Atlantic Ave (Yellow)
        BoardSpace(id: 26, name: "Atlantic Ave", type: .property, colorGroup: .yellow,
                   price: 260, baseRent: 22, rent1: 110, rent2: 330, rent3: 800, rent4: 975, hotelRent: 1150, mortgageValue: 130),
        // 27 - Ventnor Ave (Yellow)
        BoardSpace(id: 27, name: "Ventnor Ave", type: .property, colorGroup: .yellow,
                   price: 260, baseRent: 22, rent1: 110, rent2: 330, rent3: 800, rent4: 975, hotelRent: 1150, mortgageValue: 130),
        // 28 - Water Works
        BoardSpace(id: 28, name: "Water Works", type: .utility, price: 150, mortgageValue: 75),
        // 29 - Marvin Gardens (Yellow)
        BoardSpace(id: 29, name: "Marvin Gardens", type: .property, colorGroup: .yellow,
                   price: 280, baseRent: 24, rent1: 120, rent2: 360, rent3: 850, rent4: 1025, hotelRent: 1200, mortgageValue: 140),
        // 30 - Go To Jail
        BoardSpace(id: 30, name: "GO TO JAIL", type: .corner),
        // 31 - Pacific Ave (Green)
        BoardSpace(id: 31, name: "Pacific Ave", type: .property, colorGroup: .green,
                   price: 300, baseRent: 26, rent1: 130, rent2: 390, rent3: 900, rent4: 1100, hotelRent: 1275, mortgageValue: 150),
        // 32 - North Carolina Ave (Green)
        BoardSpace(id: 32, name: "North Carolina Ave", type: .property, colorGroup: .green,
                   price: 300, baseRent: 26, rent1: 130, rent2: 390, rent3: 900, rent4: 1100, hotelRent: 1275, mortgageValue: 150),
        // 33 - Community Chest
        BoardSpace(id: 33, name: "Community Chest", type: .card),
        // 34 - Pennsylvania Ave (Green)
        BoardSpace(id: 34, name: "Pennsylvania Ave", type: .property, colorGroup: .green,
                   price: 320, baseRent: 28, rent1: 150, rent2: 450, rent3: 1000, rent4: 1200, hotelRent: 1400, mortgageValue: 160),
        // 35 - Short Line Railroad
        BoardSpace(id: 35, name: "Short Line Railroad", type: .railroad, price: 200, baseRent: 25, mortgageValue: 100),
        // 36 - Chance
        BoardSpace(id: 36, name: "Chance", type: .card),
        // 37 - Park Place (Dark Blue)
        BoardSpace(id: 37, name: "Park Place", type: .property, colorGroup: .darkBlue,
                   price: 350, baseRent: 35, rent1: 175, rent2: 500, rent3: 1100, rent4: 1300, hotelRent: 1500, mortgageValue: 175),
        // 38 - Luxury Tax
        BoardSpace(id: 38, name: "Luxury Tax", type: .tax),
        // 39 - Boardwalk (Dark Blue)
        BoardSpace(id: 39, name: "Boardwalk", type: .property, colorGroup: .darkBlue,
                   price: 400, baseRent: 50, rent1: 200, rent2: 600, rent3: 1400, rent4: 1700, hotelRent: 2000, mortgageValue: 200),
    ]

    // Railroad IDs
    static let railroadIDs: Set<Int> = [5, 15, 25, 35]
    // Utility IDs
    static let utilityIDs:  Set<Int> = [12, 28]
    // Tax amounts
    static let incomeTaxAmount: Int  = 200
    static let luxuryTaxAmount: Int  = 100
    // Go salary
    static let goSalary: Int = 200

    // Grid position for BoardView rendering
    func gridPosition() -> (row: Int, col: Int) {
        let i = id
        if i <= 10       { return (row: 10, col: 10 - i) }
        else if i <= 19  { return (row: 10 - (i - 10), col: 0) }
        else if i <= 30  { return (row: 0, col: i - 20) }
        else             { return (row: i - 30, col: 10) }
    }
}
