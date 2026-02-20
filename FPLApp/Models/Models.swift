import Foundation

// MARK: - API Response Models

struct BootstrapStaticResponse: Codable {
    let teams: [Team]
    let events: [Event]
}

struct Team: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let short_name: String
    let code: Int
}

struct Event: Codable, Identifiable {
    let id: Int
    let name: String
    let finished: Bool
    let data_checked: Bool
    let is_current: Bool
    let is_next: Bool
}

struct Fixture: Codable, Identifiable {
    let id: Int
    let event: Int?
    let team_h: Int
    let team_a: Int
    let finished: Bool
    let kickoff_time: String?
    let difficulty: Int? // API provided difficulty, we might ignore this for our custom system
}

// MARK: - App Logic Models

struct FixtureDisplay: Identifiable {
    let id = UUID()
    let fixtureId: Int
    let opponentId: Int
    let opponentShortName: String
    let difficulty: Int
    let isHome: Bool
    let date: Date?
}
