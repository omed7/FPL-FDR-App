import SwiftUI
import Combine

class FPLManager: ObservableObject {
    @Published var teams: [Team] = []
    @Published var events: [Event] = []
    @Published var fixtures: [Fixture] = []

    // User Preferences
    @Published var startGameweek: Int = 1 {
        didSet { savePreferences() }
    }
    @Published var endGameweek: Int = 38 {
        didSet { savePreferences() }
    }
    @Published var sortByEase: Bool = false {
        didSet { savePreferences() }
    }

    // Team Strengths: [TeamID: [Home: Int, Away: Int]]
    @Published var teamStrengths: [Int: [String: Int]] = [:] {
        didSet { savePreferences() }
    }

    // Visibility: [TeamID: IsHidden] (Inverse logic, or IsVisible)
    // Prompt says "Show/Hide" and "dimming effect for hidden teams".
    // I'll store `hiddenTeams: Set<Int>`
    @Published var hiddenTeams: Set<Int> = [] {
        didSet { savePreferences() }
    }

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Date formatter for parsing
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    init() {
        loadPreferences()
        Task {
            await fetchData()
        }
    }

    // MARK: - Data Fetching

    @MainActor
    func fetchData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let teamsData = fetch(url: "https://fantasy.premierleague.com/api/bootstrap-static/", type: BootstrapStaticResponse.self)
            async let fixturesData = fetch(url: "https://fantasy.premierleague.com/api/fixtures/", type: [Fixture].self)

            let (bootstrap, fixturesList) = try await (teamsData, fixturesData)

            self.teams = bootstrap.teams
            self.events = bootstrap.events.filter { !$0.finished }
            self.fixtures = fixturesList

            // Set default range based on current events if not already set or valid
            if let firstActive = self.events.first {
                if self.startGameweek < firstActive.id {
                    self.startGameweek = firstActive.id
                }
            }

            // Initialize strengths if missing
            for team in self.teams {
                if self.teamStrengths[team.id] == nil {
                    self.teamStrengths[team.id] = ["home": 3, "away": 3]
                }
            }

        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func fetch<T: Decodable>(url: String, type: T.Type) async throws -> T {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(type, from: data)
    }

    // MARK: - Logic

    func getSortedTeams() -> [Team] {
        // We only sort visible teams? Or all teams but hidden ones are dimmed?
        // "Display a highly visual, tappable grid of team logos to easily toggle teams (Show/Hide) with a dimming effect for hidden teams."
        // This implies the main grid might hide them, or show them dimmed.
        // Usually, hidden teams are removed from the main view.
        // I will return all teams, but sorted. The View will handle dimming/hiding.
        // Actually, "Toggle teams (Show/Hide)" usually means remove from list.
        // Let's filter out hidden teams for the main grid.
        let visible = teams.filter { !hiddenTeams.contains($0.id) }

        if sortByEase {
            return visible.sorted {
                calculateAverageFDR(for: $0.id) < calculateAverageFDR(for: $1.id)
            }
        } else {
            return visible.sorted { $0.id < $1.id }
        }
    }

    func calculateAverageFDR(for teamId: Int) -> Double {
        var total = 0
        var count = 0

        for gw in startGameweek...endGameweek {
            let fixtures = getFixtures(for: teamId, gameweek: gw)
            for f in fixtures {
                total += f.difficulty
                count += 1
            }
        }

        guard count > 0 else { return 0.0 }
        return Double(total) / Double(count)
    }

    func getFixtures(for teamId: Int, gameweek: Int) -> [FixtureDisplay] {
        // Filter fixtures for this team and gw
        let teamFixtures = fixtures.filter {
            ($0.team_h == teamId || $0.team_a == teamId) && $0.event == gameweek
        }

        return teamFixtures.map { f in
            let isHome = (f.team_h == teamId)
            let opponentId = isHome ? f.team_a : f.team_h
            let opponentName = teams.first(where: { $0.id == opponentId })?.short_name ?? "UNK"

            // Difficulty = Opponent's Strength
            // If I am Home, Opponent is Away -> Use Opponent's Away Strength
            let opponentIsHome = !isHome
            let strength = getStrength(teamId: opponentId, location: opponentIsHome ? "home" : "away")

            let date = dateFormatter.date(from: f.kickoff_time ?? "")

            return FixtureDisplay(
                fixtureId: f.id,
                opponentId: opponentId,
                opponentShortName: opponentName,
                difficulty: strength,
                isHome: isHome,
                date: date
            )
        }.sorted { ($0.date ?? Date.distantFuture) < ($1.date ?? Date.distantFuture) }
    }

    func getStrength(teamId: Int, location: String) -> Int {
        return teamStrengths[teamId]?[location] ?? 3
    }

    func updateStrength(teamId: Int, location: String, value: Int) {
        if teamStrengths[teamId] == nil {
            teamStrengths[teamId] = ["home": 3, "away": 3]
        }
        teamStrengths[teamId]?[location] = value
    }

    func toggleVisibility(teamId: Int) {
        if hiddenTeams.contains(teamId) {
            hiddenTeams.remove(teamId)
        } else {
            hiddenTeams.insert(teamId)
        }
    }

    // MARK: - Persistence

    private let kStrengths = "FPL_TeamStrengths"
    private let kHidden = "FPL_HiddenTeams"
    private let kStartGW = "FPL_StartGW"
    private let kEndGW = "FPL_EndGW"
    private let kSort = "FPL_Sort"

    private func savePreferences() {
        if let data = try? JSONEncoder().encode(teamStrengths) {
            UserDefaults.standard.set(data, forKey: kStrengths)
        }
        if let data = try? JSONEncoder().encode(hiddenTeams) {
            UserDefaults.standard.set(data, forKey: kHidden)
        }
        UserDefaults.standard.set(startGameweek, forKey: kStartGW)
        UserDefaults.standard.set(endGameweek, forKey: kEndGW)
        UserDefaults.standard.set(sortByEase, forKey: kSort)
    }

    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: kStrengths),
           let decoded = try? JSONDecoder().decode([Int: [String: Int]].self, from: data) {
            teamStrengths = decoded
        }

        if let data = UserDefaults.standard.data(forKey: kHidden),
           let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            hiddenTeams = decoded
        }

        let start = UserDefaults.standard.integer(forKey: kStartGW)
        if start > 0 { startGameweek = start }

        let end = UserDefaults.standard.integer(forKey: kEndGW)
        if end > 0 { endGameweek = end }

        if UserDefaults.standard.object(forKey: kSort) != nil {
            sortByEase = UserDefaults.standard.bool(forKey: kSort)
        }
    }
}
