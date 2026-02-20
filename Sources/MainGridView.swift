import SwiftUI
import UIKit

struct MainGridView: View {
    @ObservedObject var manager: FPLManager
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)

                    if manager.isLoading {
                        ProgressView("Loading Data...")
                    } else if let error = manager.errorMessage {
                        VStack {
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                            Button("Retry") {
                                manager.fetchData()
                            }
                            .padding()
                        }
                    } else {
                        // Main Content
                        VStack(spacing: 0) {
                            // Sticky Header Row?
                            // No, vertical scroll view contains header row as first element.

                            ScrollView(.vertical, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 0) {

                                    // LEFT COLUMN (Fixed Horizontally)
                                    VStack(spacing: 0) {
                                        // Header for Left Column
                                        Text("Team")
                                            .font(.caption.bold())
                                            .frame(width: 80, height: 40)
                                            .background(Color(UIColor.secondarySystemBackground))
                                            .border(Color(UIColor.separator), width: 0.5)

                                        ForEach(manager.getSortedTeams()) { team in
                                            let h = rowHeight(for: team)
                                            TeamLeftCell(team: team, fdr: manager.calculateAverageFDR(for: team.id))
                                                .frame(width: 80, height: h)
                                                .background(Color(UIColor.systemBackground))
                                                .border(Color(UIColor.separator), width: 0.5)
                                        }
                                    }
                                    .zIndex(1) // Ensure left column is on top if overlap

                                    // RIGHT GRID (Scrollable Horizontally)
                                    ScrollView(.horizontal, showsIndicators: true) {
                                        VStack(spacing: 0) {
                                            // Header Row for Right Grid
                                            HStack(spacing: 0) { // spacing 0 to use border
                                                ForEach(manager.startGameweek...manager.endGameweek, id: \.self) { gw in
                                                    Text("GW\(gw)")
                                                        .font(.caption.bold())
                                                        .frame(width: 60, height: 40)
                                                        .background(Color(UIColor.secondarySystemBackground))
                                                        .border(Color(UIColor.separator), width: 0.5)
                                                }
                                            }

                                            // Data Rows
                                            ForEach(manager.getSortedTeams()) { team in
                                                let h = rowHeight(for: team)
                                                HStack(spacing: 0) {
                                                    ForEach(manager.startGameweek...manager.endGameweek, id: \.self) { gw in
                                                        let fixtures = manager.getFixtures(for: team.id, gameweek: gw)
                                                        GameweekCellView(fixtures: fixtures)
                                                            .frame(width: 60, height: h)
                                                            .border(Color(UIColor.separator), width: 0.5)
                                                    }
                                                }
                                                .frame(height: h)
                                            }
                                        }
                                    }
                                }
                            }
                        }
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
        }
        .preferredColorScheme(.dark)
    }

    // Calculate row height based on max fixtures in a gameweek for the visible range
    func rowHeight(for team: Team) -> CGFloat {
        var maxFixtures = 1
        // Range optimization: Only iterate visible range
        for gw in manager.startGameweek...manager.endGameweek {
             let count = manager.getFixtures(for: team.id, gameweek: gw).count
             if count > maxFixtures { maxFixtures = count }
        }

        // Base height for 1 fixture = 40
        // Spacing = 2
        // If maxFixtures = 1: 40
        // If maxFixtures = 2: 40 + 2 + 40 = 82
        // If maxFixtures = 3: 40 + 2 + 40 + 2 + 40 = 124
        return CGFloat(maxFixtures * 40 + (maxFixtures - 1) * 2)
    }
}
