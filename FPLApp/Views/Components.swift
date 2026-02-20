import SwiftUI

struct TeamLeftCellView: View {
    let team: Team
    let fdr: Double

    var body: some View {
        HStack {
            TeamLogoView(teamCode: team.code, teamShortName: team.short_name)

            VStack(alignment: .leading, spacing: 2) {
                Text(team.short_name)
                    .font(.caption.bold())
                Text(String(format: "%.1f", fdr))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(width: 80) // Fixed width for sticky column
        .background(Color.black.opacity(0.8)) // Dark background
    }
}

struct FixtureCellView: View {
    let fixture: FixtureDisplay

    var body: some View {
        VStack(spacing: 0) {
            Text(fixture.opponentShortName)
                .font(.caption.bold())
                .foregroundColor(Theme.textColor(for: Theme.color(for: fixture.difficulty)))

            Text(fixture.isHome ? "(H)" : "(A)")
                .font(.caption2)
                .foregroundColor(Theme.textColor(for: Theme.color(for: fixture.difficulty)).opacity(0.8))
        }
        .frame(width: 50, height: 40)
        .background(Theme.color(for: fixture.difficulty))
        .cornerRadius(4)
        .shadow(radius: 1)
    }
}

struct BlankGameweekCell: View {
    var body: some View {
        Text("-")
            .font(.caption.bold())
            .foregroundColor(.secondary)
            .frame(width: 50, height: 40)
            .background(Color(white: 0.15))
            .cornerRadius(4)
    }
}
