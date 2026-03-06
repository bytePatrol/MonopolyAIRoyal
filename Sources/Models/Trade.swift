import Foundation

// MARK: - Trade Offer

struct TradeOffer: Codable {
    var cash: Int = 0
    var propertyIDs: [Int] = []
    var getOutOfJailCards: Int = 0
}

// MARK: - Trade Proposal

struct TradeProposal: Identifiable, Codable {
    var id: String = UUID().uuidString
    var initiatorID: String
    var recipientID: String
    var offering: TradeOffer      // What initiator offers
    var requesting: TradeOffer    // What initiator wants from recipient
    var rationale: String         // AI reasoning text
    var status: TradeStatus = .pending
    var createdAt: Date = Date()
    var resolvedAt: Date?

    enum TradeStatus: String, Codable {
        case pending  = "pending"
        case accepted = "accepted"
        case rejected = "rejected"
        case countered = "countered"
    }
}
