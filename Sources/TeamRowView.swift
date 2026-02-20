import SwiftUI

struct TeamLeftCell: View {
    let team: Team
    let fdr: Double

    var body: some View {
        HStack(spacing: 4) {
            TeamLogoView(teamShortName: team.short_name)

            VStack(alignment: .leading, spacing: 2) {
                Text(team.short_name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)

                Text(String(format: "%.1f", fdr))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(fdrColor(fdr))
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func fdrColor(_ val: Double) -> Color {
        // Color scale for Average FDR
        // Lower is better (Green), Higher is harder (Red)
        if val < 2.5 { return Theme.deepGreen }
        else if val < 3.0 { return Theme.lightGreen }
        else if val < 4.0 { return Theme.lightGrey }
        else if val < 5.0 { return Theme.lightRed }
        else { return Theme.standardRed }
    }
}
