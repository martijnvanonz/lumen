import SwiftUI
import BreezSDKLiquid

// MARK: - Advanced Error Handling System

/// Comprehensive error handling with recovery strategies
class AdvancedErrorHandler: ObservableObject {
    static let shared = AdvancedErrorHandler()
    
    @Published var currentError: AppError?
    @Published var errorHistory: [ErrorEvent] = []
    @Published var showingErrorAlert = false
    @Published var showingErrorSheet = false
    
    private let maxHistoryCount = 50
    private var errorCounts: [String: Int] = [:]
    
    private init() {}
    
    // MARK: - Error Handling
    
    func handle(_ error: Error, context: ErrorContext = .general) {
        let appError = AppError.from(error, context: context)
        
        DispatchQueue.main.async {
            self.currentError = appError
            self.addToHistory(appError)
            self.updateErrorCounts(appError)
            self.determinePresentation(appError)
        }
        
        // Log error for debugging
        logError(appError)
        
        // Send analytics if needed
        trackError(appError)
    }
    
    func handleAsync(_ error: Error, context: ErrorContext = .general) async {
        await MainActor.run {
            handle(error, context: context)
        }
    }
    
    func clearError() {
        currentError = nil
        showingErrorAlert = false
        showingErrorSheet = false
    }
    
    func clearHistory() {
        errorHistory.removeAll()
        errorCounts.removeAll()
    }
    
    // MARK: - Recovery Actions
    
    func executeRecovery(for error: AppError) async {
        guard let recovery = error.recoveryAction else { return }
        
        do {
            try await recovery.execute()
            clearError()
        } catch {
            handle(error, context: .recovery)
        }
    }
    
    // MARK: - Private Methods
    
    private func addToHistory(_ error: AppError) {
        let event = ErrorEvent(error: error, timestamp: Date())
        errorHistory.insert(event, at: 0)
        
        // Limit history size
        if errorHistory.count > maxHistoryCount {
            errorHistory = Array(errorHistory.prefix(maxHistoryCount))
        }
    }
    
    private func updateErrorCounts(_ error: AppError) {
        let key = error.identifier
        errorCounts[key, default: 0] += 1
    }
    
    private func determinePresentation(_ error: AppError) {
        switch error.severity {
        case .low:
            // Don't show UI for low severity errors
            break
        case .medium:
            showingErrorAlert = true
        case .high, .critical:
            showingErrorSheet = true
        }
    }
    
    private func logError(_ error: AppError) {
        print("🚨 Error: \(error.title)")
        print("   Message: \(error.message)")
        print("   Context: \(error.context)")
        print("   Severity: \(error.severity)")
        if let underlying = error.underlyingError {
            print("   Underlying: \(underlying)")
        }
    }
    
    private func trackError(_ error: AppError) {
        // Send to analytics service
        // Analytics.track("error_occurred", properties: error.analyticsProperties)
    }
}

// MARK: - App Error

struct AppError: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let severity: Severity
    let context: ErrorContext
    let underlyingError: Error?
    let recoveryAction: RecoveryAction?
    let timestamp: Date
    
    var identifier: String {
        "\(context.rawValue)_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }
    
    enum Severity: String, CaseIterable {
        case low, medium, high, critical
        
        var color: Color {
            switch self {
            case .low: return AppTheme.Colors.info
            case .medium: return AppTheme.Colors.warning
            case .high: return AppTheme.Colors.error
            case .critical: return Color.red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return AppTheme.Icons.info
            case .medium: return AppTheme.Icons.warning
            case .high: return AppTheme.Icons.error
            case .critical: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Factory Methods
    
    static func from(_ error: Error, context: ErrorContext) -> AppError {
        if let sdkError = error as? SdkError {
            return fromSdkError(sdkError, context: context)
        } else if let networkError = error as? URLError {
            return fromNetworkError(networkError, context: context)
        } else {
            return AppError(
                title: "Unexpected Error",
                message: error.localizedDescription,
                severity: .medium,
                context: context,
                underlyingError: error,
                recoveryAction: .retry,
                timestamp: Date()
            )
        }
    }
    
    private static func fromSdkError(_ error: SdkError, context: ErrorContext) -> AppError {
        switch error {
        case .alreadyStarted:
            return AppError(
                title: "Service Already Running",
                message: "The Lightning service is already running.",
                severity: .low,
                context: context,
                underlyingError: error,
                recoveryAction: nil,
                timestamp: Date()
            )
        case .notStarted:
            return AppError(
                title: "Service Not Started",
                message: "Please start the Lightning service first.",
                severity: .high,
                context: context,
                underlyingError: error,
                recoveryAction: .restart,
                timestamp: Date()
            )
        case .serviceConnectivity:
            return AppError(
                title: "Connection Error",
                message: "Unable to connect to Lightning service. Check your internet connection.",
                severity: .high,
                context: context,
                underlyingError: error,
                recoveryAction: .checkConnection,
                timestamp: Date()
            )
        case .generic(let message):
            return AppError(
                title: "Lightning Error",
                message: message,
                severity: .medium,
                context: context,
                underlyingError: error,
                recoveryAction: .retry,
                timestamp: Date()
            )
        }
    }
    
    private static func fromNetworkError(_ error: URLError, context: ErrorContext) -> AppError {
        let title: String
        let message: String
        let severity: Severity
        let recovery: RecoveryAction?
        
        switch error.code {
        case .notConnectedToInternet:
            title = "No Internet Connection"
            message = "Please check your internet connection and try again."
            severity = .high
            recovery = .checkConnection
        case .timedOut:
            title = "Request Timed Out"
            message = "The request took too long. Please try again."
            severity = .medium
            recovery = .retry
        case .cannotFindHost, .cannotConnectToHost:
            title = "Server Unavailable"
            message = "Unable to connect to the server. Please try again later."
            severity = .high
            recovery = .retry
        default:
            title = "Network Error"
            message = error.localizedDescription
            severity = .medium
            recovery = .retry
        }
        
        return AppError(
            title: title,
            message: message,
            severity: severity,
            context: context,
            underlyingError: error,
            recoveryAction: recovery,
            timestamp: Date()
        )
    }
}

// MARK: - Error Context

enum ErrorContext: String, CaseIterable {
    case general = "general"
    case wallet = "wallet"
    case payment = "payment"
    case network = "network"
    case authentication = "authentication"
    case recovery = "recovery"
    case sync = "sync"
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .wallet: return "Wallet"
        case .payment: return "Payment"
        case .network: return "Network"
        case .authentication: return "Authentication"
        case .recovery: return "Recovery"
        case .sync: return "Synchronization"
        }
    }
}

// MARK: - Recovery Action

enum RecoveryAction {
    case retry
    case restart
    case checkConnection
    case refreshWallet
    case reconnect
    case custom(String, () async throws -> Void)
    
    var title: String {
        switch self {
        case .retry: return "Try Again"
        case .restart: return "Restart Service"
        case .checkConnection: return "Check Connection"
        case .refreshWallet: return "Refresh Wallet"
        case .reconnect: return "Reconnect"
        case .custom(let title, _): return title
        }
    }
    
    func execute() async throws {
        switch self {
        case .retry:
            // Generic retry - implementation depends on context
            break
        case .restart:
            try await WalletManager.shared.restart()
        case .checkConnection:
            await NetworkMonitor.shared.attemptReconnection()
        case .refreshWallet:
            try await WalletManager.shared.sync()
        case .reconnect:
            try await WalletManager.shared.reconnect()
        case .custom(_, let action):
            try await action()
        }
    }
}

// MARK: - Error Event

struct ErrorEvent: Identifiable {
    let id = UUID()
    let error: AppError
    let timestamp: Date
    
    var timeAgo: String {
        timestamp.relativeFormatted()
    }
}

// MARK: - Error Analytics

extension AppError {
    var analyticsProperties: [String: Any] {
        [
            "error_id": identifier,
            "title": title,
            "severity": severity.rawValue,
            "context": context.rawValue,
            "has_recovery": recoveryAction != nil,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
}

// MARK: - Error UI Components

struct ErrorAlertView: View {
    let error: AppError
    let onDismiss: () -> Void
    let onRecovery: (() async -> Void)?
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Error icon and title
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: error.severity.icon)
                    .font(.system(size: 48))
                    .foregroundColor(error.severity.color)
                
                Text(error.title)
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            
            // Error message
            Text(error.message)
                .font(AppTheme.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Action buttons
            VStack(spacing: AppTheme.Spacing.md) {
                if let recovery = error.recoveryAction, let onRecovery = onRecovery {
                    Button(recovery.title) {
                        Task {
                            await onRecovery()
                        }
                    }
                    .primaryButton()
                }
                
                Button("Dismiss") {
                    onDismiss()
                }
                .secondaryButton()
            }
            .padding(.horizontal)
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
}

struct ErrorHistoryView: View {
    @StateObject private var errorHandler = AdvancedErrorHandler.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(errorHandler.errorHistory) { event in
                    ErrorHistoryRow(event: event)
                }
            }
            .navigationTitle("Error History")
            .toolbar {
                Button("Clear") {
                    errorHandler.clearHistory()
                }
            }
        }
    }
}

struct ErrorHistoryRow: View {
    let event: ErrorEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: event.error.severity.icon)
                    .foregroundColor(event.error.severity.color)
                
                Text(event.error.title)
                    .font(AppTheme.Typography.headline)
                
                Spacer()
                
                Text(event.timeAgo)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(event.error.message)
                .font(AppTheme.Typography.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Text(event.error.context.displayName)
                    .font(AppTheme.Typography.caption)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(AppTheme.Colors.secondary.opacity(0.1))
                    )
                
                Spacer()
                
                Text(event.error.severity.rawValue.uppercased())
                    .font(AppTheme.Typography.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(event.error.severity.color)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

// MARK: - View Extensions

extension View {
    /// Handle errors with advanced error handler
    func handleErrors() -> some View {
        self.modifier(ErrorHandlingModifier())
    }
    
    /// Show error alert
    func errorAlert(
        error: Binding<AppError?>,
        onRecovery: (() async -> Void)? = nil
    ) -> some View {
        self.alert(
            error.wrappedValue?.title ?? "Error",
            isPresented: .constant(error.wrappedValue != nil)
        ) {
            if let recovery = error.wrappedValue?.recoveryAction, let onRecovery = onRecovery {
                Button(recovery.title) {
                    Task {
                        await onRecovery()
                    }
                }
            }
            Button("OK") {
                error.wrappedValue = nil
            }
        } message: {
            Text(error.wrappedValue?.message ?? "")
        }
    }
}

struct ErrorHandlingModifier: ViewModifier {
    @StateObject private var errorHandler = AdvancedErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $errorHandler.showingErrorAlert
            ) {
                if let recovery = errorHandler.currentError?.recoveryAction {
                    Button(recovery.title) {
                        Task {
                            await errorHandler.executeRecovery(for: errorHandler.currentError!)
                        }
                    }
                }
                Button("OK") {
                    errorHandler.clearError()
                }
            } message: {
                Text(errorHandler.currentError?.message ?? "")
            }
            .sheet(isPresented: $errorHandler.showingErrorSheet) {
                if let error = errorHandler.currentError {
                    ErrorAlertView(
                        error: error,
                        onDismiss: {
                            errorHandler.clearError()
                        },
                        onRecovery: error.recoveryAction != nil ? {
                            await errorHandler.executeRecovery(for: error)
                        } : nil
                    )
                }
            }
    }
}
