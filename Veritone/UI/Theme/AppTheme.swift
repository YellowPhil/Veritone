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
                backgroundTop: Color(red: 0.06, green: 0.08, blue: 0.14),
                backgroundBottom: Color(red: 0.02, green: 0.03, blue: 0.07),
                accent: Color(red: 0.37, green: 0.69, blue: 1.00),
                accentSecondary: Color(red: 0.56, green: 0.35, blue: 1.00),
                primaryText: Color.white.opacity(0.96),
                secondaryText: Color.white.opacity(0.64),
                cardBackground: Color.white.opacity(0.055),
                elevatedCardBackground: Color.white.opacity(0.085),
                controlBackground: Color.white.opacity(0.065),
                transcriptBackground: Color.white.opacity(0.045),
                border: Color.white.opacity(0.10),
                success: Color(red: 0.33, green: 0.89, blue: 0.63),
                warning: Color(red: 1.00, green: 0.69, blue: 0.31),
                danger: Color(red: 1.00, green: 0.44, blue: 0.48),
                shadow: Color.black.opacity(0.24),
                ambientGlow: Color(red: 0.31, green: 0.66, blue: 1.00).opacity(0.16)
            )
        case .ivory:
            return ThemePalette(
                backgroundTop: Color(red: 0.98, green: 0.99, blue: 1.00),
                backgroundBottom: Color(red: 0.91, green: 0.94, blue: 0.98),
                accent: Color(red: 0.13, green: 0.44, blue: 0.98),
                accentSecondary: Color(red: 0.48, green: 0.31, blue: 0.95),
                primaryText: Color(red: 0.10, green: 0.13, blue: 0.20),
                secondaryText: Color(red: 0.33, green: 0.38, blue: 0.49),
                cardBackground: Color.white.opacity(0.72),
                elevatedCardBackground: Color.white.opacity(0.84),
                controlBackground: Color.white.opacity(0.88),
                transcriptBackground: Color.white.opacity(0.68),
                border: Color.white.opacity(0.62),
                success: Color(red: 0.09, green: 0.66, blue: 0.43),
                warning: Color(red: 0.84, green: 0.48, blue: 0.12),
                danger: Color(red: 0.88, green: 0.24, blue: 0.24),
                shadow: Color.black.opacity(0.07),
                ambientGlow: Color(red: 0.31, green: 0.66, blue: 1.00).opacity(0.08)
            )
        }
    }
}

struct ThemePalette {
    let backgroundTop: Color
    let backgroundBottom: Color
    let accent: Color
    let accentSecondary: Color
    let primaryText: Color
    let secondaryText: Color
    let cardBackground: Color
    let elevatedCardBackground: Color
    let controlBackground: Color
    let transcriptBackground: Color
    let border: Color
    let success: Color
    let warning: Color
    let danger: Color
    let shadow: Color
    let ambientGlow: Color

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentSecondary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
