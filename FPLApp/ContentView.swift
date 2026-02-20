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
    @StateObject private var scrollManager = ScrollSyncManager()
    @State private var selectedFixture: FixtureDisplay?

    var body: some View {
        let gameweeks = Array(manager.startGameweek...manager.endGameweek)

        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section(header: SyncedHeaderView(gameweeks: gameweeks, scrollManager: scrollManager)) {
                    SyncedGridBodyView(rows: manager.gridRows, scrollManager: scrollManager, selectedFixture: $selectedFixture)
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .refreshable {
            await manager.fetchData()
        }
        .sheet(item: $selectedFixture) { fixture in
            FixtureDetailView(fixture: fixture)
        }
    }
}

struct FixtureDetailView: View {
    let fixture: FixtureDisplay

    var body: some View {
        VStack(spacing: 20) {
            AsyncImage(url: URL(string: "https://resources.premierleague.com/premierleague/badges/50/t\(fixture.opponentCode).png")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                } else if phase.error != nil {
                     ZStack {
                         Circle().fill(Color.gray)
                         Text(fixture.opponentShortName).font(.caption2)
                     }
                } else {
                    ProgressView()
                }
            }
            .frame(width: 80, height: 80)

            Text(fixture.opponentShortName)
                .font(.title)
                .bold()

            Text(fixture.isHome ? "Home" : "Away")
                .font(.headline)

            if let date = fixture.date {
                Text(date, style: .date)
                Text(date, style: .time)
            }

            Text("Difficulty: \(fixture.difficulty)")
                .padding()
                .background(Theme.color(for: fixture.difficulty))
                .cornerRadius(8)
        }
        .padding()
        .presentationDetents([.medium, .fraction(0.4)])
    }
}
