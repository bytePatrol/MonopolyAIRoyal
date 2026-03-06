import Foundation

// MARK: - Commentary Templates (Fallback)

extension CommentaryEngine {

    /// Returns a random snarky template string for the given event type.
    func templateFallback(for event: CommentaryEventType) -> String? {
        let templates: [String]

        switch event {
        case .rent(let player, let amount, let owner, let space):
            templates = Self.rentTemplates
            let t = templates.randomElement() ?? "\(player) just paid $\(amount) rent! Ouch!"
            return resolve(t, player: player, target: owner, amount: amount, space: space)

        case .buy(let player, let space, let amount):
            templates = Self.buyTemplates
            let t = templates.randomElement() ?? "\(player) just acquired \(space)!"
            return resolve(t, player: player, amount: amount, space: space)

        case .jail(let player):
            templates = Self.jailTemplates
            let t = templates.randomElement() ?? "\(player) is going to jail!"
            return resolve(t, player: player)

        case .bankrupt(let player):
            templates = Self.bankruptTemplates
            let t = templates.randomElement() ?? "\(player) has gone bankrupt!"
            return resolve(t, player: player)

        case .tax(let player, let amount, let space):
            templates = Self.taxTemplates
            let t = templates.randomElement() ?? "\(player) paid $\(amount) in taxes."
            return resolve(t, player: player, amount: amount, space: space)

        case .card(let player, let cardText):
            templates = Self.cardTemplates
            let t = templates.randomElement() ?? "\(player) drew a card — anything could happen!"
            return resolve(t, player: player, space: cardText)

        case .build(let player, let space, let cost):
            templates = Self.buildTemplates
            let t = templates.randomElement() ?? "\(player) built a house on \(space)."
            return resolve(t, player: player, amount: cost, space: space)

        case .gameOver(let winner):
            templates = Self.gameOverTemplates
            let t = templates.randomElement() ?? "\(winner) takes the crown! What a game!"
            return resolve(t, player: winner)

        case .colorCommentary:
            templates = Self.colorTemplates
            return templates.randomElement()
        }
    }

    // MARK: - Template Resolver

    private func resolve(_ template: String, player: String = "", target: String = "", amount: Int = 0, space: String = "") -> String {
        template
            .replacingOccurrences(of: "{player}", with: player)
            .replacingOccurrences(of: "{target}", with: target)
            .replacingOccurrences(of: "{amount}", with: "\(amount)")
            .replacingOccurrences(of: "{space}", with: space)
    }

    // MARK: - Rent Templates

    private static let rentTemplates = [
        "{player} just handed {target} a crisp ${amount} for landing on {space}. That's gotta sting.",
        "Ouch! {player} drops ${amount} rent on {space}. {target} is loving this.",
        "{player} pays ${amount} to {target} and you can almost hear the wallet crying.",
        "{target} collects ${amount} from {player} like a toll booth with an attitude.",
        "{player} landed on {space} and {target} just got ${amount} richer. Brutal.",
        "That's ${amount} from {player} straight into {target}'s pocket. Landlords stay winning.",
        "{player} thought {space} was safe. It was not. ${amount} gone.",
        "Rent day hits different when it's ${amount}. {player} just found out the hard way.",
    ]

    // MARK: - Buy Templates

    private static let buyTemplates = [
        "{player} just snagged {space} for ${amount}. Empire building in progress.",
        "{player} drops ${amount} on {space}. Bold move or reckless spending? Time will tell.",
        "And just like that, {space} belongs to {player}. ${amount} well spent... maybe.",
        "{player} couldn't resist {space} at ${amount}. Who could?",
        "{player} adds {space} to the portfolio for ${amount}. The monopoly grows.",
        "SOLD! {space} goes to {player} for ${amount}. The other players are sweating.",
        "{player} bought {space} like it was on clearance. ${amount} — deal or disaster?",
        "{player} picks up {space} for a cool ${amount}. Real estate mogul energy.",
    ]

    // MARK: - Jail Templates

    private static let jailTemplates = [
        "{player} is heading to jail! Do not pass GO, do not collect $200.",
        "And {player} goes directly to jail. The universe has a sense of humor.",
        "{player} got sent to the slammer! Someone call a lawyer.",
        "Jail time for {player}! That's what you get for rolling with the big dogs.",
        "Behind bars! {player} will be sitting this one out.",
        "{player} is locked up. Three turns to think about what they've done.",
        "The long arm of the Monopoly law catches up with {player}!",
        "{player} goes to jail — the other players just breathed a sigh of relief.",
    ]

    // MARK: - Bankrupt Templates

    private static let bankruptTemplates = [
        "{player} has gone BANKRUPT! Another one bites the dust.",
        "It's over for {player}! Bankrupt and out of the game. Devastating.",
        "{player} is officially eliminated. The board claims another victim.",
        "And {player} is done! Bankrupt. That portfolio didn't hold up under pressure.",
        "Pack it up, {player}. Bankruptcy hits and there's no coming back from this one.",
        "ELIMINATED! {player} goes bankrupt in spectacular fashion.",
        "{player} ran out of money and excuses. Bankruptcy it is.",
        "The Monopoly gods show no mercy — {player} is bankrupt and out!",
    ]

    // MARK: - Tax Templates

    private static let taxTemplates = [
        "{player} pays ${amount} in {space}. The government always gets its cut.",
        "Uncle Sam comes for {player} — ${amount} in {space}. Nothing is certain but death and taxes.",
        "{player} loses ${amount} to {space}. Even in Monopoly, taxes are unavoidable.",
        "${amount} gone to {space}. {player} is not having a great turn.",
        "{player} hits {space} for ${amount}. That's the cost of doing business.",
        "Tax time! {player} coughs up ${amount}. The IRS of Monopoly strikes again.",
        "{player} pays ${amount} to the bank. {space} is the cruelest space on the board.",
        "{space} takes ${amount} from {player}. At least it's not rent.",
    ]

    // MARK: - Card Templates

    private static let cardTemplates = [
        "{player} draws a card and fate decides what happens next.",
        "Card time for {player}! Let's see what the Monopoly gods have in store.",
        "{player} reaches into the deck — it's always a gamble.",
        "The card says... well, {player} looks concerned. That can't be good.",
        "{player} pulls a card. In this economy? Bold.",
        "Chance or Community Chest? Either way, {player} is at the mercy of the deck.",
        "{player} draws a card. The suspense is killing me. Well, maybe not me.",
        "The deck has spoken! {player} gets to deal with whatever that was.",
    ]

    // MARK: - Build Templates

    private static let buildTemplates = [
        "{player} builds a house on {space} for ${amount}. The rent just got scarier.",
        "Construction time! {player} drops ${amount} on a house at {space}.",
        "{player} is building on {space}. ${amount} invested and the trap is set.",
        "A new house rises on {space} courtesy of {player}. That's ${amount} in development.",
        "{player} upgrades {space} with a new house. ${amount} spent, future rent collected.",
        "Watch out — {player} just built on {space} for ${amount}. That neighborhood is getting expensive.",
        "{player} puts a house on {space}. ${amount} now, but the rent payoff will be glorious.",
        "Building boom! {player} develops {space} for ${amount}. Smart money or panic building?",
    ]

    // MARK: - Game Over Templates

    private static let gameOverTemplates = [
        "{player} takes the crown! What an absolute masterclass in Monopoly domination.",
        "GAME OVER! {player} wins and the crowd goes wild! Well, the AI crowd anyway.",
        "And your winner is... {player}! Bow down to the Monopoly champion.",
        "{player} did it! Victory! Someone get this AI a trophy.",
        "That's the game, folks! {player} stands alone at the top. What a battle.",
        "THE CHAMPION! {player} survives the Monopoly gauntlet and claims victory!",
        "{player} wins! If AIs could celebrate, this would be the moment.",
        "All hail {player}, the undisputed Monopoly AI Royal champion!",
    ]

    // MARK: - Color Commentary Templates

    private static let colorTemplates = [
        "The tension at this table could be cut with a knife. Or a very expensive hotel.",
        "Someone's about to make a very expensive mistake. I can feel it.",
        "This is the kind of game they'll talk about in AI history classes. Maybe.",
        "The board is getting crowded and wallets are getting thin. Something's gotta give.",
        "You know what they say — location, location, bankruptcy.",
        "Every property is a landmine now. One wrong roll and it's curtains.",
        "The rich get richer and the poor get... well, bankrupt.",
        "I've seen friendlier games of chess. And those don't even have rent.",
        "We're deep into this game and the gloves are officially off.",
        "At this point, landing on Free Parking feels like winning the lottery.",
        "The property market is brutal today. Multiple AIs are one bad roll from disaster.",
        "This game has more drama than a reality TV show. And better strategy.",
    ]
}
