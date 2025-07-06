import Foundation
import Security

/// Manages secure storage of sensitive data in iCloud Keychain
class KeychainManager {
    
    // MARK: - Constants
    
    private enum Constants {
        static let service = "com.lumen.wallet"
        static let mnemonicKey = "wallet_mnemonic"
    }
    
    // MARK: - Errors
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case invalidData
        case unexpectedError(OSStatus)
        
        var localizedDescription: String {
            switch self {
            case .itemNotFound:
                return "Item not found in keychain"
            case .duplicateItem:
                return "Item already exists in keychain"
            case .invalidData:
                return "Invalid data format"
            case .unexpectedError(let status):
                return "Unexpected keychain error: \(status)"
            }
        }
    }
    
    // MARK: - Singleton
    
    static let shared = KeychainManager()
    private init() {}
    
    // MARK: - Mnemonic Storage
    
    /// Stores the wallet mnemonic securely in iCloud Keychain
    /// - Parameter mnemonic: The mnemonic phrase to store
    /// - Throws: KeychainError if storage fails
    func storeMnemonic(_ mnemonic: String) throws {
        guard let data = mnemonic.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.service,
            kSecAttrAccount as String: Constants.mnemonicKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecAttrSynchronizable as String: true // Enable iCloud sync
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            break
        case errSecDuplicateItem:
            throw KeychainError.duplicateItem
        default:
            throw KeychainError.unexpectedError(status)
        }
    }
    
    /// Retrieves the wallet mnemonic from iCloud Keychain
    /// - Returns: The stored mnemonic phrase
    /// - Throws: KeychainError if retrieval fails
    func retrieveMnemonic() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.service,
            kSecAttrAccount as String: Constants.mnemonicKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let mnemonic = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return mnemonic
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unexpectedError(status)
        }
    }

    /// Retrieves the wallet mnemonic with biometric authentication
    /// - Parameter reason: The reason for authentication to display to the user
    /// - Returns: The stored mnemonic phrase
    /// - Throws: KeychainError or BiometricError if retrieval fails
    func retrieveMnemonicWithBiometrics(reason: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            BiometricManager.shared.authenticateAndRetrieveMnemonic(reason: reason) { result in
                switch result {
                case .success(let mnemonic):
                    continuation.resume(returning: mnemonic)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Updates an existing mnemonic in the keychain
    /// - Parameter mnemonic: The new mnemonic phrase
    /// - Throws: KeychainError if update fails
    func updateMnemonic(_ mnemonic: String) throws {
        guard let data = mnemonic.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.service,
            kSecAttrAccount as String: Constants.mnemonicKey,
            kSecAttrSynchronizable as String: true
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unexpectedError(status)
        }
    }
    
    /// Deletes the mnemonic from the keychain
    /// - Throws: KeychainError if deletion fails
    func deleteMnemonic() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.service,
            kSecAttrAccount as String: Constants.mnemonicKey,
            kSecAttrSynchronizable as String: true
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            break // Success or item already doesn't exist
        default:
            throw KeychainError.unexpectedError(status)
        }
    }
    
    /// Checks if a mnemonic exists in the keychain
    /// - Returns: true if mnemonic exists, false otherwise
    func mnemonicExists() -> Bool {
        do {
            _ = try retrieveMnemonic()
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Convenience Methods

extension KeychainManager {
    
    /// Safely stores or updates a mnemonic
    /// - Parameter mnemonic: The mnemonic to store
    /// - Throws: KeychainError if operation fails
    func storeOrUpdateMnemonic(_ mnemonic: String) throws {
        if mnemonicExists() {
            try updateMnemonic(mnemonic)
        } else {
            try storeMnemonic(mnemonic)
        }
    }

    /// Retrieves mnemonic with secure caching and biometric authentication
    /// - Parameter reason: The reason for authentication to display to the user
    /// - Returns: The mnemonic from cache or keychain
    /// - Throws: Error if retrieval fails
    func getSecureMnemonic(reason: String) async throws -> String {
        // First try to get from secure cache
        do {
            let cachedSeed = try SecureSeedCache.shared.retrieveSeed()
            print("✅ Retrieved seed from secure cache")
            return cachedSeed
        } catch SecureSeedCache.CacheError.cacheEmpty, SecureSeedCache.CacheError.cacheExpired {
            // Cache miss or expired - authenticate and retrieve from keychain
            print("🔐 Cache miss - authenticating for keychain access")

            let mnemonic = try await retrieveMnemonicWithBiometrics(reason: reason)

            // Cache the retrieved seed for future use
            SecureSeedCache.shared.storeSeed(mnemonic)

            return mnemonic
        } catch {
            // Security violation or other cache error - clear cache and re-authenticate
            print("⚠️ Cache security error - clearing and re-authenticating")
            SecureSeedCache.shared.clearCache()

            let mnemonic = try await retrieveMnemonicWithBiometrics(reason: reason)
            SecureSeedCache.shared.storeSeed(mnemonic)

            return mnemonic
        }
    }
}
