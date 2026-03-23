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
    @State private var permissionManager = PermissionManager()
    @State private var showPermissionPrompt = false

    private var selectedTheme: AppTheme {
        AppTheme.resolve(from: selectedThemeRawValue)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: transcriptionViewModel)
                .preferredColorScheme(selectedTheme.colorScheme)
                .sheet(isPresented: $showPermissionPrompt) {
                    PermissionPromptView(permissionManager: permissionManager) {
                        showPermissionPrompt = false
                    }
                }
                .task {
                    permissionManager.checkPermissions()
                    showPermissionPrompt = permissionManager.needsPermissions
                }
        }

        Settings {
            SettingsView(viewModel: transcriptionViewModel)
                .preferredColorScheme(selectedTheme.colorScheme)
        }
    }
}
