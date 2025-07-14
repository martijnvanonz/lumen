import Foundation

extension Notification.Name {
    /// Posted when the user logs out of the wallet
    static let walletLoggedOut = Notification.Name("walletLoggedOut")

    // Note: onboardingCompleted is defined in OnboardingFlowView.swift

    /// Posted when biometric data has changed (e.g., new fingerprint enrolled)
    static let biometricDataChanged = Notification.Name("biometricDataChanged")

    /// Posted when authentication is required
    static let authenticationRequired = Notification.Name("authenticationRequired")

    /// Posted when authentication state should be reset
    static let authenticationStateReset = Notification.Name("authenticationStateReset")
}
