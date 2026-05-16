import Foundation
import LocalAuthentication

@Observable
@MainActor
final class BiometricService {

    // MARK: - Persistent preference

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "biometricEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "biometricEnabled") }
    }

    // MARK: - State

    private(set) var isLocked        = false
    private(set) var biometricType: LABiometryType = .none
    private(set) var authError: String?

    // MARK: - Init

    init() {
        refreshBiometricType()
    }

    // MARK: - Computed helpers

    var isAvailable: Bool { biometricType != .none }

    var biometricLabel: String {
        switch biometricType {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        default:       return "Biometrics"
        }
    }

    var biometricIcon: String {
        switch biometricType {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        default:       return "lock.fill"
        }
    }

    // MARK: - Actions

    /// Refreshes which biometry type (Face ID / Touch ID / none) is available.
    func refreshBiometricType() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }

    /// Locks the app. No-op if biometrics are disabled or unavailable.
    func lock() {
        guard isEnabled && isAvailable else { return }
        authError = nil
        isLocked  = true
    }

    /// Presents the biometric prompt. Unlocks on success; sets authError on failure.
    func authenticate() async {
        authError = nil
        let context = LAContext()
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock TipSlip"
            )
            if success { isLocked = false }
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .systemCancel, .appCancel:
                // User dismissed — stay locked silently
                break
            case .biometryNotEnrolled:
                authError = "No biometrics enrolled on this device."
            case .biometryLockout:
                authError = "Too many failed attempts. Use your passcode to unlock."
            default:
                authError = "Authentication failed. Try again."
            }
        } catch {
            authError = "Authentication failed. Try again."
        }
    }
}
