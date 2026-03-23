import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    static let storageKey = "app_theme"

    case obsidian
    case ivory

    var id: String { rawValue }

    static func resolve(from rawValue: String) -> AppTheme {
        AppTheme(rawValue: rawValue) ?? .obsidian
    }

    var displayName: String {
        switch self {
        case .obsidian:
            return "Obsidian"
        case .ivory:
            return "Ivory"
        }
    }

    var marketingName: String {
        switch self {
        case .obsidian:
            return "Nocturne"
        case .ivory:
            return "Lumen"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .obsidian:
            return .dark
        case .ivory:
            return .light
        }
    }

    var palette: ThemePalette {
        switch self {
        case .obsidian:
            return ThemePalette(
                background: Color(red: 0.07, green: 0.09, blue: 0.09),
                accent: Color(red: 0.42, green: 0.76, blue: 0.70),
                primaryText: Color.white.opacity(0.96),
                secondaryText: Color.white.opacity(0.64),
                cardBackground: Color.white.opacity(0.055),
                elevatedCardBackground: Color.white.opacity(0.085),
                controlBackground: Color.white.opacity(0.065),
                border: Color.white.opacity(0.10),
                success: Color(red: 0.33, green: 0.89, blue: 0.63),
                warning: Color(red: 1.00, green: 0.69, blue: 0.31),
                danger: Color(red: 1.00, green: 0.44, blue: 0.48),
                shadow: Color.black.opacity(0.24),
                ambientGlow: Color(red: 0.36, green: 0.66, blue: 0.60).opacity(0.18)
            )
        case .ivory:
            return ThemePalette(
                background: Color(red: 0.97, green: 0.99, blue: 0.98),
                accent: Color(red: 0.28, green: 0.58, blue: 0.52),
                primaryText: Color(red: 0.10, green: 0.13, blue: 0.12),
                secondaryText: Color(red: 0.33, green: 0.40, blue: 0.38),
                cardBackground: Color.white.opacity(0.72),
                elevatedCardBackground: Color.white.opacity(0.84),
                controlBackground: Color.white.opacity(0.88),
                border: Color(red: 0.76, green: 0.85, blue: 0.83),
                success: Color(red: 0.09, green: 0.60, blue: 0.45),
                warning: Color(red: 0.84, green: 0.48, blue: 0.12),
                danger: Color(red: 0.88, green: 0.24, blue: 0.24),
                shadow: Color.black.opacity(0.07),
                ambientGlow: Color(red: 0.36, green: 0.66, blue: 0.60).opacity(0.10)
            )
        }
    }
}

struct ThemePalette {
    let background: Color
    let accent: Color
    let primaryText: Color
    let secondaryText: Color
    let cardBackground: Color
    let elevatedCardBackground: Color
    let controlBackground: Color
    let border: Color
    let success: Color
    let warning: Color
    let danger: Color
    let shadow: Color
    let ambientGlow: Color
}
