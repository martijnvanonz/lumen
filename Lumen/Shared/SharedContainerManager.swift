import Foundation
import BreezSDKLiquid

/// Manages shared data access between main app and notification extension
class SharedContainerManager {
    
    // MARK: - Constants
    
    private enum Constants {
        static let appGroupIdentifier = "group.com.martijnvanonzenoort.Lumen.shared"
        static let keychainAccessGroup = "com.martijnvanonzenoort.Lumen.keychain"
        static let configFileName = "breez_config.json"
        static let webhookFileName = "webhook_config.json"
        static let lastSyncFileName = "last_sync.json"
    }
    
    // MARK: - Errors
    
    enum SharedContainerError: Error {
        case containerNotFound
        case fileNotFound
        case invalidData
        case encodingError
        case decodingError
        
        var localizedDescription: String {
            switch self {
            case .containerNotFound:
                return "Shared container not found"
            case .fileNotFound:
                return "Shared file not found"
            case .invalidData:
                return "Invalid data format"
            case .encodingError:
                return "Failed to encode data"
            case .decodingError:
                return "Failed to decode data"
            }
        }
    }
    
    // MARK: - Singleton
    
    static let shared = SharedContainerManager()
    private init() {}
    
    // MARK: - Container Access
    
    /// Gets the shared container URL
    private var containerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier)
    }
    
    /// Ensures the shared container is accessible
    private func ensureContainerAccess() throws -> URL {
        guard let containerURL = containerURL else {
            throw SharedContainerError.containerNotFound
        }
        
        // Create directory if it doesn't exist
        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
        
        return containerURL
    }
    
    // MARK: - Breez SDK Configuration Sharing
    
    /// Stores Breez SDK configuration for notification extension
    func storeBreezConfig(_ config: Config) throws {
        let containerURL = try ensureContainerAccess()
        let configURL = containerURL.appendingPathComponent(Constants.configFileName)
        
        do {
            let configData = BreezConfigData(
                workingDir: config.workingDir,
                networkString: config.network == .mainnet ? "mainnet" : "testnet",
                breezApiKey: config.breezApiKey,
                syncServiceUrl: config.syncServiceUrl,
                paymentTimeoutSec: config.paymentTimeoutSec,
                cacheDir: config.cacheDir
            )
            
            let data = try JSONEncoder().encode(configData)
            try data.write(to: configURL)
            
            print("✅ Stored Breez config in shared container")
        } catch {
            print("❌ Failed to store Breez config: \(error)")
            throw SharedContainerError.encodingError
        }
    }
    
    /// Retrieves Breez SDK configuration for notification extension
    func retrieveBreezConfig() throws -> BreezConfigData {
        let containerURL = try ensureContainerAccess()
        let configURL = containerURL.appendingPathComponent(Constants.configFileName)
        
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            throw SharedContainerError.fileNotFound
        }
        
        do {
            let data = try Data(contentsOf: configURL)
            let configData = try JSONDecoder().decode(BreezConfigData.self, from: data)
            return configData
        } catch {
            print("❌ Failed to retrieve Breez config: \(error)")
            throw SharedContainerError.decodingError
        }
    }
    
    // MARK: - Webhook Configuration
    
    /// Stores webhook configuration
    func storeWebhookConfig(_ webhookUrl: String) throws {
        let containerURL = try ensureContainerAccess()
        let webhookURL = containerURL.appendingPathComponent(Constants.webhookFileName)
        
        do {
            let webhookData = WebhookConfigData(webhookUrl: webhookUrl, registeredAt: Date())
            let data = try JSONEncoder().encode(webhookData)
            try data.write(to: webhookURL)
            
            print("✅ Stored webhook config in shared container")
        } catch {
            print("❌ Failed to store webhook config: \(error)")
            throw SharedContainerError.encodingError
        }
    }
    
    /// Retrieves webhook configuration
    func retrieveWebhookConfig() throws -> WebhookConfigData {
        let containerURL = try ensureContainerAccess()
        let webhookURL = containerURL.appendingPathComponent(Constants.webhookFileName)
        
        guard FileManager.default.fileExists(atPath: webhookURL.path) else {
            throw SharedContainerError.fileNotFound
        }
        
        do {
            let data = try Data(contentsOf: webhookURL)
            let webhookData = try JSONDecoder().decode(WebhookConfigData.self, from: data)
            return webhookData
        } catch {
            print("❌ Failed to retrieve webhook config: \(error)")
            throw SharedContainerError.decodingError
        }
    }
    
    // MARK: - Sync State Management
    
    /// Updates last sync timestamp
    func updateLastSyncTime() throws {
        let containerURL = try ensureContainerAccess()
        let syncURL = containerURL.appendingPathComponent(Constants.lastSyncFileName)
        
        do {
            let syncData = LastSyncData(lastSyncTime: Date())
            let data = try JSONEncoder().encode(syncData)
            try data.write(to: syncURL)
        } catch {
            print("❌ Failed to update last sync time: \(error)")
            throw SharedContainerError.encodingError
        }
    }
    
    /// Gets last sync timestamp
    func getLastSyncTime() -> Date? {
        guard let containerURL = containerURL else { return nil }
        let syncURL = containerURL.appendingPathComponent(Constants.lastSyncFileName)
        
        guard FileManager.default.fileExists(atPath: syncURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: syncURL)
            let syncData = try JSONDecoder().decode(LastSyncData.self, from: data)
            return syncData.lastSyncTime
        } catch {
            print("❌ Failed to get last sync time: \(error)")
            return nil
        }
    }
    
    // MARK: - Keychain Access with App Group
    
    /// Enhanced keychain manager that works with app groups
    func retrieveMnemonicForExtension() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.lumen.wallet",
            kSecAttrAccount as String: "wallet_mnemonic",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: true,
            kSecAttrAccessGroup as String: Constants.keychainAccessGroup
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let mnemonic = String(data: data, encoding: .utf8) else {
                throw SharedContainerError.invalidData
            }
            return mnemonic
        case errSecItemNotFound:
            throw SharedContainerError.fileNotFound
        default:
            throw SharedContainerError.invalidData
        }
    }
}

// MARK: - Data Models

/// Breez SDK configuration data for sharing
struct BreezConfigData: Codable {
    let workingDir: String
    let networkString: String // Store as string instead of enum
    let breezApiKey: String?
    let syncServiceUrl: String?
    let paymentTimeoutSec: UInt64
    let cacheDir: String?

    // Computed property to convert back to LiquidNetwork
    var network: LiquidNetwork {
        return networkString == "mainnet" ? .mainnet : .testnet
    }
}

/// Webhook configuration data
struct WebhookConfigData: Codable {
    let webhookUrl: String
    let registeredAt: Date
}

/// Last sync data
struct LastSyncData: Codable {
    let lastSyncTime: Date
}
