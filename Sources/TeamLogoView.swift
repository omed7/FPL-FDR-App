import SwiftUI
import UIKit

struct TeamLogoView: View {
    let teamShortName: String

    var body: some View {
        // Attempt to load image from bundle (if added to Assets)
        // Since we cannot verify assets here, we use a fallback logic that looks for UIImage
        // In a real app, this would use Image("name")
        if let image = UIImage(named: teamShortName.lowercased()) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else {
            // Fallback
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                Text(teamShortName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(width: 40, height: 40)
        }
    }
}
