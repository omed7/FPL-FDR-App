import SwiftUI

struct Theme {
    static let deepGreen = Color(red: 0.0, green: 0.4, blue: 0.1)
    static let lightGreen = Color(red: 0.2, green: 0.8, blue: 0.3)
    static let lightGrey = Color(red: 0.8, green: 0.8, blue: 0.8)
    static let lightRed = Color(red: 1.0, green: 0.5, blue: 0.5)
    static let standardRed = Color(red: 0.9, green: 0.1, blue: 0.1)
    static let darkRed = Color(red: 0.6, green: 0.0, blue: 0.1)
    static let extremeDarkRed = Color(red: 0.3, green: 0.0, blue: 0.0)

    static func color(for difficulty: Int) -> Color {
        switch difficulty {
        case 1: return deepGreen
        case 2: return lightGreen
        case 3: return lightGrey
        case 4: return lightRed
        case 5: return standardRed
        case 6: return darkRed
        case 7: return extremeDarkRed
        default: return lightGrey
        }
    }

    // Helper for contrast text color
    static func contrastTextColor(for backgroundColor: Color) -> Color {
        // Simple heuristic: lighter backgrounds get black text, darker get white.
        // This maps to the theme colors above.
        switch backgroundColor {
        case lightGreen, lightGrey, lightRed:
            return .black
        default:
            return .white
        }
    }
}
