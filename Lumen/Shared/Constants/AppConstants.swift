import SwiftUI
import Foundation

/// Centralized constants for the Lumen Lightning Wallet app
/// This file eliminates hardcoded values throughout the codebase and provides
/// a single source of truth for configuration values, UI dimensions, and styling.
struct AppConstants {
    
    // MARK: - UI Dimensions & Spacing
    
    struct UI {
        // Corner Radius
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusStandard: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 16
        static let cornerRadiusXLarge: CGFloat = 20
        
        // Padding & Spacing
        static let paddingXSmall: CGFloat = 4
        static let paddingSmall: CGFloat = 8
        static let paddingStandard: CGFloat = 16
        static let paddingLarge: CGFloat = 24
        static let paddingXLarge: CGFloat = 32
        
        // Card & Component Spacing
        static let cardSpacing: CGFloat = 24
        static let sectionSpacing: CGFloat = 32
        static let componentSpacing: CGFloat = 12
        static let itemSpacing: CGFloat = 8
        
        // Button Dimensions
        static let buttonHeight: CGFloat = 50
        static let buttonHeightCompact: CGFloat = 40
        static let buttonHeightLarge: CGFloat = 56
        
        // Icon Sizes
        static let iconSizeSmall: CGFloat = 16
        static let iconSizeStandard: CGFloat = 20
        static let iconSizeLarge: CGFloat = 24
        static let iconSizeXLarge: CGFloat = 32
        
        // Animation Durations
        static let animationFast: Double = 0.2
        static let animationStandard: Double = 0.3
        static let animationSlow: Double = 0.5
        
        // Border Widths
        static let borderWidthThin: CGFloat = 1
        static let borderWidthStandard: CGFloat = 2
        static let borderWidthThick: CGFloat = 3
    }
    
    // MARK: - Colors
    
    struct Colors {
        // Brand Colors
        static let lightning = Color.yellow
        static let bitcoin = Color.orange
        static let liquid = Color.blue
        
        // Status Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Payment Method Colors
        static let bolt11 = Color.yellow
        static let lnUrlPay = Color.blue
        static let bolt12Offer = Color.purple
        static let bitcoinAddress = Color.orange
        static let lnUrlWithdraw = Color.green
        static let lnUrlAuth = Color.red
        static let unsupported = Color.gray
        
        // Network Quality Colors
        static let networkExcellent = Color.green
        static let networkGood = Color.yellow
        static let networkLimited = Color.orange
        static let networkPoor = Color.red
        static let networkOffline = Color.red
        
        // Background Colors
        static let cardBackground = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        
        // Border Colors
        static let borderPrimary = Color(.separator)
        static let borderSecondary = Color(.systemGray4)
        static let borderAccent = Color.blue.opacity(0.2)

        // Pastel Background Colors - Very subtle tones for gentle background
        static let pastelPink = Color(red: 0.99, green: 0.95, blue: 0.95)
        static let pastelPeach = Color(red: 0.99, green: 0.96, blue: 0.94)
        static let pastelLavender = Color(red: 0.95, green: 0.90, blue: 0.98)
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Font Weights
        static let weightLight = Font.Weight.light
        static let weightRegular = Font.Weight.regular
        static let weightMedium = Font.Weight.medium
        static let weightSemibold = Font.Weight.semibold
        static let weightBold = Font.Weight.bold
        
        // Font Sizes
        static let sizeCaption: CGFloat = 12
        static let sizeFootnote: CGFloat = 13
        static let sizeSubheadline: CGFloat = 15
        static let sizeBody: CGFloat = 17
        static let sizeHeadline: CGFloat = 17
        static let sizeTitle3: CGFloat = 20
        static let sizeTitle2: CGFloat = 22
        static let sizeTitle: CGFloat = 28
        static let sizeLargeTitle: CGFloat = 34
    }
    
    // MARK: - Payment & Fee Constants
    
    struct Fees {
        // Traditional Payment Method Fees (for comparison)
        static let creditCardRate: Double = 0.03 // 3%
        static let paypalRate: Double = 0.029 // 2.9%
        static let paypalFixedFee: Double = 0.30 // $0.30
        static let bankWireFee: Double = 25.0 // $25
        static let btcPriceForCalculation: Double = 45000 // Used for USD to sats conversion in comparisons
        
        // Lightning Network
        static let lightningServiceFeeRate: Double = 0.004 // 0.4%
        static let lightningMinRoutingFee: UInt64 = 1 // Minimum routing fee in sats
        static let lightningRoutingFeeRate: Double = 0.001 // 0.1% for routing fee estimation
        
        // Onchain
        static let onchainFeeEstimationBlocks: UInt32 = 6 // Blocks for fee estimation
        static let onchainDustLimit: UInt64 = 546 // Dust limit in sats
    }
    
    // MARK: - Limits & Thresholds
    
    struct Limits {
        // Amount Limits (in sats)
        static let minPaymentAmount: UInt64 = 1
        static let maxPaymentAmount: UInt64 = 100_000_000 // 1 BTC
        static let dustThreshold: UInt64 = 546
        
        // UI Limits
        static let maxRecentPayments: Int = 50
        static let maxErrorHistoryItems: Int = 100
        static let maxCachedPlaces: Int = 1000
        
        // Network Timeouts
        static let networkTimeoutShort: TimeInterval = 10
        static let networkTimeoutStandard: TimeInterval = 30
        static let networkTimeoutLong: TimeInterval = 60
        
        // Retry Limits
        static let maxRetryAttempts: Int = 3
        static let retryDelaySeconds: Double = 2.0
    }
    
    // MARK: - API & Configuration
    
    struct API {
        // BTCMap
        static let btcMapSnapshotURL = "https://api.btcmap.org/v2/elements"
        static let btcMapSearchRadius: Double = 50.0 // km
        static let btcMapMaxResults: Int = 100
        
        // Cache Keys
        static let btcMapCacheKey = "btc_map_places_cache"
        static let currencyRatesCacheKey = "currency_rates_cache"
        static let walletStateCacheKey = "wallet_state_cache"
        
        // Cache Durations (in seconds)
        static let btcMapCacheDuration: TimeInterval = 3600 // 1 hour
        static let currencyRatesCacheDuration: TimeInterval = 300 // 5 minutes
        static let walletStateCacheDuration: TimeInterval = 60 // 1 minute
    }
    
    // MARK: - UserDefaults Keys
    
    struct UserDefaultsKeys {
        static let hasWallet = "hasWallet"
        static let isLoggedIn = "isLoggedIn"
        static let selectedCurrency = "selectedCurrency"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let biometricAuthEnabled = "biometricAuthEnabled"
        static let lastSyncTimestamp = "lastSyncTimestamp"
        static let appLaunchCount = "appLaunchCount"
        static let lastAppVersion = "lastAppVersion"
    }
    
    // MARK: - Keychain Keys
    
    struct KeychainKeys {
        static let mnemonicKey = "BREEZ_SDK_LIQUID_SEED_MNEMONIC"
        static let apiKeyKey = "BREEZ_API_KEY"
        static let encryptionKeyKey = "WALLET_ENCRYPTION_KEY"
        static let biometricTokenKey = "BIOMETRIC_AUTH_TOKEN"
    }
    
    // MARK: - Notification Names
    
    struct Notifications {
        static let walletConnected = "WalletConnectedNotification"
        static let walletDisconnected = "WalletDisconnectedNotification"
        static let walletLoggedOut = "WalletLoggedOutNotification"
        static let onboardingCompleted = "OnboardingCompletedNotification"
        static let paymentReceived = "PaymentReceivedNotification"
        static let paymentSent = "PaymentSentNotification"
        static let balanceUpdated = "BalanceUpdatedNotification"
        static let networkStatusChanged = "NetworkStatusChangedNotification"
    }
    
    // MARK: - App Information
    
    struct App {
        static let name = "Lumen"
        static let bundleIdentifier = "com.yourcompany.lumen"
        static let appGroup = "group.com.yourcompany.lumen"
        static let keychainGroup = "TEAMID.com.yourcompany.SharedKeychain"
        static let urlScheme = "lumen"
        
        // Version & Build
        static var version: String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        }
        
        static var buildNumber: String {
            Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        }
    }
}

// MARK: - Convenience Extensions

extension AppConstants.Colors {
    /// Get color for payment method type
    static func colorForPaymentMethod(_ type: String) -> Color {
        switch type.lowercased() {
        case "bolt11": return bolt11
        case "lnurlpay": return lnUrlPay
        case "bolt12": return bolt12Offer
        case "bitcoin": return bitcoinAddress
        case "lnurlwithdraw": return lnUrlWithdraw
        case "lnurlauth": return lnUrlAuth
        default: return unsupported
        }
    }
    
    /// Get color for network quality
    static func colorForNetworkQuality(_ quality: String) -> Color {
        switch quality.lowercased() {
        case "excellent": return networkExcellent
        case "good": return networkGood
        case "limited": return networkLimited
        case "poor": return networkPoor
        case "offline": return networkOffline
        default: return networkOffline
        }
    }
}

extension AppConstants.UI {
    /// Standard card style with consistent styling
    static func cardStyle() -> some View {
        RoundedRectangle(cornerRadius: cornerRadiusStandard)
            .fill(AppConstants.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadiusStandard)
                    .stroke(AppConstants.Colors.borderPrimary, lineWidth: borderWidthThin)
            )
    }
    
    /// Standard button style
    static func buttonStyle(isEnabled: Bool = true) -> some View {
        RoundedRectangle(cornerRadius: cornerRadiusStandard)
            .fill(isEnabled ? AppConstants.Colors.info : AppConstants.Colors.borderSecondary)
            .frame(height: buttonHeight)
    }
}
