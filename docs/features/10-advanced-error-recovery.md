# Advanced Error Recovery

## Status: ⚠️ Partial (Needs Completion)

## Overview
**Purpose**: Handle all payment failure scenarios with appropriate user guidance.

**Documentation**: [Production Checklist](https://sdk-doc-liquid.breez.technology/guide/production.html)

**User Impact**: When payments fail, users need clear guidance on what went wrong and how to fix it. Without proper error recovery, users may lose funds, retry failed operations, or abandon the wallet entirely.

## Current Implementation Status

### ✅ What's Already Implemented
- Basic error handling in `ErrorHandler.swift`
- Simple error messages for common failures
- Basic retry mechanisms for network issues

### ⚠️ What Needs Enhancement
- Comprehensive error categorization and recovery strategies
- User-friendly error explanations with actionable steps
- Automatic recovery for transient failures
- Error reporting and analytics

## Implementation Details

### Files to Modify/Enhance
- **Enhance**: `Lumen/Utils/ErrorHandler.swift` (existing file needs major enhancement)
- **Modify**: `Lumen/Wallet/PaymentEventHandler.swift` (add more event handling)
- **Create**: `Lumen/Utils/ErrorRecoveryManager.swift` (new file)
- **Create**: `Lumen/Views/ErrorRecoveryView.swift` (new file)

### Dependencies
- Refund management (for payment recovery)

## Error Categories and Recovery Strategies

### Network Errors
- **Temporary connectivity issues**: Auto-retry with exponential backoff
- **API rate limiting**: Implement proper backoff and user notification
- **Server maintenance**: Inform user and suggest retry later

### Payment Errors
- **Insufficient funds**: Show balance and suggest funding options
- **Payment expired**: Generate new invoice/address
- **Route not found**: Suggest alternative payment methods
- **Fee too low**: Offer fee adjustment options

### SDK Errors
- **Connection lost**: Attempt reconnection with user feedback
- **Invalid state**: Guide user through recovery steps
- **Configuration errors**: Provide setup assistance

### User Errors
- **Invalid input**: Clear validation messages with examples
- **Amount too small/large**: Show limits and suggest valid amounts
- **Wrong network**: Explain network compatibility

## Enhanced Implementation

### Step 1: Create ErrorRecoveryManager
Create `Lumen/Utils/ErrorRecoveryManager.swift`:

```swift
import Foundation
import BreezSDKLiquid

class ErrorRecoveryManager: ObservableObject {
    @Published var activeRecoveries: [ErrorRecoverySession] = []
    @Published var isRecovering = false
    
    private let walletManager = WalletManager.shared
    private let errorHandler = ErrorHandler.shared
    
    static let shared = ErrorRecoveryManager()
    private init() {}
    
    /// Handle error with automatic recovery attempt
    func handleError(_ error: Error, context: String) async -> ErrorRecoveryResult {
        let categorizedError = categorizeError(error)
        let recoveryStrategy = getRecoveryStrategy(for: categorizedError)
        
        // Create recovery session
        let session = ErrorRecoverySession(
            error: categorizedError,
            context: context,
            strategy: recoveryStrategy,
            createdAt: Date()
        )
        
        await MainActor.run {
            activeRecoveries.append(session)
            isRecovering = true
        }
        
        // Attempt automatic recovery
        let result = await attemptRecovery(session: session)
        
        await MainActor.run {
            if let index = activeRecoveries.firstIndex(where: { $0.id == session.id }) {
                activeRecoveries[index].result = result
                if result.isResolved {
                    activeRecoveries.remove(at: index)
                }
            }
            isRecovering = activeRecoveries.contains { $0.result == nil }
        }
        
        return result
    }
    
    /// Categorize error for appropriate handling
    private func categorizeError(_ error: Error) -> CategorizedError {
        if let sdkError = error as? SdkError {
            return categorizeSdkError(sdkError)
        } else if let networkError = error as? URLError {
            return categorizeNetworkError(networkError)
        } else {
            return CategorizedError(
                type: .unknown,
                severity: .medium,
                originalError: error,
                userMessage: "An unexpected error occurred",
                technicalDetails: error.localizedDescription
            )
        }
    }
    
    /// Categorize SDK-specific errors
    private func categorizeSdkError(_ error: SdkError) -> CategorizedError {
        switch error {
        case .generic(let message):
            if message.contains("insufficient") {
                return CategorizedError(
                    type: .insufficientFunds,
                    severity: .high,
                    originalError: error,
                    userMessage: "Insufficient funds for this payment",
                    technicalDetails: message,
                    suggestedActions: [.checkBalance, .addFunds]
                )
            } else if message.contains("expired") {
                return CategorizedError(
                    type: .paymentExpired,
                    severity: .medium,
                    originalError: error,
                    userMessage: "Payment request has expired",
                    technicalDetails: message,
                    suggestedActions: [.generateNewInvoice, .retryPayment]
                )
            } else {
                return CategorizedError(
                    type: .sdkGeneric,
                    severity: .medium,
                    originalError: error,
                    userMessage: "Payment processing error",
                    technicalDetails: message,
                    suggestedActions: [.retryOperation, .contactSupport]
                )
            }
        }
    }
    
    /// Categorize network errors
    private func categorizeNetworkError(_ error: URLError) -> CategorizedError {
        switch error.code {
        case .notConnectedToInternet:
            return CategorizedError(
                type: .networkUnavailable,
                severity: .high,
                originalError: error,
                userMessage: "No internet connection",
                technicalDetails: error.localizedDescription,
                suggestedActions: [.checkConnection, .retryWhenOnline]
            )
            
        case .timedOut:
            return CategorizedError(
                type: .networkTimeout,
                severity: .medium,
                originalError: error,
                userMessage: "Request timed out",
                technicalDetails: error.localizedDescription,
                suggestedActions: [.retryOperation, .checkConnection]
            )
            
        default:
            return CategorizedError(
                type: .networkGeneric,
                severity: .medium,
                originalError: error,
                userMessage: "Network error occurred",
                technicalDetails: error.localizedDescription,
                suggestedActions: [.retryOperation, .checkConnection]
            )
        }
    }
    
    /// Get recovery strategy for error type
    private func getRecoveryStrategy(for error: CategorizedError) -> RecoveryStrategy {
        switch error.type {
        case .networkUnavailable, .networkTimeout:
            return RecoveryStrategy(
                type: .autoRetry,
                maxAttempts: 3,
                backoffStrategy: .exponential,
                userInteractionRequired: false
            )
            
        case .insufficientFunds:
            return RecoveryStrategy(
                type: .userAction,
                maxAttempts: 1,
                backoffStrategy: .none,
                userInteractionRequired: true
            )
            
        case .paymentExpired:
            return RecoveryStrategy(
                type: .regenerate,
                maxAttempts: 1,
                backoffStrategy: .none,
                userInteractionRequired: true
            )
            
        default:
            return RecoveryStrategy(
                type: .manual,
                maxAttempts: 1,
                backoffStrategy: .none,
                userInteractionRequired: true
            )
        }
    }
    
    /// Attempt automatic recovery
    private func attemptRecovery(session: ErrorRecoverySession) async -> ErrorRecoveryResult {
        switch session.strategy.type {
        case .autoRetry:
            return await attemptAutoRetry(session: session)
            
        case .userAction:
            return ErrorRecoveryResult(
                isResolved: false,
                requiresUserAction: true,
                userMessage: session.error.userMessage,
                suggestedActions: session.error.suggestedActions
            )
            
        case .regenerate:
            return await attemptRegeneration(session: session)
            
        case .manual:
            return ErrorRecoveryResult(
                isResolved: false,
                requiresUserAction: true,
                userMessage: session.error.userMessage,
                suggestedActions: session.error.suggestedActions
            )
        }
    }
    
    /// Attempt automatic retry with backoff
    private func attemptAutoRetry(session: ErrorRecoverySession) async -> ErrorRecoveryResult {
        var attempt = 0
        let maxAttempts = session.strategy.maxAttempts
        
        while attempt < maxAttempts {
            attempt += 1
            
            // Calculate backoff delay
            let delay = calculateBackoffDelay(attempt: attempt, strategy: session.strategy.backoffStrategy)
            
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            
            // Attempt recovery based on context
            let success = await attemptContextualRecovery(session: session)
            
            if success {
                return ErrorRecoveryResult(
                    isResolved: true,
                    requiresUserAction: false,
                    userMessage: "Issue resolved automatically",
                    attemptsMade: attempt
                )
            }
        }
        
        return ErrorRecoveryResult(
            isResolved: false,
            requiresUserAction: true,
            userMessage: "Automatic recovery failed. Manual intervention required.",
            suggestedActions: session.error.suggestedActions,
            attemptsMade: attempt
        )
    }
    
    /// Attempt regeneration (e.g., new invoice)
    private func attemptRegeneration(session: ErrorRecoverySession) async -> ErrorRecoveryResult {
        // This would depend on the specific context
        // For now, return user action required
        return ErrorRecoveryResult(
            isResolved: false,
            requiresUserAction: true,
            userMessage: "Please generate a new payment request",
            suggestedActions: [.generateNewInvoice]
        )
    }
    
    /// Attempt recovery based on original context
    private func attemptContextualRecovery(session: ErrorRecoverySession) async -> Bool {
        switch session.context {
        case "SDK Connection":
            return await attemptSDKReconnection()
            
        case "Payment Processing":
            return await attemptPaymentRetry(session: session)
            
        case "Balance Update":
            return await attemptBalanceRefresh()
            
        default:
            return false
        }
    }
    
    /// Attempt SDK reconnection
    private func attemptSDKReconnection() async -> Bool {
        do {
            // This would call the actual reconnection logic
            // For now, simulate success/failure
            return true
        } catch {
            return false
        }
    }
    
    /// Attempt payment retry
    private func attemptPaymentRetry(session: ErrorRecoverySession) async -> Bool {
        // This would depend on the specific payment context
        // For now, return false to require user action
        return false
    }
    
    /// Attempt balance refresh
    private func attemptBalanceRefresh() async -> Bool {
        do {
            await walletManager.refreshWalletInfo()
            return true
        } catch {
            return false
        }
    }
    
    /// Calculate backoff delay
    private func calculateBackoffDelay(attempt: Int, strategy: BackoffStrategy) -> TimeInterval {
        switch strategy {
        case .none:
            return 0
        case .linear:
            return TimeInterval(attempt * 2) // 2, 4, 6 seconds
        case .exponential:
            return TimeInterval(pow(2.0, Double(attempt))) // 2, 4, 8 seconds
        }
    }
    
    /// Dismiss recovery session
    func dismissRecovery(sessionId: UUID) {
        activeRecoveries.removeAll { $0.id == sessionId }
        isRecovering = !activeRecoveries.isEmpty
    }
}

// MARK: - Data Models

struct ErrorRecoverySession: Identifiable {
    let id = UUID()
    let error: CategorizedError
    let context: String
    let strategy: RecoveryStrategy
    let createdAt: Date
    var result: ErrorRecoveryResult?
}

struct CategorizedError {
    let type: ErrorType
    let severity: ErrorSeverity
    let originalError: Error
    let userMessage: String
    let technicalDetails: String
    var suggestedActions: [SuggestedAction] = []
}

struct RecoveryStrategy {
    let type: RecoveryType
    let maxAttempts: Int
    let backoffStrategy: BackoffStrategy
    let userInteractionRequired: Bool
}

struct ErrorRecoveryResult {
    let isResolved: Bool
    let requiresUserAction: Bool
    let userMessage: String
    var suggestedActions: [SuggestedAction] = []
    var attemptsMade: Int = 0
}

enum ErrorType {
    case networkUnavailable
    case networkTimeout
    case networkGeneric
    case insufficientFunds
    case paymentExpired
    case paymentFailed
    case sdkGeneric
    case unknown
}

enum ErrorSeverity {
    case low
    case medium
    case high
    case critical
}

enum RecoveryType {
    case autoRetry
    case userAction
    case regenerate
    case manual
}

enum BackoffStrategy {
    case none
    case linear
    case exponential
}

enum SuggestedAction {
    case retryOperation
    case checkConnection
    case checkBalance
    case addFunds
    case generateNewInvoice
    case retryPayment
    case retryWhenOnline
    case contactSupport
    case refreshApp
    
    var displayText: String {
        switch self {
        case .retryOperation:
            return "Try Again"
        case .checkConnection:
            return "Check Internet Connection"
        case .checkBalance:
            return "Check Balance"
        case .addFunds:
            return "Add Funds"
        case .generateNewInvoice:
            return "Generate New Invoice"
        case .retryPayment:
            return "Retry Payment"
        case .retryWhenOnline:
            return "Retry When Online"
        case .contactSupport:
            return "Contact Support"
        case .refreshApp:
            return "Refresh App"
        }
    }
    
    var icon: String {
        switch self {
        case .retryOperation, .retryPayment, .retryWhenOnline:
            return "arrow.clockwise"
        case .checkConnection:
            return "wifi"
        case .checkBalance:
            return "creditcard"
        case .addFunds:
            return "plus.circle"
        case .generateNewInvoice:
            return "doc.badge.plus"
        case .contactSupport:
            return "questionmark.circle"
        case .refreshApp:
            return "arrow.clockwise.circle"
        }
    }
}
```

### Step 2: Enhance ErrorHandler
Update `Lumen/Utils/ErrorHandler.swift`:

```swift
// Add to existing ErrorHandler class

/// Handle error with recovery attempt
func handleErrorWithRecovery(_ error: Error, context: String) async {
    // Log error first
    logError(error, context: context)
    
    // Attempt recovery
    let result = await ErrorRecoveryManager.shared.handleError(error, context: context)
    
    if result.requiresUserAction {
        // Show user-friendly error with recovery options
        await MainActor.run {
            showErrorRecoveryUI(result: result)
        }
    }
}

/// Show error recovery UI
private func showErrorRecoveryUI(result: ErrorRecoveryResult) {
    // This would trigger showing the ErrorRecoveryView
    // Implementation depends on your navigation structure
}

/// Enhanced error categorization
func categorizeWalletError(_ error: Error) -> WalletErrorCategory {
    if let sdkError = error as? SdkError {
        return .sdk(sdkError)
    } else if let networkError = error as? URLError {
        return .network(networkError)
    } else if error.localizedDescription.contains("insufficient") {
        return .insufficientFunds
    } else if error.localizedDescription.contains("expired") {
        return .expired
    } else {
        return .unknown(error)
    }
}

enum WalletErrorCategory {
    case sdk(SdkError)
    case network(URLError)
    case insufficientFunds
    case expired
    case unknown(Error)
    
    var userFriendlyMessage: String {
        switch self {
        case .sdk(let sdkError):
            return "Payment processing error: \(sdkError.localizedDescription)"
        case .network(let networkError):
            return "Network error: \(networkError.localizedDescription)"
        case .insufficientFunds:
            return "Insufficient funds for this payment"
        case .expired:
            return "Payment request has expired"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
```

### Step 3: Create ErrorRecoveryView
Create `Lumen/Views/ErrorRecoveryView.swift`:

```swift
import SwiftUI

struct ErrorRecoveryView: View {
    let result: ErrorRecoveryResult
    let onAction: (SuggestedAction) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            // Error Message
            VStack(spacing: 8) {
                Text("Something Went Wrong")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(result.userMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Suggested Actions
            if !result.suggestedActions.isEmpty {
                VStack(spacing: 12) {
                    Text("What you can do:")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        ForEach(result.suggestedActions, id: \.self) { action in
                            SuggestedActionButton(action: action) {
                                onAction(action)
                            }
                        }
                    }
                }
            }
            
            // Dismiss Button
            Button("Dismiss") {
                onDismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct SuggestedActionButton: View {
    let action: SuggestedAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: action.icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(action.displayText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ErrorRecoveryOverlay: View {
    @StateObject private var recoveryManager = ErrorRecoveryManager.shared
    
    var body: some View {
        if let activeRecovery = recoveryManager.activeRecoveries.first,
           let result = activeRecovery.result,
           result.requiresUserAction {
            
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .overlay(
                    ErrorRecoveryView(
                        result: result,
                        onAction: { action in
                            handleSuggestedAction(action, for: activeRecovery)
                        },
                        onDismiss: {
                            recoveryManager.dismissRecovery(sessionId: activeRecovery.id)
                        }
                    )
                    .padding()
                )
        }
    }
    
    private func handleSuggestedAction(_ action: SuggestedAction, for session: ErrorRecoverySession) {
        switch action {
        case .retryOperation:
            // Retry the original operation
            Task {
                _ = await recoveryManager.attemptRecovery(session: session)
            }
            
        case .checkConnection:
            // Open Settings app to network settings
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
            
        case .addFunds:
            // Navigate to funding options
            // Implementation depends on your navigation structure
            break
            
        case .generateNewInvoice:
            // Navigate to receive payment view
            // Implementation depends on your navigation structure
            break
            
        default:
            // Handle other actions
            break
        }
        
        recoveryManager.dismissRecovery(sessionId: session.id)
    }
}
```

### Step 4: Update PaymentEventHandler
Update `Lumen/Wallet/PaymentEventHandler.swift`:

```swift
// Add enhanced error handling to existing methods

private func handlePaymentFailed(_ details: Payment) {
    let paymentInfo = createPaymentInfo(from: details, status: .failed)
    addOrUpdatePayment(paymentInfo)

    // Enhanced error handling
    if let failureReason = extractFailureReason(from: details) {
        Task {
            await ErrorRecoveryManager.shared.handleError(
                PaymentError.paymentFailed(failureReason),
                context: "Payment Processing"
            )
        }
    }

    addNotification(
        title: "Payment Failed",
        message: "Payment could not be completed. Tap for recovery options.",
        type: .error
    )
}

private func extractFailureReason(from payment: Payment) -> String? {
    // Extract failure reason from payment details
    // This would depend on the specific payment failure information available
    return nil
}

enum PaymentError: LocalizedError {
    case paymentFailed(String)
    case insufficientFunds
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .paymentFailed(let reason):
            return "Payment failed: \(reason)"
        case .insufficientFunds:
            return "Insufficient funds"
        case .networkError:
            return "Network error"
        }
    }
}
```

## Testing Strategy

### Unit Tests
```swift
func testErrorCategorization() {
    let recoveryManager = ErrorRecoveryManager.shared
    let networkError = URLError(.notConnectedToInternet)
    
    Task {
        let result = await recoveryManager.handleError(networkError, context: "Test")
        XCTAssertTrue(result.requiresUserAction)
    }
}

func testAutoRetryMechanism() {
    let recoveryManager = ErrorRecoveryManager.shared
    let timeoutError = URLError(.timedOut)
    
    Task {
        let result = await recoveryManager.handleError(timeoutError, context: "Test")
        // Verify retry attempts were made
    }
}
```

### Integration Tests
1. **Error Recovery Flow**: Test complete error recovery process
2. **User Action Handling**: Test user action execution
3. **Auto-retry Logic**: Test automatic retry mechanisms
4. **UI Integration**: Test error recovery UI display

### Manual Testing Checklist
- [ ] Network errors trigger appropriate recovery
- [ ] Payment failures show helpful guidance
- [ ] Auto-retry works for transient issues
- [ ] User actions execute correctly
- [ ] Error messages are clear and actionable

## Common Issues and Solutions

### Issue: Too many retry attempts
**Cause**: Aggressive retry strategy
**Solution**: Implement proper backoff and maximum attempt limits

### Issue: Users don't understand error messages
**Cause**: Technical error descriptions
**Solution**: Provide user-friendly explanations with clear next steps

### Issue: Recovery actions don't work
**Cause**: Incorrect action mapping
**Solution**: Test all recovery actions thoroughly

## Estimated Development Time
**2 days** for experienced iOS developer

### Breakdown:
- Day 1: ErrorRecoveryManager and enhanced error categorization
- Day 2: ErrorRecoveryView and integration testing

## Success Criteria
- [ ] All error types are properly categorized
- [ ] Automatic recovery works for transient issues
- [ ] User-friendly error messages with actionable steps
- [ ] Recovery UI is intuitive and helpful
- [ ] Error analytics provide insights for improvements

## References
- [Breez SDK Production Checklist](https://sdk-doc-liquid.breez.technology/guide/production.html)
- [iOS Error Handling Best Practices](https://developer.apple.com/documentation/swift/error_handling)
- [User Experience for Error States](https://uxdesign.cc/how-to-design-better-error-states-87c0f1e7a0b4)
