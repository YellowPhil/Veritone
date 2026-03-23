import AVFoundation
import ApplicationServices

enum MicrophonePermissionStatus {
    case authorized
    case notDetermined
    case denied
}

@Observable
@MainActor
final class PermissionManager {
    private(set) var microphoneStatus: MicrophonePermissionStatus = .notDetermined
    private(set) var accessibilityGranted: Bool = false

    var needsPermissions: Bool {
        microphoneStatus != .authorized || !accessibilityGranted
    }

    func checkPermissions() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            microphoneStatus = .authorized
        case .denied:
            microphoneStatus = .denied
        case .undetermined:
            microphoneStatus = .notDetermined
        @unknown default:
            microphoneStatus = .denied
        }
        accessibilityGranted = AXIsProcessTrusted()
    }

    func requestMicrophonePermission() async {
        let granted = await AVAudioApplication.requestRecordPermission()
        microphoneStatus = granted ? .authorized : .denied
    }
}
