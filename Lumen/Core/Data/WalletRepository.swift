import Foundation

/// Repository responsible for wallet data persistence
/// This extracts all data storage logic from WalletManager and provides
/// a clean interface for wallet state and credential management.
protocol WalletRepositoryProtocol {
    
    // MARK: - Wallet State Management
    
    /// Check if a wallet exists in storage
    var hasWallet: Bool { get set }
    
    /// Check if user is currently logged in
    var isLoggedIn: Bool { get set }
    
    /// Check if onboarding has been completed
    var hasCompletedOnboarding: Bool { get set }
    
    /// Get the last sync timestamp
    var lastSyncTimestamp: Date? { get set }
    
    /// Get app launch count
    var appLaunchCount: Int { get set }
    
    /// Get last app version
    var lastAppVersion: String? { get set }
    
    // MARK: - Mnemonic Management
    
    /// Check if mnemonic exists in secure storage
    /// - Returns: True if mnemonic is stored
    func mnemonicExists() -> Bool
    
    /// Store or update mnemonic in secure storage
    /// - Parameter mnemonic: BIP39 mnemonic phrase to store
    /// - Throws: WalletRepositoryError if storage fails
    func storeMnemonic(_ mnemonic: String) throws
    
    /// Retrieve mnemonic from secure storage
    /// - Returns: Stored mnemonic phrase
    /// - Throws: WalletRepositoryError if retrieval fails
    func retrieveMnemonic() throws -> String
    
    /// Delete mnemonic from secure storage
    /// - Throws: WalletRepositoryError if deletion fails
    func deleteMnemonic() throws
    
    // MARK: - Secure Cache Management
    
    /// Store seed in secure cache for quick access
    /// - Parameter seed: Seed phrase to cache
    /// - Throws: WalletRepositoryError if caching fails
    func cacheSeed(_ seed: String) throws
    
    /// Retrieve seed from secure cache
    /// - Returns: Cached seed phrase
    /// - Throws: WalletRepositoryError if retrieval fails
    func retrieveCachedSeed() throws -> String
    
    /// Clear seed from secure cache
    /// - Throws: WalletRepositoryError if clearing fails
    func clearCachedSeed() throws
    
    /// Check if seed is cached
    /// - Returns: True if seed is in cache
    func isSeedCached() -> Bool
    
    // MARK: - Biometric Settings
    
    /// Check if biometric authentication is enabled
    var biometricAuthEnabled: Bool { get set }
    
    /// Store biometric authentication token
    /// - Parameter token: Authentication token to store
    /// - Throws: WalletRepositoryError if storage fails
    func storeBiometricToken(_ token: String) throws
    
    /// Retrieve biometric authentication token
    /// - Returns: Stored authentication token
    /// - Throws: WalletRepositoryError if retrieval fails
    func retrieveBiometricToken() throws -> String
    
    /// Delete biometric authentication token
    /// - Throws: WalletRepositoryError if deletion fails
    func deleteBiometricToken() throws
    
    // MARK: - Wallet Reset
    
    /// Clear all wallet data and reset to initial state
    /// - Throws: WalletRepositoryError if reset fails
    func resetWalletData() throws
    
    /// Clear only session data (keep wallet but logout)
    func clearSessionData()
}

// MARK: - Repository Errors

enum WalletRepositoryError: Error, LocalizedError {
    case keychainError(String)
    case userDefaultsError(String)
    case mnemonicNotFound
    case mnemonicStorageFailed(String)
    case cacheError(String)
    case biometricTokenError(String)
    case resetFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .keychainError(let message):
            return "Keychain error: \(message)"
        case .userDefaultsError(let message):
            return "Storage error: \(message)"
        case .mnemonicNotFound:
            return "Wallet seed not found. Please restore your wallet."
        case .mnemonicStorageFailed(let message):
            return "Failed to store wallet seed: \(message)"
        case .cacheError(let message):
            return "Cache error: \(message)"
        case .biometricTokenError(let message):
            return "Biometric authentication error: \(message)"
        case .resetFailed(let message):
            return "Failed to reset wallet data: \(message)"
        }
    }
}

// MARK: - Default Implementation

class DefaultWalletRepository: WalletRepositoryProtocol {
    
    // MARK: - Dependencies
    
    private let keychainManager: KeychainManager
    private let userDefaults: UserDefaults
    private let secureSeedCache: SecureSeedCache
    
    // MARK: - Initialization
    
    init(
        keychainManager: KeychainManager = KeychainManager.shared,
        userDefaults: UserDefaults = UserDefaults.standard,
        secureSeedCache: SecureSeedCache = SecureSeedCache.shared
    ) {
        self.keychainManager = keychainManager
        self.userDefaults = userDefaults
        self.secureSeedCache = secureSeedCache
    }
    
    // MARK: - Wallet State Management
    
    var hasWallet: Bool {
        get {
            userDefaults.bool(forKey: AppConstants.UserDefaultsKeys.hasWallet)
        }
        set {
            userDefaults.set(newValue, forKey: AppConstants.UserDefaultsKeys.hasWallet)
        }
    }
    
    var isLoggedIn: Bool {
        get {
            userDefaults.bool(forKey: AppConstants.UserDefaultsKeys.isLoggedIn)
        }
        set {
            userDefaults.set(newValue, forKey: AppConstants.UserDefaultsKeys.isLoggedIn)
        }
    }
    
    var hasCompletedOnboarding: Bool {
        get {
            userDefaults.bool(forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
        }
        set {
            userDefaults.set(newValue, forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
        }
    }
    
    var lastSyncTimestamp: Date? {
        get {
            let timestamp = userDefaults.double(forKey: AppConstants.UserDefaultsKeys.lastSyncTimestamp)
            return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        }
        set {
            let timestamp = newValue?.timeIntervalSince1970 ?? 0
            userDefaults.set(timestamp, forKey: AppConstants.UserDefaultsKeys.lastSyncTimestamp)
        }
    }
    
    var appLaunchCount: Int {
        get {
            userDefaults.integer(forKey: AppConstants.UserDefaultsKeys.appLaunchCount)
        }
        set {
            userDefaults.set(newValue, forKey: AppConstants.UserDefaultsKeys.appLaunchCount)
        }
    }
    
    var lastAppVersion: String? {
        get {
            userDefaults.string(forKey: AppConstants.UserDefaultsKeys.lastAppVersion)
        }
        set {
            userDefaults.set(newValue, forKey: AppConstants.UserDefaultsKeys.lastAppVersion)
        }
    }
    
    // MARK: - Mnemonic Management
    
    func mnemonicExists() -> Bool {
        return keychainManager.mnemonicExists()
    }
    
    func storeMnemonic(_ mnemonic: String) throws {
        do {
            try keychainManager.storeOrUpdateMnemonic(mnemonic)
        } catch {
            throw WalletRepositoryError.mnemonicStorageFailed(error.localizedDescription)
        }
    }
    
    func retrieveMnemonic() throws -> String {
        do {
            return try keychainManager.retrieveMnemonic()
        } catch {
            if error.localizedDescription.contains("not found") {
                throw WalletRepositoryError.mnemonicNotFound
            } else {
                throw WalletRepositoryError.keychainError(error.localizedDescription)
            }
        }
    }
    
    func deleteMnemonic() throws {
        do {
            try keychainManager.deleteMnemonic()
        } catch {
            throw WalletRepositoryError.keychainError(error.localizedDescription)
        }
    }
    
    // MARK: - Secure Cache Management
    
    func cacheSeed(_ seed: String) throws {
        do {
            try secureSeedCache.storeSeed(seed)
        } catch {
            throw WalletRepositoryError.cacheError(error.localizedDescription)
        }
    }
    
    func retrieveCachedSeed() throws -> String {
        do {
            return try secureSeedCache.retrieveSeed()
        } catch {
            throw WalletRepositoryError.cacheError(error.localizedDescription)
        }
    }
    
    func clearCachedSeed() throws {
        do {
            try secureSeedCache.clearSeed()
        } catch {
            throw WalletRepositoryError.cacheError(error.localizedDescription)
        }
    }
    
    func isSeedCached() -> Bool {
        return secureSeedCache.isSeedCached()
    }
    
    // MARK: - Biometric Settings
    
    var biometricAuthEnabled: Bool {
        get {
            userDefaults.bool(forKey: AppConstants.UserDefaultsKeys.biometricAuthEnabled)
        }
        set {
            userDefaults.set(newValue, forKey: AppConstants.UserDefaultsKeys.biometricAuthEnabled)
        }
    }
    
    func storeBiometricToken(_ token: String) throws {
        do {
            try keychainManager.storeBiometricToken(token)
        } catch {
            throw WalletRepositoryError.biometricTokenError(error.localizedDescription)
        }
    }
    
    func retrieveBiometricToken() throws -> String {
        do {
            return try keychainManager.retrieveBiometricToken()
        } catch {
            throw WalletRepositoryError.biometricTokenError(error.localizedDescription)
        }
    }
    
    func deleteBiometricToken() throws {
        do {
            try keychainManager.deleteBiometricToken()
        } catch {
            throw WalletRepositoryError.biometricTokenError(error.localizedDescription)
        }
    }
    
    // MARK: - Wallet Reset
    
    func resetWalletData() throws {
        do {
            // Clear keychain data
            try deleteMnemonic()
            try deleteBiometricToken()
            
            // Clear secure cache
            try clearCachedSeed()
            
            // Clear UserDefaults
            clearSessionData()
            hasWallet = false
            hasCompletedOnboarding = false
            lastSyncTimestamp = nil
            
            print("✅ Wallet data reset completed")
            
        } catch {
            throw WalletRepositoryError.resetFailed(error.localizedDescription)
        }
    }
    
    func clearSessionData() {
        isLoggedIn = false
        // Clear any other session-specific data
        userDefaults.removeObject(forKey: AppConstants.UserDefaultsKeys.lastSyncTimestamp)
    }
}

// MARK: - Repository Extensions

extension DefaultWalletRepository {
    
    /// Increment app launch count
    func incrementLaunchCount() {
        appLaunchCount += 1
    }
    
    /// Update app version
    func updateAppVersion() {
        lastAppVersion = AppConstants.App.version
    }
    
    /// Check if this is first app launch
    var isFirstLaunch: Bool {
        return appLaunchCount == 0
    }
    
    /// Check if app was updated since last launch
    var wasAppUpdated: Bool {
        return lastAppVersion != AppConstants.App.version
    }
    
    /// Get wallet state summary for debugging
    func getWalletStateSummary() -> [String: Any] {
        return [
            "hasWallet": hasWallet,
            "isLoggedIn": isLoggedIn,
            "hasCompletedOnboarding": hasCompletedOnboarding,
            "mnemonicExists": mnemonicExists(),
            "isSeedCached": isSeedCached(),
            "biometricAuthEnabled": biometricAuthEnabled,
            "appLaunchCount": appLaunchCount,
            "lastAppVersion": lastAppVersion ?? "unknown",
            "currentAppVersion": AppConstants.App.version,
            "lastSyncTimestamp": lastSyncTimestamp?.description ?? "never"
        ]
    }
}
