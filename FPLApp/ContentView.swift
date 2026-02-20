import SwiftUI

struct ContentView: View {
    @StateObject var manager = FPLManager()
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                if manager.isLoading {
                    ProgressView("Loading FPL Data...")
                        .preferredColorScheme(.dark)
                } else if let error = manager.errorMessage {
                    VStack {
                        Text("Error Loading Data")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .padding()
                        Button("Retry") {
                            Task { await manager.fetchData() }
                        }
                    }
                } else {
                    MainGridView(manager: manager)
                }
            }
            .navigationTitle("FPL FDR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(manager: manager)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct MainGridView: View {
    @ObservedObject var manager: FPLManager

    var body: some View {
        let teams = manager.getSortedTeams()
        let gameweeks = Array(manager.startGameweek...manager.endGameweek)

        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                // Sticky Left Column
                LazyVStack(spacing: 0) {
                    // Header
                    Text("Team")
                        .font(.caption.bold())
                        .frame(width: 80, height: 40)
                        .background(.ultraThinMaterial)
                        .border(Color.white.opacity(0.1))

                    // Team Rows
                    ForEach(teams) { team in
                        let height = rowHeight(for: team, gameweeks: gameweeks)
                        TeamLeftCellView(team: team, fdr: manager.calculateAverageFDR(for: team.id))
                            .frame(width: 80, height: height)
                            .background(.ultraThinMaterial)
                            .border(Color.white.opacity(0.1))
                    }
                }
                .zIndex(1)

                // Scrollable Right Grid
                ScrollView(.horizontal, showsIndicators: true) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        // Header Row
                        LazyHStack(spacing: 0) {
                            ForEach(gameweeks, id: \.self) { gw in
                                Text("GW\(gw)")
                                    .font(.caption.bold())
                                    .frame(width: 60, height: 40)
                                    .background(Color(white: 0.1))
                                    .border(Color.white.opacity(0.1))
                            }
                        }

                        // Data Rows
                        ForEach(teams) { team in
                            let height = rowHeight(for: team, gameweeks: gameweeks)
                            LazyHStack(spacing: 0) {
                                ForEach(gameweeks, id: \.self) { gw in
                                    let fixtures = manager.getFixtures(for: team.id, gameweek: gw)
                                    Group {
                                        if fixtures.isEmpty {
                                            BlankGameweekCell()
                                        } else {
                                            VStack(spacing: 2) {
                                                ForEach(fixtures) { fixture in
                                                    FixtureCellView(fixture: fixture)
                                                }
                                            }
                                        }
                                    }
                                    .frame(width: 60, height: height)
                                    .border(Color.white.opacity(0.1))
                                }
                            }
                            .frame(height: height)
                        }
                    }
                }
            }
        }
    }

    func rowHeight(for team: Team, gameweeks: [Int]) -> CGFloat {
        // Calculate the maximum number of fixtures any team has in a single gameweek to determine row height
        var maxFixtures = 1
        for gw in gameweeks {
            let count = manager.getFixtures(for: team.id, gameweek: gw).count
            if count > maxFixtures { maxFixtures = count }
        }
        // Base height 40 per fixture + spacing
        return CGFloat(maxFixtures * 40 + (maxFixtures - 1) * 2)
    }
}
