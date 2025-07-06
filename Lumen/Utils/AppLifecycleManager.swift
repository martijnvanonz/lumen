import Foundation
import UIKit
import SwiftUI

/// Manages app lifecycle events and coordinates security measures
class AppLifecycleManager: ObservableObject {

    // MARK: - Published Properties

    @Published var isAppActive = true
    @Published var requiresAuthentication = false

    // MARK: - Private Properties

    private var backgroundTime: Date?
    private let backgroundTimeout: TimeInterval = 300 // 5 minutes
    private let walletManager = WalletManager.shared

    // Authentication state tracking
    private var isAuthenticating = false
    private var lastSuccessfulAuth: Date?
    private let authGracePeriod: TimeInterval = 10 // 10 seconds grace period after successful auth
    
    // MARK: - Singleton
    
    static let shared = AppLifecycleManager()
    
    private init() {
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Handles app returning to foreground
    func handleAppDidBecomeActive() async {
        isAppActive = true

        // Check if we should skip authentication logic entirely
        if shouldSkipAuthentication() {
            backgroundTime = nil
            return
        }

        // Check if biometric data has changed
        if BiometricManager.shared.hasBiometricDataChanged() {
            // Biometric enrollment changed, require re-authentication
            requiresAuthentication = true
            SecureSeedCache.shared.clearCache()
            backgroundTime = nil
            return
        }

        // Check if we need to re-authenticate based on background time
        if let backgroundTime = backgroundTime {
            let timeInBackground = Date().timeIntervalSince(backgroundTime)

            if timeInBackground > backgroundTimeout {
                // App was in background too long, require authentication
                requiresAuthentication = true
            } else {
                // Quick return, try to initialize from cache
                let cacheSuccess = await walletManager.initializeWalletFromCache()
                if !cacheSuccess && !walletManager.isConnected {
                    requiresAuthentication = true
                }
            }
        } else {
            // First launch or no background time recorded
            let cacheSuccess = await walletManager.initializeWalletFromCache()
            if !cacheSuccess && !walletManager.isConnected {
                requiresAuthentication = true
            }
        }

        backgroundTime = nil
    }
    
    /// Handles app going to background
    func handleAppDidEnterBackground() {
        isAppActive = false
        backgroundTime = Date()
        
        // Disconnect wallet but keep cache for quick return
        Task {
            await walletManager.disconnect()
        }
    }
    
    /// Handles app becoming inactive (e.g., control center, phone call)
    func handleAppWillResignActive() {
        isAppActive = false
        // Don't disconnect for brief interruptions
    }
    
    /// Handles successful authentication
    func handleAuthenticationSuccess() {
        isAuthenticating = false
        requiresAuthentication = false
        lastSuccessfulAuth = Date()

        // Update biometric data after successful authentication
        BiometricManager.shared.updateBiometricData()

        // Pre-cache the mnemonic to avoid second Face ID prompt
        Task {
            do {
                // Use direct keychain access since user already authenticated
                let mnemonic = try KeychainManager.shared.retrieveMnemonic()
                SecureSeedCache.shared.storeSeed(mnemonic)

                // Now initialize wallet with cached mnemonic
                await walletManager.initializeWallet()
            } catch {
                // Fallback to normal initialization
                await walletManager.initializeWallet()
            }
        }
    }

    /// Handles authentication failure or cancellation
    func handleAuthenticationFailure() {
        isAuthenticating = false

        // Clear cache and require fresh authentication
        SecureSeedCache.shared.clearCache()

        Task {
            await walletManager.logout()
        }
    }

    /// Called when authentication starts
    func handleAuthenticationStart() {
        isAuthenticating = true
    }

    /// Checks if authentication should be skipped based on current state
    private func shouldSkipAuthentication() -> Bool {
        // Skip if already authenticating
        if isAuthenticating {
            return true
        }

        // Skip if wallet is already connected and logged in
        if walletManager.isConnected && walletManager.isLoggedIn {
            return true
        }

        // Skip if we recently authenticated successfully (grace period)
        if let lastAuth = lastSuccessfulAuth {
            let timeSinceAuth = Date().timeIntervalSince(lastAuth)
            if timeSinceAuth < authGracePeriod {
                return true
            }
        }

        return false
    }

    /// Resets authentication state (called on logout)
    func resetAuthenticationState() {
        isAuthenticating = false
        lastSuccessfulAuth = nil
        requiresAuthentication = false
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthenticationStateResetNotification),
            name: .authenticationStateReset,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        Task {
            await handleAppDidBecomeActive()
        }
    }
    
    @objc private func appDidEnterBackground() {
        handleAppDidEnterBackground()
    }
    
    @objc private func appWillResignActive() {
        handleAppWillResignActive()
    }
    
    @objc private func appWillTerminate() {
        // Disconnect wallet but preserve cache for next app launch
        // Cache will only be cleared on explicit logout or security violations
        Task {
            await walletManager.disconnect()
        }
    }

    @objc private func handleAuthenticationStateResetNotification() {
        resetAuthenticationState()
    }
}

// MARK: - Authentication View

struct AuthenticationRequiredView: View {
    @ObservedObject private var lifecycleManager = AppLifecycleManager.shared
    private let biometricManager = BiometricManager.shared
    @State private var isAuthenticating = false
    @State private var authError: String?
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon or Logo
            Image(systemName: "lock.shield")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            VStack(spacing: 16) {
                Text("Authentication Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Please authenticate to access your wallet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                // Authenticate Button
                Button(action: {
                    authenticateUser()
                }) {
                    HStack {
                        if isAuthenticating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: biometricManager.availableBiometricType() == .faceID ? "faceid" : "touchid")
                        }
                        
                        Text(isAuthenticating ? "Authenticating..." : "Authenticate")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(12)
                }
                .disabled(isAuthenticating)
                
                // Error message
                if let error = authError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .padding()
    }
    
    private func authenticateUser() {
        isAuthenticating = true
        authError = nil

        // Notify lifecycle manager that authentication started
        lifecycleManager.handleAuthenticationStart()

        biometricManager.authenticateUser(reason: "Authenticate to access your Lumen wallet") { result in
            DispatchQueue.main.async {
                isAuthenticating = false

                switch result {
                case .success:
                    lifecycleManager.handleAuthenticationSuccess()
                case .failure(let error):
                    authError = biometricManager.userFriendlyErrorMessage(for: error)

                    // Only handle failure for serious errors, not user cancellation
                    if let biometricError = error as? BiometricManager.BiometricError {
                        switch biometricError {
                        case .notAvailable, .notEnrolled, .biometryNotAvailable, .biometryNotEnrolled, .biometryLockout:
                            // Serious biometric issues - handle as failure
                            lifecycleManager.handleAuthenticationFailure()
                        case .userCancel, .authenticationFailed, .systemCancel, .userFallback, .passcodeNotSet, .invalidContext, .notInteractive:
                            // User cancelled or failed - don't logout, just show error
                            break
                        case .unknown(_):
                            // Unknown error - don't logout, just show error
                            break
                        }
                    }
                }
            }
        }
    }
}
