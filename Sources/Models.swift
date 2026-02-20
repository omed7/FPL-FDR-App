import Foundation

// MARK: - API Responses

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
}
