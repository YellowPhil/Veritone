//
//  VeritoneApp.swift
//  Veritone
//
//  Created by Михаил Давыдов on 19.03.2026.
//

import SwiftUI

@main
struct VeritoneApp: App {
    @AppStorage(AppTheme.storageKey) private var selectedThemeRawValue = AppTheme.obsidian.rawValue
    @State private var transcriptionViewModel = TranscriptionViewModel()

    private var selectedTheme: AppTheme {
        AppTheme.resolve(from: selectedThemeRawValue)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: transcriptionViewModel)
                .preferredColorScheme(selectedTheme.colorScheme)
        }

        Settings {
            SettingsView(viewModel: transcriptionViewModel)
                .preferredColorScheme(selectedTheme.colorScheme)
        }
    }
}
