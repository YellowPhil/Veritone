import SwiftUI

struct ContentView: View {
    @AppStorage(AppTheme.storageKey) private var selectedThemeRawValue = AppTheme.obsidian.rawValue
    @Bindable var viewModel: TranscriptionViewModel
    @State private var recordingPulse = false

    var body: some View {
        ZStack {
            palette.background
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
        .onAppear {
            if viewModel.uiState == .recording {
                withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                    recordingPulse = true
                }
            }
        }
        .onChange(of: viewModel.uiState) { _, state in
            if state == .recording {
                withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                    recordingPulse = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    recordingPulse = false
                }
            }
        }
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

                if case .success(let text) = viewModel.uiState, !text.isEmpty {
                    transcriptPreview(text)
                }
            }

            SettingsLink {
                Label("Open Settings", systemImage: "gearshape.2")
            }
            .buttonStyle(ChromeButtonStyle(palette: palette, variant: .primary))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
        .overlay(panelBorder)
        .shadow(color: palette.shadow, radius: 10, y: 6)
    }

    private var statusSymbol: some View {
        ZStack {
            if viewModel.uiState == .recording {
                Circle()
                    .fill(statusColor.opacity(0.10))
                    .frame(width: 54, height: 54)
                    .scaleEffect(recordingPulse ? 1.4 : 1.0)
                    .opacity(recordingPulse ? 0 : 0.7)
            }

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

    private func transcriptPreview(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TRANSCRIPT")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.55)
                .foregroundStyle(palette.secondaryText)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(palette.primaryText)
                .lineLimit(3)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
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
            return "Processing"
        case .success:
            return "Complete"
        case .failure:
            return "Error"
        }
    }

    private var statusHeadline: String {
        switch viewModel.uiState {
        case .idle:
            return viewModel.currentAvailability.isReady ? "Ready to capture" : "Configuration required"
        case .recording:
            return "Listening..."
        case .transcribing:
            return "Processing audio"
        case .success:
            return "Transcript ready"
        case .failure:
            return "Something went wrong"
        }
    }

    private var statusSubtitle: String {
        switch viewModel.uiState {
        case .idle:
            return viewModel.currentAvailability.isReady
                ? "Use your shortcut to begin recording. Open Settings whenever you need to adjust preferences or run a manual test."
                : "Open Settings to finish provider setup before you start."
        case .recording:
            return "Speak clearly into your microphone."
        case .transcribing:
            return "Your audio is being processed, hang tight."
        case .success:
            return "Your transcript is ready. Check the clipboard or focused input."
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
            return AnyShapeStyle(palette.accent)
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
