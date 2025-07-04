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

        // Check if biometric data has changed
        if BiometricManager.shared.hasBiometricDataChanged() {
            // Biometric enrollment changed, require re-authentication
            requiresAuthentication = true
            SecureSeedCache.shared.clearCache()
            print("🔒 Biometric data changed - requiring re-authentication")
            backgroundTime = nil
            return
        }

        // Check if we need to re-authenticate based on background time
        if let backgroundTime = backgroundTime {
            let timeInBackground = Date().timeIntervalSince(backgroundTime)

            if timeInBackground > backgroundTimeout {
                // App was in background too long, require authentication
                requiresAuthentication = true
                print("🔒 App was backgrounded for \(timeInBackground)s - requiring authentication")
            } else {
                // Quick return, try to initialize from cache
                let cacheSuccess = await walletManager.initializeWalletFromCache()
                if !cacheSuccess {
                    requiresAuthentication = true
                }
            }
        } else {
            // First launch or no background time recorded
            let cacheSuccess = await walletManager.initializeWalletFromCache()
            if !cacheSuccess {
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
        
        print("📱 App entered background - wallet disconnected, cache preserved")
    }
    
    /// Handles app becoming inactive (e.g., control center, phone call)
    func handleAppWillResignActive() {
        isAppActive = false
        // Don't disconnect for brief interruptions
        print("📱 App will resign active - keeping connection")
    }
    
    /// Handles successful authentication
    func handleAuthenticationSuccess() {
        requiresAuthentication = false

        // Update biometric data after successful authentication
        BiometricManager.shared.updateBiometricData()

        // Initialize wallet after successful authentication
        Task {
            await walletManager.initializeWallet()
        }
    }
    
    /// Handles authentication failure or cancellation
    func handleAuthenticationFailure() {
        // Clear cache and require fresh authentication
        SecureSeedCache.shared.clearCache()
        
        Task {
            await walletManager.logout()
        }
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
        // Clear cache on app termination
        SecureSeedCache.shared.clearCache()
        
        Task {
            await walletManager.disconnect()
        }
        
        print("🛑 App terminating - cache cleared, wallet disconnected")
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
        
        biometricManager.authenticateUser(reason: "Authenticate to access your Lumen wallet") { result in
            DispatchQueue.main.async {
                isAuthenticating = false
                
                switch result {
                case .success:
                    lifecycleManager.handleAuthenticationSuccess()
                case .failure(let error):
                    authError = biometricManager.userFriendlyErrorMessage(for: error)

                    // If user cancels or fails multiple times, handle appropriately
                    if let biometricError = error as? BiometricManager.BiometricError,
                       case .userCancel = biometricError {
                        lifecycleManager.handleAuthenticationFailure()
                    }
                }
            }
        }
    }
}
