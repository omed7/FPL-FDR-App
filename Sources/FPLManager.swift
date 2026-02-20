import SwiftUI
import Combine

// MARK: - Filter Models

struct FixtureDisplay: Identifiable {
    let id = UUID()
    let fixtureId: Int
    let opponentId: Int
    let opponentShortName: String
    let difficulty: Int
    let isHome: Bool
    let date: Date?
}

// MARK: - Manager

class FPLManager: ObservableObject {

    // MARK: - Published Properties

    @Published var teams: [Team] = []
    @Published var events: [Event] = []
    @Published var fixtures: [Fixture] = []

    // Key: Team ID, Value: (Home Difficulty, Away Difficulty)
    @Published var teamDifficultyRatings: [Int: [String: Int]] = [:]

    // Key: Team ID, Value: Is Visible
    @Published var teamVisibility: [Int: Bool] = [:]

    @Published var startGameweek: Int = 1
    @Published var endGameweek: Int = 38
    @Published var sortByEase: Bool = false

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Helper Maps
    private var teamMap: [Int: Team] = [:]
    private var fixturesByTeamAndEvent: [Int: [Int: [Fixture]]] = [:] // TeamID -> EventID -> [Fixture]

    private var cancellables = Set<AnyCancellable>()

    // Constants
    let defaultDifficulty = 3

    // Formatter
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    init() {
        loadPreferences()
        // If data is empty, fetch? User will likely trigger or we trigger on appear.
        // We'll trigger fetch immediately.
        fetchData()
    }

    // MARK: - Data Fetching

    func fetchData() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        let teamsUrl = URL(string: "https://fantasy.premierleague.com/api/bootstrap-static/")!
        let fixturesUrl = URL(string: "https://fantasy.premierleague.com/api/fixtures/")!

        let teamsPublisher = URLSession.shared.dataTaskPublisher(for: teamsUrl)
            .map { $0.data }
            .decode(type: BootstrapStaticResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        let fixturesPublisher = URLSession.shared.dataTaskPublisher(for: fixturesUrl)
            .map { $0.data }
            .decode(type: [Fixture].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        Publishers.Zip(teamsPublisher, fixturesPublisher)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = "Failed to load data: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] (bootstrap, fixturesList) in
                self?.processData(bootstrap: bootstrap, fixturesList: fixturesList)
            })
            .store(in: &cancellables)
    }

    private func processData(bootstrap: BootstrapStaticResponse, fixturesList: [Fixture]) {
        self.teams = bootstrap.teams

        // Filter out finished events
        let activeEvents = bootstrap.events.filter { !$0.finished }
        self.events = activeEvents

        self.fixtures = fixturesList

        // Update Team Map
        self.teamMap = Dictionary(uniqueKeysWithValues: teams.map { ($0.id, $0) })

        // Initialize preferences for new teams if needed
        for team in teams {
            if teamDifficultyRatings[team.id] == nil {
                // Default to 3
                teamDifficultyRatings[team.id] = ["home": defaultDifficulty, "away": defaultDifficulty]
            }
            if teamVisibility[team.id] == nil {
                teamVisibility[team.id] = true
            }
        }

        // Pre-process fixtures for fast lookup
        // fixturesByTeamAndEvent: TeamID -> EventID -> [Fixture]
        var lookup: [Int: [Int: [Fixture]]] = [:]

        for fixture in fixturesList {
            guard let eventId = fixture.event else { continue }

            // Add for Home Team
            if lookup[fixture.team_h] == nil { lookup[fixture.team_h] = [:] }
            if lookup[fixture.team_h]?[eventId] == nil { lookup[fixture.team_h]?[eventId] = [] }
            lookup[fixture.team_h]?[eventId]?.append(fixture)

            // Add for Away Team
            if lookup[fixture.team_a] == nil { lookup[fixture.team_a] = [:] }
            if lookup[fixture.team_a]?[eventId] == nil { lookup[fixture.team_a]?[eventId] = [] }
            lookup[fixture.team_a]?[eventId]?.append(fixture)
        }
        self.fixturesByTeamAndEvent = lookup

        // Set default start/end gameweek based on active events
        if let first = activeEvents.first {
            // Only update startGameweek if it's less than current active
            if self.startGameweek < first.id {
                self.startGameweek = first.id
            }
        }

        // Ensure endGameweek is valid
        if self.endGameweek > 38 { self.endGameweek = 38 }
        if self.startGameweek > self.endGameweek { self.startGameweek = self.endGameweek }
    }

    // MARK: - Logic & Helpers

    func getSortedTeams() -> [Team] {
        let visibleTeams = teams.filter { teamVisibility[$0.id] ?? true }

        if sortByEase {
            return visibleTeams.sorted { teamA, teamB in
                let avgA = calculateAverageFDR(for: teamA.id)
                let avgB = calculateAverageFDR(for: teamB.id)
                return avgA < avgB // Lower is easier
            }
        } else {
            return visibleTeams.sorted { $0.id < $1.id } // Default API Order (usually alphabetical-ish or by ID)
        }
    }

    func calculateAverageFDR(for teamId: Int) -> Double {
        var totalDifficulty = 0
        var count = 0

        // Iterate through gameweeks in range
        // Note: events might be sparse, so we iterate from startGameweek to endGameweek integers
        for gw in startGameweek...endGameweek {
            let fixtures = getFixtures(for: teamId, gameweek: gw)
            for fixture in fixtures {
                totalDifficulty += fixture.difficulty
                count += 1
            }
        }

        guard count > 0 else { return 0.0 }
        return Double(totalDifficulty) / Double(count)
    }

    func getFixtures(for teamId: Int, gameweek: Int) -> [FixtureDisplay] {
        guard let teamFixtures = fixturesByTeamAndEvent[teamId]?[gameweek] else {
            return []
        }

        return teamFixtures.map { fixture in
            let isHome = (fixture.team_h == teamId)
            let opponentId = isHome ? fixture.team_a : fixture.team_h
            let opponent = teamMap[opponentId]

            // Difficulty Calculation
            // If I am Home, opponent is Away -> Use Opponent's Away Strength
            // If I am Away, opponent is Home -> Use Opponent's Home Strength
            let opponentIsHome = !isHome
            let strength = getStrength(teamId: opponentId, location: opponentIsHome ? "home" : "away")

            let date = FPLManager.dateFormatter.date(from: fixture.kickoff_time ?? "")

            return FixtureDisplay(
                fixtureId: fixture.id,
                opponentId: opponentId,
                opponentShortName: opponent?.short_name ?? "UNK",
                difficulty: strength,
                isHome: isHome,
                date: date
            )
        }.sorted { (a, b) in
            // Sort fixtures in same gameweek by date
            (a.date ?? Date.distantFuture) < (b.date ?? Date.distantFuture)
        }
    }

    func getStrength(teamId: Int, location: String) -> Int {
        // location: "home" or "away"
        guard let ratings = teamDifficultyRatings[teamId] else { return defaultDifficulty }
        return ratings[location] ?? defaultDifficulty
    }

    func updateStrength(teamId: Int, location: String, value: Int) {
        if teamDifficultyRatings[teamId] == nil {
            teamDifficultyRatings[teamId] = ["home": defaultDifficulty, "away": defaultDifficulty]
        }
        teamDifficultyRatings[teamId]?[location] = value
        savePreferences()
    }

    func toggleVisibility(teamId: Int) {
        let current = teamVisibility[teamId] ?? true
        teamVisibility[teamId] = !current
        savePreferences()
    }

    // MARK: - Persistence

    private let ratingsKey = "FPL_TeamRatings"
    private let visibilityKey = "FPL_TeamVisibility"
    private let sortKey = "FPL_SortByEase"
    private let startGwKey = "FPL_StartGW"
    private let endGwKey = "FPL_EndGW"

    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(teamDifficultyRatings) {
            UserDefaults.standard.set(encoded, forKey: ratingsKey)
        }
        if let encoded = try? JSONEncoder().encode(teamVisibility) {
            UserDefaults.standard.set(encoded, forKey: visibilityKey)
        }
        UserDefaults.standard.set(sortByEase, forKey: sortKey)
        UserDefaults.standard.set(startGameweek, forKey: startGwKey)
        UserDefaults.standard.set(endGameweek, forKey: endGwKey)
    }

    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: ratingsKey),
           let decoded = try? JSONDecoder().decode([Int: [String: Int]].self, from: data) {
            teamDifficultyRatings = decoded
        }

        if let data = UserDefaults.standard.data(forKey: visibilityKey),
           let decoded = try? JSONDecoder().decode([Int: Bool].self, from: data) {
            teamVisibility = decoded
        }

        if UserDefaults.standard.object(forKey: sortKey) != nil {
            sortByEase = UserDefaults.standard.bool(forKey: sortKey)
        }

        let savedStart = UserDefaults.standard.integer(forKey: startGwKey)
        if savedStart > 0 { startGameweek = savedStart }

        let savedEnd = UserDefaults.standard.integer(forKey: endGwKey)
        if savedEnd > 0 { endGameweek = savedEnd }
    }
}
