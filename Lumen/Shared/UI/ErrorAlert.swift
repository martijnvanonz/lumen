import SwiftUI

/// Reusable error alert view modifier for consistent error display across the app
/// This provides a standardized way to show errors with recovery actions
struct ErrorAlert: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $errorHandler.showingErrorAlert,
                presenting: errorHandler.currentError
            ) { error in
                // Recovery action button (if available)
                if let recoveryAction = error.recoveryAction {
                    Button(recoveryAction.message) {
                        handleRecoveryAction(recoveryAction)
                    }
                }
                
                // Dismiss button
                Button("OK") {
                    errorHandler.clearError()
                }
            } message: { error in
                Text(error.message)
            }
    }
    
    private func handleRecoveryAction(_ action: ErrorHandler.RecoveryAction) {
        switch action.type {
        case .retry:
            // Dismiss the alert and let the calling view handle retry
            errorHandler.clearError()
            
        case .settings:
            // Open Settings app
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
            errorHandler.clearError()
            
        case .wait:
            // Just dismiss the alert - user should wait
            errorHandler.clearError()
            
        case .info:
            // Just dismiss the alert - informational only
            errorHandler.clearError()
            
        case .restart:
            // Show restart instruction and dismiss
            errorHandler.clearError()
        }
    }
}

/// Enhanced error alert with custom recovery actions
struct ErrorAlertWithActions: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    let onRetry: (() -> Void)?
    let onSettings: (() -> Void)?
    
    init(errorHandler: ErrorHandler, onRetry: (() -> Void)? = nil, onSettings: (() -> Void)? = nil) {
        self.errorHandler = errorHandler
        self.onRetry = onRetry
        self.onSettings = onSettings
    }
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $errorHandler.showingErrorAlert,
                presenting: errorHandler.currentError
            ) { error in
                // Custom recovery actions
                if let recoveryAction = error.recoveryAction {
                    Button(recoveryAction.message) {
                        handleCustomRecoveryAction(recoveryAction)
                    }
                }
                
                // Dismiss button
                Button("OK") {
                    errorHandler.clearError()
                }
            } message: { error in
                Text(error.message)
            }
    }
    
    private func handleCustomRecoveryAction(_ action: ErrorHandler.RecoveryAction) {
        switch action.type {
        case .retry:
            errorHandler.clearError()
            onRetry?()
            
        case .settings:
            errorHandler.clearError()
            if let customSettings = onSettings {
                customSettings()
            } else {
                // Default to system settings
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            
        case .wait, .info, .restart:
            errorHandler.clearError()
        }
    }
}

/// Inline error display component for forms and input fields
struct InlineErrorView: View {
    let error: ErrorHandler.AppError?
    
    var body: some View {
        if let error = error {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: DesignSystem.Icons.error)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.error)
                
                Text(error.message)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.error)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.error.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                            .stroke(DesignSystem.Colors.error.opacity(0.3), lineWidth: AppConstants.UI.borderWidthThin)
                    )
            )
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

/// Error banner for non-blocking error display
struct ErrorBanner: View {
    let error: ErrorHandler.AppError
    let onDismiss: () -> Void
    let onAction: (() -> Void)?
    
    init(error: ErrorHandler.AppError, onDismiss: @escaping () -> Void, onAction: (() -> Void)? = nil) {
        self.error = error
        self.onDismiss = onDismiss
        self.onAction = onAction
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Error icon
            Image(systemName: DesignSystem.Icons.error)
                .font(DesignSystem.Typography.subheadline(weight: .medium))
                .foregroundColor(DesignSystem.Colors.error)
            
            // Error message
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs / 2) {
                Text(error.title)
                    .font(DesignSystem.Typography.subheadline(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(error.message)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Action button (if available)
            if let recoveryAction = error.recoveryAction, let onAction = onAction {
                Button(action: onAction) {
                    Text(recoveryAction.type == .retry ? "Retry" : "Fix")
                        .font(DesignSystem.Typography.caption(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.info)
                }
            }
            
            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(DesignSystem.Colors.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(DesignSystem.Colors.error.opacity(0.3), lineWidth: AppConstants.UI.borderWidthThin)
                )
        )
        .shadow(color: DesignSystem.Colors.error.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standard error alert to any view
    func errorAlert(errorHandler: ErrorHandler = ErrorHandler.shared) -> some View {
        self.modifier(ErrorAlert(errorHandler: errorHandler))
    }
    
    /// Apply error alert with custom recovery actions
    func errorAlert(
        errorHandler: ErrorHandler = ErrorHandler.shared,
        onRetry: (() -> Void)? = nil,
        onSettings: (() -> Void)? = nil
    ) -> some View {
        self.modifier(ErrorAlertWithActions(
            errorHandler: errorHandler,
            onRetry: onRetry,
            onSettings: onSettings
        ))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        // Inline error example
        InlineErrorView(error: .network(.noConnection))
        
        // Error banner example
        ErrorBanner(
            error: .payment(.insufficientFunds),
            onDismiss: {},
            onAction: {}
        )
        
        Spacer()
    }
    .padding()
}
