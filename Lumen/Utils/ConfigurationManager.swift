import Foundation
import BreezSDKLiquid

/// Manages app configuration from environment variables and build settings
class ConfigurationManager {
    
    // MARK: - Singleton
    
    static let shared = ConfigurationManager()
    private init() {
        loadEnvironmentVariables()
    }
    
    // MARK: - Configuration Properties
    
    private(set) var breezApiKey: String = ""
    private(set) var environment: Environment = .development
    private(set) var liquidNetwork: LiquidNetwork = .mainnet
    private(set) var logLevel: LogLevel = .info
    
    // MARK: - Types
    
    enum Environment: String, CaseIterable {
        case development = "development"
        case staging = "staging"
        case production = "production"
        
        var isProduction: Bool {
            return self == .production
        }
    }
    
    enum LogLevel: String, CaseIterable {
        case debug = "debug"
        case info = "info"
        case warning = "warning"
        case error = "error"
        
        var priority: Int {
            switch self {
            case .debug: return 0
            case .info: return 1
            case .warning: return 2
            case .error: return 3
            }
        }
    }
    
    // MARK: - Configuration Loading
    
    private func loadEnvironmentVariables() {
        // Load from .env file if it exists
        loadDotEnvFile()
        
        // Load configuration values
        breezApiKey = getEnvironmentValue(for: "BREEZ_API_KEY") ?? ""
        
        if let envString = getEnvironmentValue(for: "ENVIRONMENT"),
           let env = Environment(rawValue: envString) {
            environment = env
        }
        
        if let networkString = getEnvironmentValue(for: "LIQUID_NETWORK") {
            liquidNetwork = networkString.lowercased() == "testnet" ? .testnet : .mainnet
        }
        
        if let logString = getEnvironmentValue(for: "LOG_LEVEL"),
           let level = LogLevel(rawValue: logString) {
            logLevel = level
        }
        
        // Validate critical configuration
        validateConfiguration()
    }
    
    private func loadDotEnvFile() {
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print("⚠️ .env file not found in bundle")
            return
        }
        
        do {
            let content = try String(contentsOfFile: path)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip empty lines and comments
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }
                
                // Parse key=value pairs
                let components = trimmedLine.components(separatedBy: "=")
                if components.count >= 2 {
                    let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = components.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                    setenv(key, value, 1)
                }
            }
            
            print("✅ Loaded .env file successfully")
        } catch {
            print("⚠️ Failed to load .env file: \(error)")
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
    
    private func validateConfiguration() {
        var errors: [String] = []
        
        // Validate API key
        if breezApiKey.isEmpty {
            errors.append("BREEZ_API_KEY is required but not set")
        } else if !isValidBreezApiKey(breezApiKey) {
            errors.append("BREEZ_API_KEY format appears invalid")
        }
        
        // Log validation results
        if errors.isEmpty {
            print("✅ Configuration validation passed")
            print("   Environment: \(environment.rawValue)")
            print("   Network: \(liquidNetwork == .mainnet ? "mainnet" : "testnet")")
            print("   Log Level: \(logLevel.rawValue)")
            print("   API Key: \(breezApiKey.prefix(20))...")
        } else {
            print("❌ Configuration validation failed:")
            for error in errors {
                print("   - \(error)")
            }
        }
    }
    
    private func isValidBreezApiKey(_ key: String) -> Bool {
        // Basic validation - Breez API keys are typically base64-encoded certificates
        // They should be reasonably long and contain valid base64 characters
        return key.count > 100 && key.allSatisfy { char in
            char.isLetter || char.isNumber || char == "+" || char == "/" || char == "="
        }
    }
    
    // MARK: - Public Methods
    
    /// Gets the Breez SDK configuration with the API key
    func getBreezSDKConfig() throws -> Config {
        guard !breezApiKey.isEmpty else {
            throw ConfigurationError.missingApiKey
        }
        
        do {
            var config = try defaultConfig(
                network: liquidNetwork,
                breezApiKey: breezApiKey
            )

            // Set working directory to app's documents directory to avoid read-only file system errors
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let workingDir = documentsPath.appendingPathComponent("breez_sdk").path

            // Create directory if it doesn't exist
            try FileManager.default.createDirectory(atPath: workingDir, withIntermediateDirectories: true, attributes: nil)

            config.workingDir = workingDir

            print("✅ Created Breez SDK config for \(liquidNetwork == .mainnet ? "mainnet" : "testnet")")
            print("📁 Working directory: \(workingDir)")
            return config
        } catch {
            print("❌ Failed to create Breez SDK config: \(error)")
            throw ConfigurationError.invalidConfiguration(error.localizedDescription)
        }
    }
    
    /// Checks if the app is running in production mode
    var isProduction: Bool {
        return environment.isProduction
    }
    
    /// Gets the display name for the current environment
    var environmentDisplayName: String {
        switch environment {
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
    
    /// Gets the network display name
    var networkDisplayName: String {
        return liquidNetwork == .mainnet ? "Bitcoin Mainnet" : "Bitcoin Testnet"
    }
    
    /// Logs a message if it meets the current log level
    func log(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard level.priority >= logLevel.priority else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        
        let levelIcon = level.icon
        print("\(timestamp) \(levelIcon) [\(fileName):\(line)] \(function) - \(message)")
    }
    
    // MARK: - Configuration Errors
    
    enum ConfigurationError: Error, LocalizedError {
        case missingApiKey
        case invalidConfiguration(String)
        
        var errorDescription: String? {
            switch self {
            case .missingApiKey:
                return "Breez API key is missing. Please check your .env file or environment variables."
            case .invalidConfiguration(let details):
                return "Invalid configuration: \(details)"
            }
        }
    }
}

// MARK: - Extensions

private extension ConfigurationManager.LogLevel {
    var icon: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Global Logging Functions

/// Global logging functions for convenience
func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    ConfigurationManager.shared.log(.debug, message, file: file, function: function, line: line)
}

func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    ConfigurationManager.shared.log(.info, message, file: file, function: function, line: line)
}

func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    ConfigurationManager.shared.log(.warning, message, file: file, function: function, line: line)
}

func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    ConfigurationManager.shared.log(.error, message, file: file, function: function, line: line)
}
