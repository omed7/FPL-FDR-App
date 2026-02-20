import SwiftUI

struct GameweekCellView: View {
    let fixtures: [FixtureDisplay]

    var body: some View {
        if fixtures.isEmpty {
            // BLANK Gameweek
            Text("-")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
                .frame(width: 60)
                .frame(maxHeight: .infinity)
                .background(Color.black.opacity(0.2))
                .cornerRadius(4)
        } else {
            VStack(spacing: 2) {
                ForEach(fixtures) { fixture in
                    SingleFixtureView(fixture: fixture)
                }
            }
            .frame(width: 60)
        }
    }
}

struct SingleFixtureView: View {
    let fixture: FixtureDisplay

    var body: some View {
        let bgColor = Theme.color(for: fixture.difficulty)
        let textColor = Theme.contrastTextColor(for: bgColor)

        VStack(spacing: 0) {
            Text(fixture.opponentShortName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(textColor)
                .lineLimit(1)

            Text(fixture.isHome ? "(H)" : "(A)")
                .font(.system(size: 10))
                .foregroundColor(textColor.opacity(0.8))
        }
        .frame(width: 60, height: 40)
        .background(bgColor)
        .cornerRadius(4)
    }
}
