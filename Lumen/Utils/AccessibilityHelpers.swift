import SwiftUI

// MARK: - Accessibility Helpers

struct AccessibilityHelpers {
    
    // MARK: - Payment Accessibility
    
    /// Create accessible label for payment amount
    static func paymentAmountLabel(amount: UInt64, type: PaymentType) -> String {
        let direction = type == .send ? "sent" : "received"
        return "\(amount) satoshis \(direction)"
    }
    
    /// Create accessible label for payment status
    static func paymentStatusLabel(status: PaymentStatus) -> String {
        switch status {
        case .created: return "Payment created"
        case .pending: return "Payment pending"
        case .complete: return "Payment completed"
        case .failed: return "Payment failed"
        case .timedOut: return "Payment timed out"
        case .refundable: return "Payment refundable"
        case .refundPending: return "Refund pending"
        case .waitingFeeAcceptance: return "Waiting for fee acceptance"
        }
    }
    
    /// Create accessible hint for payment actions
    static func paymentActionHint(for action: String) -> String {
        switch action.lowercased() {
        case "send": return "Double tap to send payment"
        case "receive": return "Double tap to create payment request"
        case "copy": return "Double tap to copy to clipboard"
        case "share": return "Double tap to share payment details"
        default: return "Double tap to \(action)"
        }
    }
    
    // MARK: - Network Accessibility
    
    /// Create accessible label for network status
    static func networkStatusLabel(isConnected: Bool, type: NetworkMonitor.ConnectionType) -> String {
        if !isConnected {
            return "No internet connection"
        }
        
        switch type {
        case .wifi: return "Connected via Wi-Fi"
        case .cellular: return "Connected via cellular"
        case .ethernet: return "Connected via ethernet"
        case .other: return "Connected to internet"
        case .none: return "No internet connection"
        }
    }
    
    /// Create accessible hint for network actions
    static func networkActionHint() -> String {
        return "Double tap to retry connection"
    }
    
    // MARK: - Balance Accessibility
    
    /// Create accessible label for wallet balance
    static func balanceLabel(amount: UInt64) -> String {
        return "Wallet balance: \(amount) satoshis"
    }
    
    /// Create accessible hint for balance actions
    static func balanceActionHint() -> String {
        return "Double tap to view wallet details"
    }
    
    // MARK: - Button Accessibility
    
    /// Create accessible label for action buttons
    static func actionButtonLabel(title: String, isEnabled: Bool) -> String {
        let status = isEnabled ? "enabled" : "disabled"
        return "\(title) button, \(status)"
    }
    
    /// Create accessible hint for buttons
    static func buttonHint(action: String) -> String {
        return "Double tap to \(action)"
    }
    
    // MARK: - Form Accessibility
    
    /// Create accessible label for text fields
    static func textFieldLabel(title: String, isRequired: Bool) -> String {
        let requirement = isRequired ? "required" : "optional"
        return "\(title), \(requirement) text field"
    }
    
    /// Create accessible hint for text fields
    static func textFieldHint(placeholder: String) -> String {
        return "Enter \(placeholder)"
    }
    
    // MARK: - Loading Accessibility
    
    /// Create accessible label for loading states
    static func loadingLabel(text: String) -> String {
        return "Loading: \(text)"
    }
    
    // MARK: - Error Accessibility
    
    /// Create accessible label for error states
    static func errorLabel(message: String) -> String {
        return "Error: \(message)"
    }
    
    /// Create accessible hint for error recovery
    static func errorRecoveryHint() -> String {
        return "Double tap to try again"
    }
}

// MARK: - Accessibility View Modifiers

struct AccessiblePaymentRow: ViewModifier {
    let payment: Payment
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Double tap to view payment details")
            .accessibilityAddTraits(.isButton)
    }
    
    private var accessibilityLabel: String {
        let amount = AccessibilityHelpers.paymentAmountLabel(
            amount: payment.amountSat,
            type: payment.paymentType
        )
        let status = AccessibilityHelpers.paymentStatusLabel(status: payment.status)
        let timestamp = payment.timestamp > 0 ? 
            Date(timeIntervalSince1970: TimeInterval(payment.timestamp)).relativeFormatted() : 
            "unknown time"
        
        return "\(amount), \(status), \(timestamp)"
    }
}

struct AccessibleButton: ViewModifier {
    let label: String
    let hint: String
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(AccessibilityHelpers.actionButtonLabel(title: label, isEnabled: isEnabled))
            .accessibilityHint(hint)
            .accessibilityAddTraits(.isButton)
            .if(!isEnabled) { view in
                view.accessibilityAddTraits(.isNotEnabled)
            }
    }
}

struct AccessibleTextField: ViewModifier {
    let label: String
    let placeholder: String
    let isRequired: Bool
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(AccessibilityHelpers.textFieldLabel(title: label, isRequired: isRequired))
            .accessibilityHint(AccessibilityHelpers.textFieldHint(placeholder: placeholder))
    }
}

struct AccessibleBalance: ViewModifier {
    let amount: UInt64
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AccessibilityHelpers.balanceLabel(amount: amount))
            .accessibilityHint(AccessibilityHelpers.balanceActionHint())
            .accessibilityAddTraits(.isButton)
    }
}

struct AccessibleNetworkStatus: ViewModifier {
    let isConnected: Bool
    let connectionType: NetworkMonitor.ConnectionType
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(AccessibilityHelpers.networkStatusLabel(
                isConnected: isConnected,
                type: connectionType
            ))
            .if(!isConnected) { view in
                view.accessibilityHint(AccessibilityHelpers.networkActionHint())
                    .accessibilityAddTraits(.isButton)
            }
    }
}

struct AccessibleLoadingState: ViewModifier {
    let text: String
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AccessibilityHelpers.loadingLabel(text: text))
            .accessibilityAddTraits(.updatesFrequently)
    }
}

struct AccessibleErrorState: ViewModifier {
    let message: String
    let hasRetryAction: Bool
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AccessibilityHelpers.errorLabel(message: message))
            .if(hasRetryAction) { view in
                view.accessibilityHint(AccessibilityHelpers.errorRecoveryHint())
                    .accessibilityAddTraits(.isButton)
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Make payment row accessible
    func accessiblePaymentRow(payment: Payment) -> some View {
        modifier(AccessiblePaymentRow(payment: payment))
    }
    
    /// Make button accessible
    func accessibleButton(
        label: String,
        hint: String,
        isEnabled: Bool = true
    ) -> some View {
        modifier(AccessibleButton(label: label, hint: hint, isEnabled: isEnabled))
    }
    
    /// Make text field accessible
    func accessibleTextField(
        label: String,
        placeholder: String,
        isRequired: Bool = false
    ) -> some View {
        modifier(AccessibleTextField(label: label, placeholder: placeholder, isRequired: isRequired))
    }
    
    /// Make balance accessible
    func accessibleBalance(amount: UInt64) -> some View {
        modifier(AccessibleBalance(amount: amount))
    }
    
    /// Make network status accessible
    func accessibleNetworkStatus(
        isConnected: Bool,
        connectionType: NetworkMonitor.ConnectionType
    ) -> some View {
        modifier(AccessibleNetworkStatus(isConnected: isConnected, connectionType: connectionType))
    }
    
    /// Make loading state accessible
    func accessibleLoadingState(text: String) -> some View {
        modifier(AccessibleLoadingState(text: text))
    }
    
    /// Make error state accessible
    func accessibleErrorState(message: String, hasRetryAction: Bool = false) -> some View {
        modifier(AccessibleErrorState(message: message, hasRetryAction: hasRetryAction))
    }
    
    /// Add semantic accessibility traits
    func accessibilityPaymentAmount() -> some View {
        self.accessibilityAddTraits(.isStaticText)
            .accessibilityRemoveTraits(.isButton)
    }
    
    /// Add navigation accessibility traits
    func accessibilityNavigation() -> some View {
        self.accessibilityAddTraits(.isButton)
            .accessibilityHint("Double tap to navigate")
    }
    
    /// Add toggle accessibility traits
    func accessibilityToggle(isOn: Bool) -> some View {
        self.accessibilityAddTraits(.isToggle)
            .accessibilityValue(isOn ? "On" : "Off")
    }
    
    /// Add progress accessibility traits
    func accessibilityProgress(value: Double, total: Double = 1.0) -> some View {
        self.accessibilityAddTraits(.updatesFrequently)
            .accessibilityValue("\(Int((value / total) * 100)) percent")
    }
    
    /// Add currency accessibility traits
    func accessibilityCurrency(amount: UInt64, currency: String = "satoshis") -> some View {
        self.accessibilityLabel("\(amount) \(currency)")
            .accessibilityAddTraits(.isStaticText)
    }
    
    /// Add timestamp accessibility traits
    func accessibilityTimestamp(_ date: Date) -> some View {
        self.accessibilityLabel(date.relativeFormatted())
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Accessibility Constants

struct AccessibilityConstants {
    static let minimumTouchTarget: CGFloat = 44
    static let preferredTouchTarget: CGFloat = 48
    static let minimumContrast: Double = 4.5
    static let preferredContrast: Double = 7.0
    
    struct VoiceOver {
        static let shortPause = "."
        static let mediumPause = ".."
        static let longPause = "..."
    }
    
    struct Announcements {
        static let paymentSent = "Payment sent successfully"
        static let paymentReceived = "Payment received"
        static let paymentFailed = "Payment failed"
        static let connectionLost = "Internet connection lost"
        static let connectionRestored = "Internet connection restored"
        static let walletSynced = "Wallet synchronized"
    }
}

// MARK: - Dynamic Type Support

extension View {
    /// Support dynamic type scaling
    func dynamicTypeSize(_ range: ClosedRange<DynamicTypeSize> = .xSmall...(.accessibility5)) -> some View {
        self.dynamicTypeSize(range)
    }
    
    /// Limit dynamic type scaling for specific elements
    func limitDynamicType() -> some View {
        self.dynamicTypeSize(.large...(.accessibility1))
    }
    
    /// Scale with dynamic type but maintain minimum size
    func scaledToFit(minimum: CGFloat = 16) -> some View {
        self.font(.system(size: max(minimum, UIFont.preferredFont(forTextStyle: .body).pointSize)))
    }
}
