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
