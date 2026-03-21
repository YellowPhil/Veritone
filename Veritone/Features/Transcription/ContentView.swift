import SwiftUI

struct ContentView: View {
    @AppStorage(AppTheme.storageKey) private var selectedThemeRawValue = AppTheme.obsidian.rawValue
    @Bindable var viewModel: TranscriptionViewModel

    var body: some View {
        ZStack {
            palette.backgroundGradient
                .ignoresSafeArea()

            LinearGradient(
                colors: [palette.ambientGlow.opacity(0.18), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                topBar
                Spacer(minLength: 0)
                primaryPanel
                Spacer(minLength: 0)
            }
            .padding(14)
        }
        .frame(minWidth: 460, minHeight: 340)
        .tint(palette.accent)
    }

    private var selectedTheme: AppTheme {
        AppTheme.resolve(from: selectedThemeRawValue)
    }

    private var palette: ThemePalette {
        selectedTheme.palette
    }

    private var topBar: some View {
        HStack {
            Text("Veritone")
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.18)
                .foregroundStyle(palette.primaryText)

            Spacer()

            SettingsLink {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(ChromeButtonStyle(palette: palette, variant: .secondary))
        }
        .padding(.horizontal, 2)
    }

    private var primaryPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                statusSymbol

                VStack(alignment: .leading, spacing: 3) {
                    Text(stateTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(statusColor)

                    Text(statusHeadline)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(palette.primaryText)
                }

                Spacer(minLength: 0)
            }

            Text(statusSubtitle)
                .font(.callout)
                .foregroundStyle(palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                statusLine(title: "Status", value: viewModel.statusMessage, tone: statusDetailColor)

                if shouldShowSetupNote {
                    statusLine(title: "Setup", value: viewModel.providerDetailText, tone: providerTone)
                }
            }

            HStack {
                SettingsLink {
                    Label("Open Settings", systemImage: "gearshape.2")
                }
                .buttonStyle(ChromeButtonStyle(palette: palette, variant: .primary))

                Spacer(minLength: 0)

                Text("Testing tools live in Settings.")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryText)
            }
        }
        .padding(18)
        .frame(maxWidth: 320, alignment: .leading)
        .background(panelBackground)
        .overlay(panelBorder)
        .shadow(color: palette.shadow, radius: 10, y: 6)
    }

    private var statusSymbol: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.14))
                .frame(width: 38, height: 38)

            Image(systemName: stateSymbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(statusColor)
        }
    }

    private func statusLine(title: String, value: String, tone: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.55)
                .foregroundStyle(palette.secondaryText)

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(tone)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(controlPlate)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(palette.cardBackground)
    }

    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(palette.border, lineWidth: 1)
    }

    private var controlPlate: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(palette.controlBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
    }

    private var statusColor: Color {
        switch viewModel.uiState {
        case .failure:
            return palette.danger
        case .recording, .transcribing:
            return palette.accent
        case .success:
            return palette.success
        case .idle:
            return palette.primaryText
        }
    }

    private var statusDetailColor: Color {
        switch viewModel.uiState {
        case .failure:
            return palette.danger
        case .idle:
            switch viewModel.currentAvailability {
            case .available:
                return palette.secondaryText
            case .requiresAPIKey, .requiresLocalModel:
                return palette.warning
            case .unavailable:
                return palette.danger
            }
        case .recording, .transcribing:
            return palette.accent
        case .success:
            return palette.success
        }
    }

    private var providerTone: Color {
        switch viewModel.currentAvailability {
        case .available:
            return palette.secondaryText
        case .requiresAPIKey, .requiresLocalModel:
            return palette.warning
        case .unavailable:
            return palette.danger
        }
    }

    private var stateTitle: String {
        switch viewModel.uiState {
        case .idle:
            return viewModel.currentAvailability.isReady ? "Ready" : "Setup Needed"
        case .recording:
            return "Recording"
        case .transcribing:
            return "Transcribing"
        case .success:
            return "Complete"
        case .failure:
            return "Attention Needed"
        }
    }

    private var statusHeadline: String {
        switch viewModel.uiState {
        case .idle:
            return viewModel.currentAvailability.isReady ? "Ready to capture" : "Configuration required"
        case .recording:
            return "Recording"
        case .transcribing:
            return "Transcribing"
        case .success:
            return "Completed"
        case .failure:
            return "Needs attention"
        }
    }

    private var statusSubtitle: String {
        switch viewModel.uiState {
        case .idle:
            return viewModel.currentAvailability.isReady
                ? "Use your shortcut to begin recording. Open Settings whenever you need to adjust preferences or run a manual test."
                : "Open Settings to finish provider setup before you start."
        case .recording:
            return "Recording is active now."
        case .transcribing:
            return "Your audio is being transcribed now."
        case .success:
            return "The latest transcript finished successfully."
        case .failure:
            return "Review the status message below and adjust the app configuration if needed."
        }
    }

    private var shouldShowSetupNote: Bool {
        if case .idle = viewModel.uiState {
            return !viewModel.currentAvailability.isReady
        }

        return false
    }

    private var stateSymbolName: String {
        switch viewModel.uiState {
        case .idle:
            return viewModel.currentAvailability.isReady ? "waveform.circle.fill" : "exclamationmark.circle.fill"
        case .recording:
            return "mic.circle.fill"
        case .transcribing:
            return "waveform.badge.magnifyingglass"
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "xmark.circle.fill"
        }
    }
}

enum ChromeButtonVariant {
    case primary
    case secondary
}

struct ChromeButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let palette: ThemePalette
    let variant: ChromeButtonVariant

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.46)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .shadow(color: shadowColor, radius: 6, y: 3)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return .white
        case .secondary:
            return palette.primaryText
        }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(backgroundFill)
    }

    private var backgroundFill: AnyShapeStyle {
        switch variant {
        case .primary:
            return AnyShapeStyle(palette.accentGradient)
        case .secondary:
            return AnyShapeStyle(palette.controlBackground)
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary:
            return palette.accent.opacity(0.35)
        case .secondary:
            return palette.border
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .primary:
            return palette.ambientGlow
        case .secondary:
            return palette.shadow
        }
    }
}

#Preview {
    ContentView(viewModel: TranscriptionViewModel())
}
