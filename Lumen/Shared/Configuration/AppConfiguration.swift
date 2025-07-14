import Foundation
import BreezSDKLiquid

/// Protocol defining the configuration interface for the Lumen app
/// This provides a clean abstraction over configuration management,
/// making it easier to test and swap configuration sources.
protocol AppConfigurationProtocol {
    
    // MARK: - Environment Configuration
    
    /// Current app environment (development, staging, production)
    var environment: AppEnvironment { get }
    
    /// Whether the app is running in production mode
    var isProduction: Bool { get }
    
    /// Current log level for the application
    var logLevel: String { get }
    
    // MARK: - Network Configuration
    
    /// Liquid network to use (mainnet or testnet)
    var liquidNetwork: LiquidNetwork { get }
    
    /// Breez API key for SDK operations
    var breezApiKey: String { get }
    
    /// Whether to use testnet for development
    var useTestnet: Bool { get }
    
    // MARK: - Directory Configuration
    
    /// Working directory for Breez SDK
    var workingDirectory: String { get }
    
    /// App group identifier for shared storage
    var appGroupIdentifier: String { get }
    
    /// Keychain access group for shared keychain
    var keychainAccessGroup: String { get }
    
    // MARK: - Feature Flags
    
    /// Whether biometric authentication is enabled
    var biometricAuthEnabled: Bool { get }
    
    /// Whether to show debug information
    var debugModeEnabled: Bool { get }
    
    /// Whether to enable crash reporting
    var crashReportingEnabled: Bool { get }
    
    /// Whether to enable analytics
    var analyticsEnabled: Bool { get }
    
    // MARK: - API Configuration
    
    /// Base URL for BTCMap API
    var btcMapApiBaseURL: String { get }
    
    /// Timeout for network requests
    var networkTimeout: TimeInterval { get }
    
    /// Maximum retry attempts for failed requests
    var maxRetryAttempts: Int { get }
    
    // MARK: - Methods
    
    /// Get Breez SDK configuration
    /// - Returns: Configured Config object for Breez SDK
    /// - Throws: ConfigurationError if configuration is invalid
    func getBreezSDKConfig() throws -> Config
    
    /// Validate current configuration
    /// - Throws: ConfigurationError if configuration is invalid
    func validateConfiguration() throws
    
    /// Reload configuration from sources
    func reloadConfiguration()
}

/// App environment enumeration
enum AppEnvironment: String, CaseIterable {
    case development = "development"
    case staging = "staging"
    case production = "production"
    
    var isProduction: Bool {
        return self == .production
    }
    
    var displayName: String {
        switch self {
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
}

/// Configuration errors
enum AppConfigurationError: Error, LocalizedError {
    case missingApiKey
    case invalidApiKey
    case missingWorkingDirectory
    case invalidWorkingDirectory
    case invalidEnvironment
    case invalidConfiguration(String)
    
    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Breez API key is missing. Please check your configuration."
        case .invalidApiKey:
            return "Breez API key is invalid. Please check your configuration."
        case .missingWorkingDirectory:
            return "Working directory is not configured."
        case .invalidWorkingDirectory:
            return "Working directory is invalid or inaccessible."
        case .invalidEnvironment:
            return "Invalid environment configuration."
        case .invalidConfiguration(let message):
            return "Configuration error: \(message)"
        }
    }
}

/// Default implementation of AppConfigurationProtocol
/// This replaces the existing ConfigurationManager with a cleaner,
/// protocol-based approach that's easier to test and maintain.
class DefaultAppConfiguration: AppConfigurationProtocol {
    
    // MARK: - Private Properties
    
    private var _environment: AppEnvironment = .development
    private var _liquidNetwork: LiquidNetwork = .mainnet
    private var _breezApiKey: String = ""
    private var _logLevel: String = "info"
    private var _biometricAuthEnabled: Bool = true
    private var _debugModeEnabled: Bool = false
    private var _crashReportingEnabled: Bool = true
    private var _analyticsEnabled: Bool = false
    
    // MARK: - Initialization
    
    init() {
        loadConfiguration()
    }
    
    // MARK: - AppConfigurationProtocol Implementation
    
    var environment: AppEnvironment {
        return _environment
    }
    
    var isProduction: Bool {
        return _environment.isProduction
    }
    
    var logLevel: String {
        return _logLevel
    }
    
    var liquidNetwork: LiquidNetwork {
        return _liquidNetwork
    }
    
    var breezApiKey: String {
        return _breezApiKey
    }
    
    var useTestnet: Bool {
        return _liquidNetwork == .testnet
    }
    
    var workingDirectory: String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("breez_sdk").path
    }
    
    var appGroupIdentifier: String {
        return AppConstants.App.appGroup
    }
    
    var keychainAccessGroup: String {
        return AppConstants.App.keychainGroup
    }
    
    var biometricAuthEnabled: Bool {
        return _biometricAuthEnabled
    }
    
    var debugModeEnabled: Bool {
        return _debugModeEnabled || !isProduction
    }
    
    var crashReportingEnabled: Bool {
        return _crashReportingEnabled && isProduction
    }
    
    var analyticsEnabled: Bool {
        return _analyticsEnabled && isProduction
    }
    
    var btcMapApiBaseURL: String {
        return AppConstants.API.btcMapSnapshotURL
    }
    
    var networkTimeout: TimeInterval {
        return AppConstants.Limits.networkTimeoutStandard
    }
    
    var maxRetryAttempts: Int {
        return AppConstants.Limits.maxRetryAttempts
    }
    
    // MARK: - Methods
    
    func getBreezSDKConfig() throws -> Config {
        guard !breezApiKey.isEmpty else {
            throw AppConfigurationError.missingApiKey
        }
        
        guard isValidBreezApiKey(breezApiKey) else {
            throw AppConfigurationError.invalidApiKey
        }
        
        do {
            var config = try defaultConfig(
                network: liquidNetwork,
                breezApiKey: breezApiKey
            )
            
            // Ensure working directory exists
            let workingDir = workingDirectory
            try FileManager.default.createDirectory(
                atPath: workingDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            config.workingDir = workingDir
            
            return config
        } catch {
            throw AppConfigurationError.invalidConfiguration(error.localizedDescription)
        }
    }
    
    func validateConfiguration() throws {
        // Validate API key
        guard !breezApiKey.isEmpty else {
            throw AppConfigurationError.missingApiKey
        }
        
        guard isValidBreezApiKey(breezApiKey) else {
            throw AppConfigurationError.invalidApiKey
        }
        
        // Validate working directory
        let workingDir = workingDirectory
        let parentDir = (workingDir as NSString).deletingLastPathComponent
        
        guard FileManager.default.isWritableFile(atPath: parentDir) else {
            throw AppConfigurationError.invalidWorkingDirectory
        }
    }
    
    func reloadConfiguration() {
        loadConfiguration()
    }
    
    // MARK: - Private Methods
    
    private func loadConfiguration() {
        // Load from .env file if it exists
        loadDotEnvFile()

        // Load configuration values
        _breezApiKey = getEnvironmentValue(for: "BREEZ_API_KEY") ?? ""

        // Debug: Print API key status
        print("🔧 Configuration Debug:")
        print("   - API Key loaded: \(_breezApiKey.isEmpty ? "❌ EMPTY" : "✅ Found (\(_breezApiKey.count) chars)")")
        print("   - Environment: \(_environment)")
        print("   - Network: \(_liquidNetwork)")
        
        if let envString = getEnvironmentValue(for: "ENVIRONMENT"),
           let env = AppEnvironment(rawValue: envString) {
            _environment = env
        }
        
        if let networkString = getEnvironmentValue(for: "LIQUID_NETWORK") {
            _liquidNetwork = networkString.lowercased() == "testnet" ? .testnet : .mainnet
        }
        
        if let logString = getEnvironmentValue(for: "LOG_LEVEL"),
           ["debug", "info", "warn", "error"].contains(logString.lowercased()) {
            _logLevel = logString.lowercased()
        }
        
        // Load feature flags
        _biometricAuthEnabled = getBoolEnvironmentValue(for: "BIOMETRIC_AUTH_ENABLED") ?? true
        _debugModeEnabled = getBoolEnvironmentValue(for: "DEBUG_MODE_ENABLED") ?? false
        _crashReportingEnabled = getBoolEnvironmentValue(for: "CRASH_REPORTING_ENABLED") ?? true
        _analyticsEnabled = getBoolEnvironmentValue(for: "ANALYTICS_ENABLED") ?? false
    }
    
    private func loadDotEnvFile() {
        // Try to find .env file in bundle first
        var envPath: String?

        if let bundlePath = Bundle.main.path(forResource: ".env", ofType: nil) {
            envPath = bundlePath
            print("🔧 Found .env in bundle: \(bundlePath)")
        } else {
            // Fallback: try to find .env in project directory (development)
            let projectPaths = [
                Bundle.main.bundlePath + "/.env",
                Bundle.main.bundlePath + "/../.env",
                Bundle.main.bundlePath + "/../../.env"
            ]

            for path in projectPaths {
                if FileManager.default.fileExists(atPath: path) {
                    envPath = path
                    print("🔧 Found .env at fallback path: \(path)")
                    break
                }
            }
        }

        guard let path = envPath,
              let content = try? String(contentsOfFile: path) else {
            print("⚠️ Could not load .env file")
            return
        }

        print("✅ Loading .env from: \(path)")

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty && !trimmedLine.hasPrefix("#") else { continue }

            let parts = trimmedLine.components(separatedBy: "=")
            guard parts.count == 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)

            setenv(key, value, 1)
            print("🔧 Set env var: \(key) = \(value.prefix(10))...")
        }
    }
    
    private func getEnvironmentValue(for key: String) -> String? {
        // First check environment variables
        if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
            return value
        }
        
        // Then check Info.plist
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty {
            return value
        }
        
        return nil
    }
    
    private func getBoolEnvironmentValue(for key: String) -> Bool? {
        guard let stringValue = getEnvironmentValue(for: key) else { return nil }
        return stringValue.lowercased() == "true" || stringValue == "1"
    }
    
    private func isValidBreezApiKey(_ key: String) -> Bool {
        // Basic validation - Breez API keys are typically base64-encoded certificates
        return key.count > 100 && key.allSatisfy { char in
            char.isLetter || char.isNumber || char == "+" || char == "/" || char == "="
        }
    }
}

// MARK: - Singleton Access

extension DefaultAppConfiguration {
    
    /// Shared instance for global access
    /// In production code, consider using dependency injection instead
    static let shared = DefaultAppConfiguration()
}
