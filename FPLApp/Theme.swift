import SwiftUI

struct Theme {
    static let deepGreen = Color(red: 0.0, green: 0.4, blue: 0.1)
    static let lightGreen = Color(red: 0.2, green: 0.8, blue: 0.3)
    static let gray = Color(white: 0.8)
    static let yellow = Color(red: 1.0, green: 0.9, blue: 0.2)
    static let orange = Color.orange
    static let red = Color.red
    static let darkRed = Color(red: 0.5, green: 0.0, blue: 0.0)

    static func color(for difficulty: Int) -> Color {
        switch difficulty {
        case 1: return deepGreen
        case 2: return lightGreen
        case 3: return gray
        case 4: return yellow
        case 5: return orange
        case 6: return red
        case 7: return darkRed
        default: return gray
        }
    }

    static func textColor(for backgroundColor: Color) -> Color {
        switch backgroundColor {
        case deepGreen, red, darkRed:
            return .white
        default:
            return .black
        }
    }
}
