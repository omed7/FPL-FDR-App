import SwiftUI
import Combine

enum SortOption: Int, Codable {
    case id = 0
    case easiest = 1
    case hardest = 2
}

class FPLManager: ObservableObject {
    @Published var teams: [Team] = []
    @Published var events: [Event] = []
    @Published var fixtures: [Fixture] = []

    // User Preferences
    @Published var startGameweek: Int = 1 {
        didSet {
            savePreferences()
            recomputeFDR()
        }
    }
    @Published var endGameweek: Int = 38 {
        didSet {
            savePreferences()
            recomputeFDR()
        }
    }
    @Published var sortOption: SortOption = .id {
        didSet { savePreferences() }
    }

    // Team Strengths: [TeamID: [Home: Int, Away: Int]]
    @Published var teamStrengths: [Int: [String: Int]] = [:] {
        didSet {
            savePreferences()
            recomputeFDR()
        }
    }

    // Visibility: [TeamID: IsHidden]
    @Published var hiddenTeams: Set<Int> = [] {
        didSet { savePreferences() }
    }

    // Cached FDR Data
    @Published var processedFDR: [Int: Double] = [:]

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

            recomputeFDR()

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
        let visible = teams.filter { !hiddenTeams.contains($0.id) }

        switch sortOption {
        case .id:
            return visible.sorted { $0.id < $1.id }
        case .easiest:
            return visible.sorted {
                (processedFDR[$0.id] ?? 0) < (processedFDR[$1.id] ?? 0)
            }
        case .hardest:
            return visible.sorted {
                (processedFDR[$0.id] ?? 0) > (processedFDR[$1.id] ?? 0)
            }
        }
    }

    func calculateAverageFDR(for teamId: Int) -> Double {
        return processedFDR[teamId] ?? 0.0
    }

    private func recomputeFDR() {
        var newFDR: [Int: Double] = [:]
        for team in teams {
            var total = 0
            var count = 0

            for gw in startGameweek...endGameweek {
                let fixtures = getFixtures(for: team.id, gameweek: gw)
                for f in fixtures {
                    total += f.difficulty
                    count += 1
                }
            }

            if count > 0 {
                newFDR[team.id] = Double(total) / Double(count)
            } else {
                newFDR[team.id] = 0.0
            }
        }
        DispatchQueue.main.async {
            self.processedFDR = newFDR
        }
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
        recomputeFDR()
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
    private let kSort = "FPL_SortOption"

    private func savePreferences() {
        if let data = try? JSONEncoder().encode(teamStrengths) {
            UserDefaults.standard.set(data, forKey: kStrengths)
        }
        if let data = try? JSONEncoder().encode(hiddenTeams) {
            UserDefaults.standard.set(data, forKey: kHidden)
        }
        UserDefaults.standard.set(startGameweek, forKey: kStartGW)
        UserDefaults.standard.set(endGameweek, forKey: kEndGW)
        if let data = try? JSONEncoder().encode(sortOption) {
             UserDefaults.standard.set(data, forKey: kSort)
        }
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

        if let data = UserDefaults.standard.data(forKey: kSort),
           let decoded = try? JSONDecoder().decode(SortOption.self, from: data) {
            sortOption = decoded
        }
    }
}
