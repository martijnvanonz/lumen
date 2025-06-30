import SwiftUI

struct ErrorAlertView: ViewModifier {
    @StateObject private var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $errorHandler.showingErrorAlert,
                presenting: errorHandler.currentError
            ) { error in
                // Primary action button
                if let recoveryAction = error.recoveryAction {
                    Button(actionButtonTitle(for: recoveryAction.type)) {
                        handleRecoveryAction(recoveryAction)
                    }
                }
                
                // Cancel/Dismiss button
                Button("OK") {
                    errorHandler.clearError()
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.message)
                    
                    if let recoveryAction = error.recoveryAction {
                        Text(recoveryAction.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
    }
    
    private func actionButtonTitle(for actionType: ErrorHandler.RecoveryAction.ActionType) -> String {
        switch actionType {
        case .retry: return "Try Again"
        case .settings: return "Settings"
        case .wait: return "OK"
        case .info: return "Got It"
        }
    }
    
    private func handleRecoveryAction(_ action: ErrorHandler.RecoveryAction) {
        switch action.type {
        case .retry:
            // Trigger retry logic - this would be handled by the specific view
            errorHandler.clearError()
            
        case .settings:
            // Open device settings
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
            errorHandler.clearError()
            
        case .wait, .info:
            // Just dismiss
            errorHandler.clearError()
        }
    }
}

extension View {
    func errorAlert() -> some View {
        modifier(ErrorAlertView())
    }
}

// MARK: - Error Banner View

struct ErrorBannerView: View {
    let error: ErrorHandler.AppError
    let onDismiss: () -> Void
    let onAction: (() -> Void)?
    
    init(error: ErrorHandler.AppError, onDismiss: @escaping () -> Void, onAction: (() -> Void)? = nil) {
        self.error = error
        self.onDismiss = onDismiss
        self.onAction = onAction
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.title3)
            
            // Error content
            VStack(alignment: .leading, spacing: 4) {
                Text(error.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(error.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let recoveryAction = error.recoveryAction {
                    Text(recoveryAction.message)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 8) {
                if let recoveryAction = error.recoveryAction, let onAction = onAction {
                    Button(actionButtonTitle(for: recoveryAction.type)) {
                        onAction()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
                
                Button("Dismiss") {
                    onDismiss()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .red.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private func actionButtonTitle(for actionType: ErrorHandler.RecoveryAction.ActionType) -> String {
        switch actionType {
        case .retry: return "Retry"
        case .settings: return "Settings"
        case .wait: return "Wait"
        case .info: return "Info"
        }
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let error: ErrorHandler.AppError
    let onRetry: (() -> Void)?
    
    init(error: ErrorHandler.AppError, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Error illustration
            VStack(spacing: 16) {
                Image(systemName: errorIcon)
                    .font(.system(size: 64))
                    .foregroundColor(.red)
                
                Text(error.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(error.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Recovery actions
            VStack(spacing: 12) {
                if let recoveryAction = error.recoveryAction {
                    Button(actionButtonTitle(for: recoveryAction.type)) {
                        handleRecoveryAction(recoveryAction)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text(recoveryAction.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if let onRetry = onRetry {
                    Button("Try Again") {
                        onRetry()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }
    
    private var errorIcon: String {
        switch error {
        case .network:
            return "wifi.slash"
        case .wallet:
            return "exclamationmark.triangle"
        case .biometric:
            return "faceid"
        case .keychain:
            return "lock.slash"
        case .payment:
            return "creditcard.trianglebadge.exclamationmark"
        case .sdk:
            return "server.rack"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private func actionButtonTitle(for actionType: ErrorHandler.RecoveryAction.ActionType) -> String {
        switch actionType {
        case .retry: return "Try Again"
        case .settings: return "Open Settings"
        case .wait: return "OK"
        case .info: return "Got It"
        }
    }
    
    private func handleRecoveryAction(_ action: ErrorHandler.RecoveryAction) {
        switch action.type {
        case .retry:
            onRetry?()
            
        case .settings:
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
            
        case .wait, .info:
            // Just acknowledge
            break
        }
    }
}

// MARK: - Loading with Error State

struct LoadingWithErrorView: View {
    let isLoading: Bool
    let error: ErrorHandler.AppError?
    let onRetry: () -> Void
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Loading...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else if let error = error {
                ErrorStateView(error: error, onRetry: onRetry)
            }
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        ErrorBannerView(
            error: .network(.noConnection),
            onDismiss: {},
            onAction: {}
        )
        
        ErrorStateView(
            error: .biometric(.notAvailable),
            onRetry: {}
        )
        
        LoadingWithErrorView(
            isLoading: false,
            error: .payment(.insufficientFunds),
            onRetry: {}
        )
    }
    .padding()
}
