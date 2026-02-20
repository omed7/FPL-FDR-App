import SwiftUI

// Moved from SettingsView and updated to use AsyncImage
struct TeamLogoView: View {
    let team: Team

    var body: some View {
        AsyncImage(url: URL(string: "https://resources.premierleague.com/premierleague/badges/50/t\(team.code).png")) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
            } else if phase.error != nil {
                 // Fallback
                 ZStack {
                     Circle().fill(Color.gray)
                     Text(team.short_name).font(.caption2)
                 }
            } else {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .frame(width: 40, height: 40)
    }
}

struct TeamLeftCellView: View {
    let team: Team
    let averageFDR: Double

    var body: some View {
        VStack(spacing: 2) {
            TeamLogoView(team: team)

            Text(String(format: "%.2f", averageFDR))
                .font(.caption2.bold())
                .foregroundColor(.white)
        }
        .frame(width: 80, height: 55) // Height matches row height
        .background(Color.black) // Ensure no transparency gap
        .border(Color.white.opacity(0.1), width: 0.5)
    }
}

struct FixtureCellView: View {
    let fixture: FixtureDisplay
    @Binding var selectedFixture: FixtureDisplay?

    var body: some View {
        Button(action: {
            selectedFixture = fixture
        }) {
            VStack(spacing: 0) {
                Text(fixture.opponentShortName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textColor(for: Theme.color(for: fixture.difficulty)))

                Text(fixture.isHome ? "(H)" : "(A)")
                    .font(.system(size: 8))
                    .foregroundColor(Theme.textColor(for: Theme.color(for: fixture.difficulty)).opacity(0.8))
            }
            .frame(width: 55, height: 55)
            .background(Theme.color(for: fixture.difficulty))
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BlankGameweekCell: View {
    var body: some View {
        Color.clear
            .frame(width: 55, height: 55)
            .border(Color.white.opacity(0.05), width: 0.5)
    }
}

// MARK: - Synced Grid Components

import Combine

class ScrollSyncManager: ObservableObject {
    @Published var offset: CGFloat = 0
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct SyncedHeaderView: View {
    let gameweeks: [Int]
    @ObservedObject var scrollManager: ScrollSyncManager

    var body: some View {
        HStack(spacing: 0) {
            // Left Header (Team)
            Text("Team")
                .font(.caption.bold())
                .frame(width: 80, height: 40)
                .background(Color.black)
                .border(Color.white.opacity(0.1), width: 0.5)
                .zIndex(1)

            // Right Header (Scrollable via Offset)
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(gameweeks, id: \.self) { gw in
                        Text("GW\(gw)")
                            .font(.caption.bold())
                            .frame(width: 55, height: 40)
                            .background(Color(white: 0.1))
                            .border(Color.white.opacity(0.1), width: 0.5)
                    }
                }
                .offset(x: scrollManager.offset) // Offset is usually negative from ScrollView
            }
            .frame(height: 40)
            .background(Color.black)
            .clipped()
        }
    }
}

struct SyncedRowView: View {
    let row: GridRow
    @Binding var selectedFixture: FixtureDisplay?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<row.fixtures.count, id: \.self) { i in
                let fixtures = row.fixtures[i]
                if fixtures.isEmpty {
                    BlankGameweekCell()
                } else {
                    // Show first fixture
                    FixtureCellView(fixture: fixtures[0], selectedFixture: $selectedFixture)
                }
            }
        }
    }
}

// Container for the Right Grid that handles horizontal scrolling
struct RightGridScrollView: View {
    let rows: [GridRow]
    @ObservedObject var scrollManager: ScrollSyncManager
    @Binding var selectedFixture: FixtureDisplay?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(rows) { row in
                    SyncedRowView(row: row, selectedFixture: $selectedFixture)
                }
            }
            .background(GeometryReader { geo in
                Color.clear
                    .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scrollSpace")).minX)
            })
        }
        .coordinateSpace(name: "scrollSpace")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollManager.offset = value
        }
    }
}

struct SyncedGridBodyView: View {
    let rows: [GridRow]
    @ObservedObject var scrollManager: ScrollSyncManager
    @Binding var selectedFixture: FixtureDisplay?

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left Column (Sticky Teams)
            LazyVStack(spacing: 0) {
                ForEach(rows) { row in
                    TeamLeftCellView(team: row.team, averageFDR: row.averageFDR)
                }
            }
            .frame(width: 80)
            .zIndex(1) // Keep on top of right grid if needed (though HStack handles layout)

            // Right Grid (Scrollable)
            RightGridScrollView(rows: rows, scrollManager: scrollManager, selectedFixture: $selectedFixture)
        }
    }
}
