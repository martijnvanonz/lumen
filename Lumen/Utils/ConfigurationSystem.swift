import SwiftUI
import Foundation

// MARK: - Configuration Management System

/// Centralized configuration management with environment support
class ConfigurationSystem: ObservableObject {
    static let shared = ConfigurationSystem()
    
    @Published var currentEnvironment: Environment = .production
    @Published var userPreferences = UserPreferences()
    @Published var featureFlags = FeatureFlags()
    @Published var themeConfiguration = ThemeConfiguration()
    
    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainManager.shared
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Environment Management
    
    enum Environment: String, CaseIterable {
        case development = "development"
        case staging = "staging"
        case production = "production"
        
        var displayName: String {
            switch self {
            case .development: return "Development"
            case .staging: return "Staging"
            case .production: return "Production"
            }
        }
        
        var apiBaseURL: String {
            switch self {
            case .development: return "https://dev-api.lumen.app"
            case .staging: return "https://staging-api.lumen.app"
            case .production: return "https://api.lumen.app"
            }
        }
        
        var isDebugEnabled: Bool {
            self != .production
        }
        
        var logLevel: LogLevel {
            switch self {
            case .development: return .verbose
            case .staging: return .info
            case .production: return .error
            }
        }
    }
    
    // MARK: - Configuration Loading/Saving
    
    func loadConfiguration() {
        loadEnvironment()
        loadUserPreferences()
        loadFeatureFlags()
        loadThemeConfiguration()
    }
    
    func saveConfiguration() {
        saveEnvironment()
        saveUserPreferences()
        saveFeatureFlags()
        saveThemeConfiguration()
    }
    
    private func loadEnvironment() {
        if let envString = userDefaults.string(forKey: "selected_environment"),
           let env = Environment(rawValue: envString) {
            currentEnvironment = env
        }
    }
    
    private func saveEnvironment() {
        userDefaults.set(currentEnvironment.rawValue, forKey: "selected_environment")
    }
    
    private func loadUserPreferences() {
        if let data = userDefaults.data(forKey: "user_preferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            userPreferences = preferences
        }
    }
    
    private func saveUserPreferences() {
        if let data = try? JSONEncoder().encode(userPreferences) {
            userDefaults.set(data, forKey: "user_preferences")
        }
    }
    
    private func loadFeatureFlags() {
        if let data = userDefaults.data(forKey: "feature_flags"),
           let flags = try? JSONDecoder().decode(FeatureFlags.self, from: data) {
            featureFlags = flags
        }
    }
    
    private func saveFeatureFlags() {
        if let data = try? JSONEncoder().encode(featureFlags) {
            userDefaults.set(data, forKey: "feature_flags")
        }
    }
    
    private func loadThemeConfiguration() {
        if let data = userDefaults.data(forKey: "theme_configuration"),
           let theme = try? JSONDecoder().decode(ThemeConfiguration.self, from: data) {
            themeConfiguration = theme
        }
    }
    
    private func saveThemeConfiguration() {
        if let data = try? JSONEncoder().encode(themeConfiguration) {
            userDefaults.set(data, forKey: "theme_configuration")
        }
    }
    
    // MARK: - Configuration Updates
    
    func updateEnvironment(_ environment: Environment) {
        currentEnvironment = environment
        saveEnvironment()
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) {
        userPreferences = preferences
        saveUserPreferences()
    }
    
    func updateFeatureFlags(_ flags: FeatureFlags) {
        featureFlags = flags
        saveFeatureFlags()
    }
    
    func updateThemeConfiguration(_ theme: ThemeConfiguration) {
        themeConfiguration = theme
        saveThemeConfiguration()
    }
    
    // MARK: - Reset Configuration
    
    func resetToDefaults() {
        userPreferences = UserPreferences()
        featureFlags = FeatureFlags()
        themeConfiguration = ThemeConfiguration()
        saveConfiguration()
    }
}

// MARK: - User Preferences

struct UserPreferences: Codable {
    var currency: Currency = .usd
    var language: Language = .english
    var notifications: NotificationSettings = NotificationSettings()
    var security: SecuritySettings = SecuritySettings()
    var display: DisplaySettings = DisplaySettings()
    var privacy: PrivacySettings = PrivacySettings()
    
    enum Currency: String, CaseIterable, Codable {
        case usd = "USD"
        case eur = "EUR"
        case gbp = "GBP"
        case jpy = "JPY"
        case btc = "BTC"
        case sats = "SATS"
        
        var symbol: String {
            switch self {
            case .usd: return "$"
            case .eur: return "€"
            case .gbp: return "£"
            case .jpy: return "¥"
            case .btc: return "₿"
            case .sats: return "sats"
            }
        }
        
        var displayName: String {
            switch self {
            case .usd: return "US Dollar"
            case .eur: return "Euro"
            case .gbp: return "British Pound"
            case .jpy: return "Japanese Yen"
            case .btc: return "Bitcoin"
            case .sats: return "Satoshis"
            }
        }
    }
    
    enum Language: String, CaseIterable, Codable {
        case english = "en"
        case spanish = "es"
        case french = "fr"
        case german = "de"
        case japanese = "ja"
        case chinese = "zh"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            case .french: return "Français"
            case .german: return "Deutsch"
            case .japanese: return "日本語"
            case .chinese: return "中文"
            }
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettings: Codable {
    var paymentReceived: Bool = true
    var paymentSent: Bool = true
    var paymentFailed: Bool = true
    var networkStatus: Bool = true
    var securityAlerts: Bool = true
    var marketUpdates: Bool = false
    var promotions: Bool = false
    
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
    var badgeEnabled: Bool = true
}

// MARK: - Security Settings

struct SecuritySettings: Codable {
    var biometricEnabled: Bool = true
    var autoLockEnabled: Bool = true
    var autoLockTimeout: TimeInterval = 300 // 5 minutes
    var requireBiometricForPayments: Bool = true
    var requireBiometricForSettings: Bool = false
    var showBalanceOnLockScreen: Bool = false
    var allowScreenshots: Bool = false
    
    enum AutoLockTimeout: TimeInterval, CaseIterable {
        case immediate = 0
        case oneMinute = 60
        case fiveMinutes = 300
        case fifteenMinutes = 900
        case oneHour = 3600
        case never = -1
        
        var displayName: String {
            switch self {
            case .immediate: return "Immediately"
            case .oneMinute: return "1 minute"
            case .fiveMinutes: return "5 minutes"
            case .fifteenMinutes: return "15 minutes"
            case .oneHour: return "1 hour"
            case .never: return "Never"
            }
        }
    }
}

// MARK: - Display Settings

struct DisplaySettings: Codable {
    var theme: AppTheme.Mode = .system
    var fontSize: FontSize = .medium
    var showAmountsInSats: Bool = true
    var showUSDEquivalent: Bool = true
    var animationsEnabled: Bool = true
    var hapticFeedbackEnabled: Bool = true
    var reduceMotion: Bool = false
    
    enum FontSize: String, CaseIterable, Codable {
        case small = "small"
        case medium = "medium"
        case large = "large"
        case extraLarge = "extraLarge"
        
        var displayName: String {
            switch self {
            case .small: return "Small"
            case .medium: return "Medium"
            case .large: return "Large"
            case .extraLarge: return "Extra Large"
            }
        }
        
        var scaleFactor: CGFloat {
            switch self {
            case .small: return 0.9
            case .medium: return 1.0
            case .large: return 1.1
            case .extraLarge: return 1.2
            }
        }
    }
}

// MARK: - Privacy Settings

struct PrivacySettings: Codable {
    var analyticsEnabled: Bool = true
    var crashReportingEnabled: Bool = true
    var usageDataEnabled: Bool = false
    var locationServicesEnabled: Bool = false
    var cameraAccessEnabled: Bool = true
    var contactsAccessEnabled: Bool = false
}

// MARK: - Feature Flags

struct FeatureFlags: Codable {
    var advancedPaymentOptions: Bool = false
    var multiCurrencySupport: Bool = false
    var darkModeSupport: Bool = true
    var biometricPayments: Bool = true
    var qrCodeScanning: Bool = true
    var nfcPayments: Bool = false
    var voiceCommands: Bool = false
    var smartNotifications: Bool = false
    var advancedCharts: Bool = false
    var socialFeatures: Bool = false
    var experimentalFeatures: Bool = false
    
    // Development/Debug features
    var debugMode: Bool = false
    var performanceMonitoring: Bool = false
    var networkLogging: Bool = false
    var uiTesting: Bool = false
}

// MARK: - Theme Configuration

struct ThemeConfiguration: Codable {
    var primaryColor: String = "#007AFF"
    var accentColor: String = "#FF9500"
    var backgroundColor: String = "#FFFFFF"
    var textColor: String = "#000000"
    var cornerRadius: Double = 16.0
    var shadowOpacity: Double = 0.1
    var animationDuration: Double = 0.3
    
    var customColors: [String: String] = [:]
    var customFonts: [String: String] = [:]
    
    func color(for key: String) -> Color {
        if let hexString = customColors[key] {
            return Color(hex: hexString)
        }
        
        switch key {
        case "primary": return Color(hex: primaryColor)
        case "accent": return Color(hex: accentColor)
        case "background": return Color(hex: backgroundColor)
        case "text": return Color(hex: textColor)
        default: return Color.primary
        }
    }
}

// MARK: - Log Level

enum LogLevel: String, CaseIterable, Codable {
    case verbose = "verbose"
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case none = "none"
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - App Theme Mode

extension AppTheme {
    enum Mode: String, CaseIterable, Codable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "System"
            }
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }
}

// MARK: - Configuration View Extensions

extension View {
    /// Apply configuration-based styling
    func configuredTheme() -> some View {
        let config = ConfigurationSystem.shared.themeConfiguration
        let preferences = ConfigurationSystem.shared.userPreferences
        
        return self
            .preferredColorScheme(preferences.display.theme.colorScheme)
            .animation(
                preferences.display.animationsEnabled ? 
                Animation.easeInOut(duration: config.animationDuration) : nil,
                value: preferences.display.animationsEnabled
            )
    }
    
    /// Apply font size scaling
    func configuredFontSize() -> some View {
        let scaleFactor = ConfigurationSystem.shared.userPreferences.display.fontSize.scaleFactor
        return self.scaleEffect(scaleFactor)
    }
    
    /// Apply haptic feedback based on preferences
    func configuredHaptics(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        let isEnabled = ConfigurationSystem.shared.userPreferences.display.hapticFeedbackEnabled
        
        return self.onTapGesture {
            if isEnabled {
                let impactFeedback = UIImpactFeedbackGenerator(style: style)
                impactFeedback.impactOccurred()
            }
        }
    }
}

// MARK: - Configuration Binding Helpers

extension ConfigurationSystem {
    var environmentBinding: Binding<Environment> {
        Binding(
            get: { self.currentEnvironment },
            set: { self.updateEnvironment($0) }
        )
    }
    
    var userPreferencesBinding: Binding<UserPreferences> {
        Binding(
            get: { self.userPreferences },
            set: { self.updateUserPreferences($0) }
        )
    }
    
    var featureFlagsBinding: Binding<FeatureFlags> {
        Binding(
            get: { self.featureFlags },
            set: { self.updateFeatureFlags($0) }
        )
    }
    
    var themeConfigurationBinding: Binding<ThemeConfiguration> {
        Binding(
            get: { self.themeConfiguration },
            set: { self.updateThemeConfiguration($0) }
        )
    }
}

// MARK: - Configuration Validation

extension ConfigurationSystem {
    func validateConfiguration() -> [ConfigurationIssue] {
        var issues: [ConfigurationIssue] = []
        
        // Validate security settings
        if !userPreferences.security.biometricEnabled && 
           userPreferences.security.requireBiometricForPayments {
            issues.append(.inconsistentSecurity)
        }
        
        // Validate notification settings
        if !userPreferences.notifications.soundEnabled && 
           !userPreferences.notifications.vibrationEnabled {
            issues.append(.noNotificationFeedback)
        }
        
        // Validate theme configuration
        if themeConfiguration.animationDuration < 0 || themeConfiguration.animationDuration > 2.0 {
            issues.append(.invalidAnimationDuration)
        }
        
        return issues
    }
    
    enum ConfigurationIssue {
        case inconsistentSecurity
        case noNotificationFeedback
        case invalidAnimationDuration
        
        var description: String {
            switch self {
            case .inconsistentSecurity:
                return "Biometric authentication is required for payments but not enabled"
            case .noNotificationFeedback:
                return "No notification feedback methods are enabled"
            case .invalidAnimationDuration:
                return "Animation duration is outside valid range (0-2 seconds)"
            }
        }
        
        var severity: AppError.Severity {
            switch self {
            case .inconsistentSecurity: return .high
            case .noNotificationFeedback: return .medium
            case .invalidAnimationDuration: return .low
            }
        }
    }
}
