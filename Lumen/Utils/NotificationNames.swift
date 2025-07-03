import Foundation

extension Notification.Name {
    /// Posted when the user logs out of the wallet
    static let walletLoggedOut = Notification.Name("walletLoggedOut")

    /// Posted when onboarding is completed
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}
