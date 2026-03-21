import AVFoundation
import ApplicationServices

enum MicrophonePermissionStatus {
    case authorized
    case notDetermined
    case denied
    case restricted
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
        let avStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        switch avStatus {
        case .authorized:
            microphoneStatus = .authorized
        case .denied:
            microphoneStatus = .denied
        case .restricted:
            microphoneStatus = .restricted
        case .notDetermined:
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
