import Foundation
import SwiftUI
import BreezSDKLiquid

/// Centralized error handling and user-friendly error messages
class ErrorHandler: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentError: AppError?
    @Published var showingErrorAlert = false
    @Published var errorHistory: [ErrorLog] = []
    
    // MARK: - Types
    
    struct ErrorLog: Identifiable {
        let id = UUID()
        let error: AppError
        let timestamp: Date
        let context: String?
    }
    
    enum AppError: Error, Identifiable {
        case network(NetworkError)
        case wallet(WalletError)
        case biometric(BiometricError)
        case keychain(KeychainError)
        case payment(PaymentError)
        case sdk(SdkError)
        case location(LocationError)
        case configuration(ConfigurationError)
        case onboarding(OnboardingError)
        case currency(CurrencyError)
        case notification(NotificationError)
        case cache(CacheError)
        case unknown(String)

        var id: String {
            switch self {
            case .network(let error): return "network_\(error.rawValue)"
            case .wallet(let error): return "wallet_\(error.rawValue)"
            case .biometric(let error): return "biometric_\(error.rawValue)"
            case .keychain(let error): return "keychain_\(error.rawValue)"
            case .payment(let error): return "payment_\(error.rawValue)"
            case .sdk(let error): return "sdk_\(error.rawValue)"
            case .location(let error): return "location_\(error.rawValue)"
            case .configuration(let error): return "configuration_\(error.rawValue)"
            case .onboarding(let error): return "onboarding_\(error.rawValue)"
            case .currency(let error): return "currency_\(error.rawValue)"
            case .notification(let error): return "notification_\(error.rawValue)"
            case .cache(let error): return "cache_\(error.rawValue)"
            case .unknown(let message): return "unknown_\(message.hashValue)"
            }
        }
        
        var title: String {
            switch self {
            case .network: return "Connection Error"
            case .wallet: return "Wallet Error"
            case .biometric: return "Authentication Error"
            case .keychain: return "Security Error"
            case .payment: return "Payment Error"
            case .sdk: return "Service Error"
            case .location: return "Location Error"
            case .configuration: return "Configuration Error"
            case .onboarding: return "Setup Error"
            case .currency: return "Currency Error"
            case .notification: return "Notification Error"
            case .cache: return "Storage Error"
            case .unknown: return "Unexpected Error"
            }
        }

        var message: String {
            switch self {
            case .network(let error): return error.userMessage
            case .wallet(let error): return error.userMessage
            case .biometric(let error): return error.userMessage
            case .keychain(let error): return error.userMessage
            case .payment(let error): return error.userMessage
            case .sdk(let error): return error.userMessage
            case .location(let error): return error.userMessage
            case .configuration(let error): return error.userMessage
            case .onboarding(let error): return error.userMessage
            case .currency(let error): return error.userMessage
            case .notification(let error): return error.userMessage
            case .cache(let error): return error.userMessage
            case .unknown(let message): return message
            }
        }
        
        var recoveryAction: RecoveryAction? {
            switch self {
            case .network(.noConnection), .network(.timeout):
                return .retry("Check your internet connection and try again")
            case .biometric(.notAvailable):
                return .settings("Enable biometric authentication in Settings")
            case .biometric(.lockout):
                return .wait("Wait a moment and try again")
            case .wallet(.notConnected):
                return .retry("Reconnect to wallet")
            case .payment(.insufficientFunds):
                return .info("Add funds to your wallet")
            case .sdk(.serviceUnavailable):
                return .retry("Service temporarily unavailable")
            case .location(.noPermission), .location(.servicesDisabled):
                return .settings("Enable location services in Settings")
            case .location(.unavailable), .location(.timeout):
                return .retry("Try again to get your location")
            case .configuration(.missingApiKey), .configuration(.invalidApiKey):
                return .restart("Restart the app to reload configuration")
            case .onboarding(.seedGenerationFailed), .onboarding(.walletSetupFailed):
                return .retry("Try setting up your wallet again")
            case .currency(.exchangeRateFailed):
                return .retry("Refresh exchange rates")
            case .notification(.permissionDenied):
                return .settings("Enable notifications in Settings")
            case .cache(.storageFull):
                return .info("Free up device storage space")
            default:
                return nil
            }
        }
    }
    
    enum NetworkError: String, CaseIterable {
        case noConnection = "no_connection"
        case timeout = "timeout"
        case serverError = "server_error"
        case invalidResponse = "invalid_response"
        
        var userMessage: String {
            switch self {
            case .noConnection:
                return "No internet connection. Please check your network settings."
            case .timeout:
                return "Request timed out. Please try again."
            case .serverError:
                return "Server is temporarily unavailable. Please try again later."
            case .invalidResponse:
                return "Received invalid response from server."
            }
        }
    }
    
    enum WalletError: String, CaseIterable {
        case notConnected = "not_connected"
        case initializationFailed = "initialization_failed"
        case syncFailed = "sync_failed"
        case balanceUnavailable = "balance_unavailable"
        case invalidInvoice = "invalid_invoice"
        case insufficientFunds = "insufficient_funds"
        case networkError = "network_error"
        case unsupportedPaymentType = "unsupported_payment_type"
        case connectionFailed = "connection_failed"
        case importFailed = "import_failed"
        case deletionFailed = "deletion_failed"
        case exportFailed = "export_failed"
        case infoUpdateFailed = "info_update_failed"

        static func unsupportedPaymentType(_ message: String) -> WalletError {
            return .unsupportedPaymentType
        }

        var userMessage: String {
            switch self {
            case .notConnected:
                return "Wallet is not connected. Please restart the app."
            case .initializationFailed:
                return "Failed to initialize wallet. Please try again."
            case .syncFailed:
                return "Failed to sync wallet data. Check your connection."
            case .balanceUnavailable:
                return "Unable to retrieve wallet balance."
            case .invalidInvoice:
                return "The provided invoice is invalid or expired."
            case .insufficientFunds:
                return "Insufficient funds to complete this payment."
            case .networkError:
                return "Network connection error. Please check your internet connection."
            case .unsupportedPaymentType:
                return "This payment type is not yet supported."
            case .connectionFailed:
                return "Failed to connect to wallet service. Please try again."
            case .importFailed:
                return "Failed to import wallet. Please check your seed phrase."
            case .deletionFailed:
                return "Failed to delete wallet from secure storage."
            case .exportFailed:
                return "Failed to export wallet seed phrase."
            case .infoUpdateFailed:
                return "Failed to update wallet information."
            }
        }
    }
    
    enum BiometricError: String, CaseIterable {
        case notAvailable = "not_available"
        case notEnrolled = "not_enrolled"
        case lockout = "lockout"
        case authenticationFailed = "authentication_failed"
        case userCancel = "user_cancel"
        
        var userMessage: String {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device."
            case .notEnrolled:
                return "No biometric data is enrolled. Please set up Face ID or Touch ID."
            case .lockout:
                return "Biometric authentication is temporarily locked. Try again later."
            case .authenticationFailed:
                return "Biometric authentication failed. Please try again."
            case .userCancel:
                return "Authentication was cancelled."
            }
        }
    }
    
    enum KeychainError: String, CaseIterable {
        case itemNotFound = "item_not_found"
        case accessDenied = "access_denied"
        case storageError = "storage_error"
        case syncError = "sync_error"
        
        var userMessage: String {
            switch self {
            case .itemNotFound:
                return "Wallet data not found. You may need to create a new wallet."
            case .accessDenied:
                return "Access to secure storage denied. Check your device settings."
            case .storageError:
                return "Failed to save wallet data securely."
            case .syncError:
                return "Failed to sync wallet data with iCloud."
            }
        }
    }
    
    enum PaymentError: String, CaseIterable {
        case invalidInvoice = "invalid_invoice"
        case insufficientFunds = "insufficient_funds"
        case paymentFailed = "payment_failed"
        case invoiceExpired = "invoice_expired"
        case routingFailed = "routing_failed"
        
        var userMessage: String {
            switch self {
            case .invalidInvoice:
                return "Invalid payment request. Please check the invoice."
            case .insufficientFunds:
                return "Insufficient funds to complete this payment."
            case .paymentFailed:
                return "Payment failed. Please try again."
            case .invoiceExpired:
                return "Payment request has expired."
            case .routingFailed:
                return "Unable to find a route for this payment."
            }
        }
    }
    
    enum SdkError: String, CaseIterable {
        case serviceUnavailable = "service_unavailable"
        case configurationError = "configuration_error"
        case connectionFailed = "connection_failed"
        case operationFailed = "operation_failed"
        
        var userMessage: String {
            switch self {
            case .serviceUnavailable:
                return "Lightning service is temporarily unavailable."
            case .configurationError:
                return "Wallet configuration error. Please restart the app."
            case .connectionFailed:
                return "Failed to connect to Lightning network."
            case .operationFailed:
                return "Operation failed. Please try again."
            }
        }
    }
    
    struct RecoveryAction {
        let type: ActionType
        let message: String
        
        enum ActionType {
            case retry
            case settings
            case wait
            case info
            case restart
        }

        static func retry(_ message: String) -> RecoveryAction {
            RecoveryAction(type: .retry, message: message)
        }

        static func settings(_ message: String) -> RecoveryAction {
            RecoveryAction(type: .settings, message: message)
        }

        static func wait(_ message: String) -> RecoveryAction {
            RecoveryAction(type: .wait, message: message)
        }

        static func info(_ message: String) -> RecoveryAction {
            RecoveryAction(type: .info, message: message)
        }

        static func restart(_ message: String) -> RecoveryAction {
            RecoveryAction(type: .restart, message: message)
        }
    }
    
    // MARK: - Singleton
    
    static let shared = ErrorHandler()
    private init() {}
    
    // MARK: - Error Handling Methods
    
    /// Handle and display an error to the user
    func handle(_ error: Error, context: String? = nil) {
        let appError = mapToAppError(error)
        logError(appError, context: context)
        
        DispatchQueue.main.async {
            self.currentError = appError
            self.showingErrorAlert = true
        }
    }
    
    /// Handle an error without showing UI (for logging only)
    func logError(_ error: AppError, context: String? = nil) {
        let errorLog = ErrorLog(error: error, timestamp: Date(), context: context)

        // Update @Published properties on main thread
        DispatchQueue.main.async {
            self.errorHistory.append(errorLog)

            // Keep only the last 100 errors
            if self.errorHistory.count > 100 {
                self.errorHistory = Array(self.errorHistory.suffix(100))
            }
        }

        // Log to console for debugging (can be done on any thread)
        print("🚨 Error: \(error.title) - \(error.message)")
        if let context = context {
            print("   Context: \(context)")
        }
    }
    
    /// Map system errors to user-friendly app errors
    private func mapToAppError(_ error: Error) -> AppError {
        // Map KeychainManager errors
        if let keychainError = error as? KeychainManager.KeychainError {
            switch keychainError {
            case .itemNotFound:
                return .keychain(.itemNotFound)
            case .duplicateItem, .invalidData, .unexpectedError:
                return .keychain(.storageError)
            }
        }
        
        // Map BiometricManager errors
        if let biometricError = error as? BiometricManager.BiometricError {
            switch biometricError {
            case .notAvailable, .biometryNotAvailable:
                return .biometric(.notAvailable)
            case .notEnrolled, .biometryNotEnrolled:
                return .biometric(.notEnrolled)
            case .biometryLockout:
                return .biometric(.lockout)
            case .authenticationFailed:
                return .biometric(.authenticationFailed)
            case .userCancel:
                return .biometric(.userCancel)
            default:
                return .biometric(.authenticationFailed)
            }
        }
        
        // Map WalletManager errors
        if let walletError = error as? WalletError {
            switch walletError {
            case .notConnected:
                return .wallet(.notConnected)
            case .initializationFailed:
                return .wallet(.initializationFailed)
            case .syncFailed:
                return .wallet(.syncFailed)
            case .balanceUnavailable:
                return .wallet(.balanceUnavailable)
            case .invalidInvoice:
                return .payment(.invalidInvoice)
            case .insufficientFunds:
                return .payment(.insufficientFunds)
            case .networkError:
                return .network(.noConnection)
            case .unsupportedPaymentType:
                return .payment(.invalidInvoice)
            }
        }
        
        // Map URL/Network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .network(.noConnection)
            case .timedOut:
                return .network(.timeout)
            case .badServerResponse:
                return .network(.serverError)
            default:
                return .network(.invalidResponse)
            }
        }
        
        // Default to unknown error
        return .unknown(error.localizedDescription)
    }
    
    /// Clear current error
    func clearError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.showingErrorAlert = false
        }
    }
    
    /// Get recent errors for debugging
    func getRecentErrors(limit: Int = 10) -> [ErrorLog] {
        return Array(errorHistory.suffix(limit).reversed())
    }
}

// MARK: - Additional Error Types

/// Location-related errors (integrated from BTCMapErrorHandler)
enum LocationError: String, CaseIterable {
    case noPermission = "no_permission"
    case servicesDisabled = "services_disabled"
    case unavailable = "unavailable"
    case timeout = "timeout"

    var userMessage: String {
        switch self {
        case .noPermission:
            return "We need your location to show nearby Bitcoin places. Your location stays private and is only used on your device."
        case .servicesDisabled:
            return "Location services are disabled. Please enable them in Settings to see nearby Bitcoin places."
        case .unavailable:
            return "Unable to determine your location. Please check your connection and try again."
        case .timeout:
            return "Location request timed out. Please try again."
        }
    }
}

/// Configuration-related errors
enum ConfigurationError: String, CaseIterable {
    case missingApiKey = "missing_api_key"
    case invalidApiKey = "invalid_api_key"
    case missingConfiguration = "missing_configuration"
    case invalidEnvironment = "invalid_environment"

    var userMessage: String {
        switch self {
        case .missingApiKey:
            return "App configuration is incomplete. Please restart the app or contact support."
        case .invalidApiKey:
            return "App configuration is invalid. Please restart the app or contact support."
        case .missingConfiguration:
            return "Required configuration is missing. Please restart the app."
        case .invalidEnvironment:
            return "Invalid app environment configuration."
        }
    }
}

/// Onboarding and setup errors
enum OnboardingError: String, CaseIterable {
    case seedGenerationFailed = "seed_generation_failed"
    case walletSetupFailed = "wallet_setup_failed"
    case biometricSetupFailed = "biometric_setup_failed"
    case currencySelectionFailed = "currency_selection_failed"

    var userMessage: String {
        switch self {
        case .seedGenerationFailed:
            return "Failed to generate secure wallet seed. Please try again."
        case .walletSetupFailed:
            return "Failed to set up your wallet. Please try again or restart the app."
        case .biometricSetupFailed:
            return "Failed to set up biometric authentication. You can enable it later in Settings."
        case .currencySelectionFailed:
            return "Failed to save currency selection. You can change it later in Settings."
        }
    }
}

/// Currency and exchange rate errors
enum CurrencyError: String, CaseIterable {
    case exchangeRateFailed = "exchange_rate_failed"
    case unsupportedCurrency = "unsupported_currency"
    case conversionFailed = "conversion_failed"
    case rateLimitExceeded = "rate_limit_exceeded"

    var userMessage: String {
        switch self {
        case .exchangeRateFailed:
            return "Failed to fetch current exchange rates. Amounts may not be accurate."
        case .unsupportedCurrency:
            return "Selected currency is not supported. Please choose a different currency."
        case .conversionFailed:
            return "Failed to convert currency amounts. Please try again."
        case .rateLimitExceeded:
            return "Too many currency requests. Please wait a moment and try again."
        }
    }
}

/// Notification-related errors
enum NotificationError: String, CaseIterable {
    case permissionDenied = "permission_denied"
    case registrationFailed = "registration_failed"
    case deliveryFailed = "delivery_failed"
    case invalidToken = "invalid_token"

    var userMessage: String {
        switch self {
        case .permissionDenied:
            return "Notification permission denied. Enable notifications in Settings to receive payment alerts."
        case .registrationFailed:
            return "Failed to register for notifications. Some features may not work properly."
        case .deliveryFailed:
            return "Failed to deliver notification. Please check your notification settings."
        case .invalidToken:
            return "Notification configuration is invalid. Please restart the app."
        }
    }
}

/// Cache and local storage errors
enum CacheError: String, CaseIterable {
    case readFailed = "read_failed"
    case writeFailed = "write_failed"
    case corruptedData = "corrupted_data"
    case storageFull = "storage_full"
    case permissionDenied = "permission_denied"

    var userMessage: String {
        switch self {
        case .readFailed:
            return "Failed to load cached data. Some features may load slowly."
        case .writeFailed:
            return "Failed to save data locally. Some features may not work offline."
        case .corruptedData:
            return "Local data is corrupted. The app will refresh data from the server."
        case .storageFull:
            return "Device storage is full. Please free up space for optimal performance."
        case .permissionDenied:
            return "Storage permission denied. Some features may not work properly."
        }
    }
}
