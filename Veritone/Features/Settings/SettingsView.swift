import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    private enum SettingsTab: Hashable {
        case general
        case models
        case testing
    }

    @AppStorage(AppTheme.storageKey) private var selectedThemeRawValue = AppTheme.obsidian.rawValue
    @State private var selectedTab: SettingsTab = .general
    @Bindable var viewModel: TranscriptionViewModel

    private var selectedTheme: AppTheme {
        AppTheme.resolve(from: selectedThemeRawValue)
    }

    private var selectedThemeBinding: Binding<AppTheme> {
        Binding(
            get: { selectedTheme },
            set: { selectedThemeRawValue = $0.rawValue }
        )
    }

    private var palette: ThemePalette { selectedTheme.palette }

    private var recordingShortcutModeBinding: Binding<RecordingShortcutMode> {
        Binding(
            get: { viewModel.recordingShortcutMode },
            set: { viewModel.recordingShortcutMode = $0 }
        )
    }

    private var transcriptDeliveryModeBinding: Binding<TranscriptDeliveryMode> {
        Binding(
            get: { viewModel.transcriptDeliveryMode },
            set: { viewModel.transcriptDeliveryMode = $0 }
        )
    }

    private var providerSelection: Binding<SpeechToTextProviderID> {
        Binding(
            get: { viewModel.selectedProviderID },
            set: { viewModel.selectedProviderID = $0 }
        )
    }

    private var openAIAPIKeyBinding: Binding<String> {
        Binding(
            get: { viewModel.openAIAPIKey },
            set: { viewModel.openAIAPIKey = $0 }
        )
    }

    private var localModelSelection: Binding<String> {
        Binding(
            get: { viewModel.selectedLocalModelIdentifier },
            set: { viewModel.selectedLocalModelIdentifier = $0 }
        )
    }

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    customTabBar
                    Spacer()
                }
                .padding(.top, 18)
                .padding(.horizontal, 18)
                .padding(.bottom, 10)

                Group {
                    switch selectedTab {
                    case .general:
                        generalTab
                    case .models:
                        modelsTab
                    case .testing:
                        testingTab
                    }
                }
            }
        }
        .frame(minWidth: 620, minHeight: 560)
        .onAppear {
            viewModel.refreshRecordingShortcutDisplay()
            viewModel.setShortcutHandlingEnabled(false)
        }
        .onDisappear {
            viewModel.setShortcutHandlingEnabled(true)
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 2) {
            tabBarButton(.general, title: "General", icon: "slider.horizontal.3")
            tabBarButton(.models, title: "Models", icon: "cube.transparent")
            tabBarButton(.testing, title: "Testing", icon: "waveform.and.mic")
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.controlBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                )
        )
    }

    private func tabBarButton(_ tab: SettingsTab, title: String, icon: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selectedTab == tab ? .white : palette.secondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(palette.accent)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: selectedTab)
    }

    private var generalTab: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) {
                tabHeader(
                    title: "General",
                    detail: "Appearance, shortcuts, and transcript delivery live here."
                )

                settingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Appearance", systemImage: "paintbrush.pointed")

                        HStack(spacing: 10) {
                            ForEach(AppTheme.allCases) { theme in
                                themePreview(for: theme)
                            }
                        }
                    }
                }

                settingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Recording Shortcut", systemImage: "keyboard")

                        Text("Choose how the shortcut behaves, then record the key combination you want to use.")
                            .font(.callout)
                            .foregroundStyle(palette.secondaryText)

                        Picker("Recording Mode", selection: recordingShortcutModeBinding) {
                            ForEach(RecordingShortcutMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(viewModel.recordingShortcutMode.detailText)
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)

                        KeyboardShortcuts.Recorder("Shortcut", name: .recordingShortcut) { _ in
                            viewModel.refreshRecordingShortcutDisplay()
                        }

                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(palette.secondaryText)

                                Text(viewModel.recordingShortcutSummary)
                                    .font(.headline)
                                    .foregroundStyle(palette.primaryText)
                            }

                            Spacer()

                            Button("Reset to Default") {
                                viewModel.resetRecordingShortcutToDefault()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                settingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Transcript Delivery", systemImage: "arrowshape.turn.up.right")

                        Text("Control whether finished transcripts are pasted into the focused input, copied to the clipboard, or both.")
                            .font(.callout)
                            .foregroundStyle(palette.secondaryText)

                        Picker("Transcript Delivery", selection: transcriptDeliveryModeBinding) {
                            ForEach(TranscriptDeliveryMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)

                        Text(viewModel.transcriptDeliveryMode.detailText)
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)

                        Text("Pasting into other apps requires Accessibility access. If no editable input is focused, Veritone will fall back to the clipboard.")
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)
                    }
                }
            }
            .padding(6)
        }
    }

    private var modelsTab: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) {
                tabHeader(
                    title: "Models",
                    detail: "Provider selection, model downloads, and API credentials live here."
                )

                settingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Provider", systemImage: "waveform.and.mic")

                        labeledControl(title: "Provider") {
                            Picker("Provider", selection: providerSelection) {
                                ForEach(SpeechToTextProviderID.allCases, id: \.self) { id in
                                    Text(id.displayName).tag(id)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }

                        if viewModel.showLocalModelPicker {
                            labeledControl(title: "Local Model") {
                                Picker("Local Model", selection: localModelSelection) {
                                    ForEach(viewModel.availableLocalModels, id: \.modelIdentifier) { model in
                                        Text("\(model.displayName) (\(model.approximateSizeMB) MB)")
                                            .tag(model.modelIdentifier)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                        }

                        if viewModel.showAPIKeyField {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("OpenAI API Key")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(palette.secondaryText)

                                SecureField("OpenAI API Key (or set OPENAI_API_KEY)", text: openAIAPIKeyBinding)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(palette.primaryText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(controlPlate)
                            }
                        }

                        Text(viewModel.providerDetailText)
                            .font(.subheadline)
                            .foregroundStyle(providerDetailColor)

                        if viewModel.downloader.isDownloading {
                            ProgressView()
                                .progressViewStyle(.linear)
                                .tint(palette.accent)
                        }

                        if viewModel.showDownloadButton {
                            Button {
                                viewModel.downloadModel()
                            } label: {
                                Label(
                                    "Download \(viewModel.downloadCatalogEntry.displayName)",
                                    systemImage: "arrow.down.circle.fill"
                                )
                            }
                            .buttonStyle(ChromeButtonStyle(palette: palette, variant: .secondary))
                        }
                    }
                }
            }
            .padding(6)
        }
    }

    private var testingTab: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) {
                tabHeader(
                    title: "Testing",
                    detail: "Manual recording and transcript inspection live here."
                )

                settingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Manual Controls", systemImage: "button.horizontal.top.press")

                        Text("Use these controls for direct verification without relying on the global shortcut.")
                            .font(.callout)
                            .foregroundStyle(palette.secondaryText)

                        HStack(spacing: 12) {
                            Button {
                                Task { await viewModel.requestPermissionAndRecord() }
                            } label: {
                                Label("Start Recording", systemImage: "mic.fill")
                            }
                            .buttonStyle(ChromeButtonStyle(palette: palette, variant: .primary))
                            .disabled(!viewModel.canStartRecording)

                            Button {
                                viewModel.stopRecordingAndTranscribe()
                            } label: {
                                Label("Stop & Transcribe", systemImage: "stop.fill")
                            }
                            .buttonStyle(ChromeButtonStyle(palette: palette, variant: .secondary))
                            .disabled(!viewModel.canStopRecording)
                        }

                        statusLine(title: "Status", value: viewModel.statusMessage, tone: statusLineColor)
                    }
                }

                settingsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Transcript", systemImage: "text.bubble")

                        HStack {
                            Text("Latest result")
                                .font(.callout)
                                .foregroundStyle(palette.secondaryText)

                            Spacer()

                            if viewModel.hasTranscript {
                                Button("Clear") {
                                    viewModel.clear()
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(palette.secondaryText)
                            }
                        }

                        ScrollView {
                            Text(
                                viewModel.transcript.isEmpty
                                    ? "No transcript yet. Run a manual test to inspect the latest output here."
                                    : viewModel.transcript
                            )
                            .font(.body)
                            .foregroundStyle(viewModel.transcript.isEmpty ? palette.secondaryText : palette.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(14)
                        }
                        .frame(minHeight: 220)
                        .background(controlPlate)
                    }
                }
            }
            .padding(6)
        }
    }

    private func tabHeader(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(palette.primaryText)

            Text(detail)
                .font(.callout)
                .foregroundStyle(palette.secondaryText)
        }
        .padding(.horizontal, 4)
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(palette.primaryText)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(palette.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
            .shadow(color: palette.shadow, radius: 10, y: 5)
    }

    private func labeledControl<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.secondaryText)

            content()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(controlPlate)
        }
    }

    private func statusLine(title: String, value: String, tone: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(palette.secondaryText)

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(tone)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(controlPlate)
    }

    private var controlPlate: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(palette.controlBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
    }

    private var providerDetailColor: Color {
        switch viewModel.currentAvailability {
        case .available:
            return palette.success
        case .requiresAPIKey, .requiresLocalModel:
            return palette.warning
        case .unavailable:
            return palette.danger
        }
    }

    private var statusLineColor: Color {
        switch viewModel.uiState {
        case .failure:
            return palette.danger
        case .recording, .transcribing:
            return palette.accent
        case .success:
            return palette.success
        case .idle:
            return palette.secondaryText
        }
    }

    private func themePreview(for theme: AppTheme) -> some View {
        let previewPalette = theme.palette

        return Button {
            selectedThemeBinding.wrappedValue = theme
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(previewPalette.background)
                        .frame(height: 84)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selectedTheme == theme ? previewPalette.accent : previewPalette.border, lineWidth: 1.5)
                        )

                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(previewPalette.cardBackground)
                            .frame(height: 18)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(previewPalette.accent)
                            .frame(width: 52, height: 7)
                    }
                    .padding(10)
                }

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(theme.marketingName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.primaryText)

                        Text(theme == .obsidian ? "Dark, polished, and high-contrast." : "Bright, crisp, and minimal.")
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)
                    }

                    Spacer(minLength: 8)

                    if selectedTheme == theme {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(previewPalette.accent)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(selectedTheme == theme ? palette.accent.opacity(0.8) : palette.border, lineWidth: 1)
        )
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView(viewModel: TranscriptionViewModel())
}
