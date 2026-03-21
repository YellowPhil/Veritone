import AVFoundation
import SwiftUI

struct PermissionPromptView: View {
    @AppStorage(AppTheme.storageKey) private var selectedThemeRawValue = AppTheme.obsidian.rawValue
    @Bindable var permissionManager: PermissionManager
    var onDismiss: () -> Void

    private var palette: ThemePalette {
        AppTheme.resolve(from: selectedThemeRawValue).palette
    }

    var body: some View {
        ZStack {
            palette.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 32)
                    .padding(.horizontal, 28)

                Divider()
                    .background(palette.border)
                    .padding(.top, 24)

                ScrollView {
                    VStack(spacing: 16) {
                        if permissionManager.microphoneStatus != .authorized {
                            PermissionRowView(
                                palette: palette,
                                icon: "mic.fill",
                                title: "Microphone Access",
                                description: "Veritone records your voice to transcribe speech into text. Without microphone access, recording is not possible.",
                                actionLabel: permissionManager.microphoneStatus == .notDetermined
                                    ? "Enable Microphone" : "Open System Settings",
                                action: {
                                    if permissionManager.microphoneStatus == .notDetermined {
                                        Task { await permissionManager.requestMicrophonePermission() }
                                    } else {
                                        openSettings(for: .microphone)
                                    }
                                }
                            )
                        }

                        if !permissionManager.accessibilityGranted {
                            PermissionRowView(
                                palette: palette,
                                icon: "hand.point.up.left.fill",
                                title: "Accessibility Access",
                                description: "Veritone needs Accessibility access to paste transcribed text directly into the app you're using.",
                                actionLabel: "Open System Settings",
                                action: { openSettings(for: .accessibility) }
                            )
                        }
                    }
                    .padding(24)
                }

                Divider()
                    .background(palette.border)

                footer
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)
            }
        }
        .frame(width: 460)
        .frame(minHeight: 300)
        .preferredColorScheme(AppTheme.resolve(from: selectedThemeRawValue).colorScheme)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(palette.accent)

                Text("Permissions Required")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(palette.primaryText)

                Spacer()
            }

            Text("Veritone needs the following permissions to function correctly. These are only used for transcription and never shared.")
                .font(.subheadline)
                .foregroundStyle(palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Continue Anyway") {
                onDismiss()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(palette.secondaryText)
            .buttonStyle(.plain)
        }
    }

    private enum PermissionTarget {
        case microphone
        case accessibility
    }

    private func openSettings(for target: PermissionTarget) {
        let urlString: String
        switch target {
        case .microphone:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        case .accessibility:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        }
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

private struct PermissionRowView: View {
    let palette: ThemePalette
    let icon: String
    let title: String
    let description: String
    let actionLabel: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(palette.accent.opacity(0.14))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(palette.accent)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(palette.primaryText)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: action) {
                    HStack(spacing: 6) {
                        Text(actionLabel)
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(palette.accentGradient)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                )
        )
    }
}
