import Foundation
import LocalAuthentication

/// Manages biometric authentication for secure wallet access
class BiometricManager {
    
    // MARK: - Types
    
    enum BiometricType {
        case none
        case touchID
        case faceID
        case opticID
        
        var displayName: String {
            switch self {
            case .none:
                return "None"
            case .touchID:
                return "Touch ID"
            case .faceID:
                return "Face ID"
            case .opticID:
                return "Optic ID"
            }
        }
    }
    
    enum BiometricError: Error {
        case notAvailable
        case notEnrolled
        case authenticationFailed
        case userCancel
        case userFallback
        case systemCancel
        case passcodeNotSet
        case biometryNotAvailable
        case biometryNotEnrolled
        case biometryLockout
        case invalidContext
        case notInteractive
        case unknown(Error)
        
        var localizedDescription: String {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device"
            case .notEnrolled:
                return "No biometric data is enrolled on this device"
            case .authenticationFailed:
                return "Biometric authentication failed"
            case .userCancel:
                return "Authentication was cancelled by the user"
            case .userFallback:
                return "User chose to use fallback authentication"
            case .systemCancel:
                return "Authentication was cancelled by the system"
            case .passcodeNotSet:
                return "Device passcode is not set"
            case .biometryNotAvailable:
                return "Biometric authentication is not available"
            case .biometryNotEnrolled:
                return "No biometric data is enrolled"
            case .biometryLockout:
                return "Biometric authentication is locked out"
            case .invalidContext:
                return "Invalid authentication context"
            case .notInteractive:
                return "Authentication is not interactive"
            case .unknown(let error):
                return "Unknown error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Singleton
    
    static let shared = BiometricManager()
    private init() {}
    
    // MARK: - Properties
    
    private let context = LAContext()
    
    // MARK: - Public Methods
    
    /// Checks if biometric authentication is available on the device
    /// - Returns: The type of biometric authentication available
    func availableBiometricType() -> BiometricType {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }
    
    /// Checks if biometric authentication is available and enrolled
    /// - Returns: true if biometrics can be used, false otherwise
    func isBiometricAvailable() -> Bool {
        return availableBiometricType() != .none
    }
    
    /// Authenticates the user using biometrics or device passcode as fallback
    /// - Parameters:
    ///   - reason: The reason for authentication to display to the user
    ///   - completion: Completion handler with success/failure result
    func authenticateUser(reason: String, completion: @escaping (Result<Void, BiometricError>) -> Void) {
        // Create a fresh context for each authentication attempt
        let authContext = LAContext()

        // First try biometric authentication if available
        var error: NSError?
        if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Configure the context for biometric auth
            authContext.localizedFallbackTitle = "Use Passcode"
            authContext.localizedCancelTitle = "Cancel"

            // Perform biometric authentication
            authContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(()))
                    } else if let error = error {
                        completion(.failure(self.mapLAError(error)))
                    } else {
                        completion(.failure(.authenticationFailed))
                    }
                }
            }
        } else {
            // Fallback to device passcode authentication if biometrics not available/enrolled
            if authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                authContext.localizedCancelTitle = "Cancel"

                // Use device passcode authentication
                authContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            completion(.success(()))
                        } else if let error = error {
                            completion(.failure(self.mapLAError(error)))
                        } else {
                            completion(.failure(.authenticationFailed))
                        }
                    }
                }
            } else {
                // Neither biometric nor passcode authentication is available
                DispatchQueue.main.async {
                    if let laError = error {
                        completion(.failure(self.mapLAError(laError)))
                    } else {
                        completion(.failure(.notAvailable))
                    }
                }
            }
        }
    }
    
    /// Authenticates the user and retrieves the mnemonic from keychain
    /// - Parameters:
    ///   - reason: The reason for authentication to display to the user
    ///   - completion: Completion handler with mnemonic or error
    func authenticateAndRetrieveMnemonic(reason: String, completion: @escaping (Result<String, Error>) -> Void) {
        authenticateUser(reason: reason) { result in
            switch result {
            case .success:
                // Authentication successful, retrieve mnemonic
                do {
                    let mnemonic = try KeychainManager.shared.retrieveMnemonic()
                    completion(.success(mnemonic))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Authenticates the user and stores a mnemonic in keychain
    /// - Parameters:
    ///   - mnemonic: The mnemonic to store
    ///   - reason: The reason for authentication to display to the user
    ///   - completion: Completion handler with success/failure result
    func authenticateAndStoreMnemonic(_ mnemonic: String, reason: String, completion: @escaping (Result<Void, Error>) -> Void) {
        authenticateUser(reason: reason) { result in
            switch result {
            case .success:
                // Authentication successful, store mnemonic
                do {
                    try KeychainManager.shared.storeOrUpdateMnemonic(mnemonic)
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Checks if biometric authentication has changed (e.g., new fingerprint added)
    /// - Returns: true if biometric data has changed since last evaluation
    func hasBiometricDataChanged() -> Bool {
        let context = LAContext()
        var error: NSError?

        // Check if biometrics are available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        // For iOS 18+, we'll use a simpler approach since evaluatedPolicyDomainState is deprecated
        // We'll track biometric availability and type changes instead
        let currentBiometricType = context.biometryType
        let storedBiometricTypeKey = "StoredBiometricType"
        let storedBiometricType = UserDefaults.standard.string(forKey: storedBiometricTypeKey)

        let currentTypeString = biometricTypeToString(currentBiometricType)

        // If stored type is different from current, biometrics have changed
        if let storedType = storedBiometricType, storedType != currentTypeString {
            UserDefaults.standard.set(currentTypeString, forKey: storedBiometricTypeKey)
            return true
        }

        // If no stored type, save current and return false (first time)
        if storedBiometricType == nil {
            UserDefaults.standard.set(currentTypeString, forKey: storedBiometricTypeKey)
        }

        return false
    }

    /// Converts biometric type to string for storage
    private func biometricTypeToString(_ type: LABiometryType) -> String {
        switch type {
        case .faceID:
            return "faceID"
        case .touchID:
            return "touchID"
        case .opticID:
            return "opticID"
        case .none:
            return "none"
        @unknown default:
            return "unknown"
        }
    }

    /// Updates stored biometric data after successful authentication
    func updateBiometricData() {
        let context = LAContext()
        let currentBiometricType = context.biometryType
        let currentTypeString = biometricTypeToString(currentBiometricType)
        UserDefaults.standard.set(currentTypeString, forKey: "StoredBiometricType")
    }

    /// Provides user-friendly error messages for authentication failures
    /// - Parameter error: The error to convert
    /// - Returns: User-friendly error message
    func userFriendlyErrorMessage(for error: Error) -> String {
        if let biometricError = error as? BiometricError {
            switch biometricError {
            case .notAvailable:
                return "Biometric authentication is not available on this device."
            case .notEnrolled:
                return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings."
            case .userCancel:
                return "Authentication was cancelled."
            case .userFallback:
                return "Please use your device passcode to authenticate."
            case .systemCancel:
                return "Authentication was cancelled by the system."
            case .authenticationFailed:
                return "Authentication failed. Please try again."
            case .invalidContext:
                return "Authentication context is invalid."
            case .biometryNotAvailable:
                return "Biometric authentication is temporarily unavailable."
            case .biometryLockout:
                return "Biometric authentication is locked. Please use your device passcode."
            case .passcodeNotSet:
                return "Device passcode is not set. Please set up a passcode in Settings."
            case .biometryNotEnrolled:
                return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings."
            case .notInteractive:
                return "Authentication cannot be performed in the current context."
            case .unknown(let error):
                return error.localizedDescription
            }
        }

        return error.localizedDescription
    }
    
    // MARK: - Private Methods
    
    /// Maps LocalAuthentication errors to BiometricError
    /// - Parameter error: The LAError to map
    /// - Returns: Corresponding BiometricError
    private func mapLAError(_ error: Error) -> BiometricError {
        guard let laError = error as? LAError else {
            return .unknown(error)
        }
        
        switch laError.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryLockout:
            return .biometryLockout
        case .invalidContext:
            return .invalidContext
        case .notInteractive:
            return .notInteractive
        case .touchIDNotAvailable:
            return .biometryNotAvailable
        case .touchIDNotEnrolled:
            return .biometryNotEnrolled
        case .touchIDLockout:
            return .biometryLockout
        case .appCancel:
            return .systemCancel
        @unknown default:
            return .unknown(error)
        }
    }
}

// MARK: - Convenience Methods

extension BiometricManager {
    
    /// Quick check if the user can authenticate with biometrics or device passcode
    /// - Returns: true if authentication is possible, false otherwise
    func canAuthenticate() -> Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ||
               context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
    
    /// Gets a user-friendly description of the available authentication methods
    /// - Returns: Description string for UI display
    func biometricTypeDescription() -> String {
        let type = availableBiometricType()
        let context = LAContext()
        let hasPasscode = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)

        switch type {
        case .none:
            if hasPasscode {
                return "Device passcode authentication is available"
            } else {
                return "No authentication method is available"
            }
        case .touchID:
            return "Touch ID is available (with passcode fallback)"
        case .faceID:
            return "Face ID is available (with passcode fallback)"
        case .opticID:
            return "Optic ID is available (with passcode fallback)"
        }
    }
}
