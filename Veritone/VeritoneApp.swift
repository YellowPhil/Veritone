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
                .onAppear {
                    permissionManager.checkPermissions()
                    showPermissionPrompt = permissionManager.needsPermissions
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    permissionManager.checkPermissions()
                    if permissionManager.needsPermissions {
                        showPermissionPrompt = true
                    } else {
                        showPermissionPrompt = false
                    }
                }
        }

        Settings {
            SettingsView(viewModel: transcriptionViewModel)
                .preferredColorScheme(selectedTheme.colorScheme)
        }
    }
}
