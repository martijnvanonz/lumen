import SwiftUI
import BreezSDKLiquid

// MARK: - Payment Status Badge

struct PaymentStatusBadge: View {
    let status: PaymentStatus
    let size: BadgeSize
    
    enum BadgeSize {
        case small, medium, large
        
        var fontSize: Font {
            switch self {
            case .small: return AppTheme.Typography.caption2
            case .medium: return AppTheme.Typography.caption
            case .large: return AppTheme.Typography.subheadline
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            }
        }
    }
    
    init(status: PaymentStatus, size: BadgeSize = .medium) {
        self.status = status
        self.size = size
    }
    
    var body: some View {
        Text(status.displayName)
            .font(size.fontSize)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(size.padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(status.color)
            )
    }
}

// MARK: - Payment Amount View

struct PaymentAmountView: View {
    let amount: UInt64
    let type: PaymentType
    let showPrefix: Bool
    let fontSize: Font
    let showUSD: Bool
    
    init(
        amount: UInt64,
        type: PaymentType,
        showPrefix: Bool = true,
        fontSize: Font = AppTheme.Typography.subheadline,
        showUSD: Bool = false
    ) {
        self.amount = amount
        self.type = type
        self.showPrefix = showPrefix
        self.fontSize = fontSize
        self.showUSD = showUSD
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 2) {
                if showPrefix {
                    Text(type == .send ? "-" : "+")
                        .font(fontSize)
                        .foregroundColor(type.color)
                }
                
                Text("\(amount)")
                    .font(fontSize)
                    .fontWeight(.semibold)
                    .foregroundColor(type.color)
                
                Text("sats")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if showUSD {
                Text("≈ $\(formattedUSDValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var formattedUSDValue: String {
        // Simplified USD conversion - in production use real exchange rates
        let usdValue = Double(amount) * 0.00045 // ~$45k BTC price
        return String(format: "%.2f", usdValue)
    }
}

// MARK: - Payment Row View

struct PaymentRowView: View {
    let payment: Payment
    let showDetails: Bool
    let onTap: (() -> Void)?
    
    init(payment: Payment, showDetails: Bool = true, onTap: (() -> Void)? = nil) {
        self.payment = payment
        self.showDetails = showDetails
        self.onTap = onTap
    }
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                // Status indicator
                StatusIndicator(
                    status: statusIndicatorType,
                    size: 40,
                    showAnimation: payment.status == .pending
                )
                
                // Payment info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(payment.paymentType.displayName)
                            .font(AppTheme.Typography.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        PaymentStatusBadge(status: payment.status, size: .small)
                    }
                    
                    if showDetails {
                        if let description = payment.description, !description.isEmpty {
                            Text(description)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Text(timestampText)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Amount
                PaymentAmountView(
                    amount: payment.amountSat,
                    type: payment.paymentType,
                    fontSize: AppTheme.Typography.subheadline
                )
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.cardBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusIndicatorType: StatusIndicator.StatusType {
        switch payment.status {
        case .complete: return .success
        case .failed, .timedOut: return .error
        case .pending, .refundPending: return .loading
        case .refundable: return .warning
        default: return .info
        }
    }
    
    private var timestampText: String {
        let date = Date(timeIntervalSince1970: TimeInterval(payment.timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Fee Display View

struct FeeDisplayView: View {
    let feeSats: UInt64
    let amountSats: UInt64
    let style: DisplayStyle
    
    enum DisplayStyle {
        case compact, detailed, comparison
    }
    
    init(feeSats: UInt64, amountSats: UInt64, style: DisplayStyle = .compact) {
        self.feeSats = feeSats
        self.amountSats = amountSats
        self.style = style
    }
    
    var body: some View {
        switch style {
        case .compact:
            compactView
        case .detailed:
            detailedView
        case .comparison:
            comparisonView
        }
    }
    
    private var compactView: some View {
        HStack(spacing: 4) {
            Text("\(feeSats) sats")
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)
            
            Text("(\(feePercentage)%)")
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var detailedView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Network Fee")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(feeSats) sats")
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Fee Rate")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(feePercentage)% of payment")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var comparisonView: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: AppTheme.Icons.lightning)
                    .foregroundColor(AppTheme.Colors.lightning)
                
                Text("Lightning Network")
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)
                
                Text("RECOMMENDED")
                    .font(AppTheme.Typography.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.Colors.success)
                    .cornerRadius(4)
                
                Spacer()
                
                Text("\(feeSats) sats")
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.lightning)
            }
            
            Text("Only \(feePercentage)% fee vs 3% for credit cards")
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle(
            backgroundColor: AppTheme.Colors.lightning.opacity(0.05),
            borderColor: AppTheme.Colors.lightning.opacity(0.2)
        )
    }
    
    private var feePercentage: String {
        guard amountSats > 0 else { return "0.00" }
        let percentage = (Double(feeSats) / Double(amountSats)) * 100
        return String(format: "%.2f", percentage)
    }
}

// MARK: - Payment Input Info Card

struct PaymentInputInfoCard: View {
    let paymentInfo: PaymentInputInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header with type and icon
            HStack {
                Image(systemName: paymentInfo.type.icon)
                    .foregroundColor(paymentInfo.type.color)
                
                Text(paymentInfo.type.displayName)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(paymentInfo.type.color)
                
                Spacer()
                
                if paymentInfo.isExpired {
                    PaymentStatusBadge(status: .timedOut, size: .small)
                }
            }
            
            // Payment details
            VStack(spacing: AppTheme.Spacing.sm) {
                if let amount = paymentInfo.amount {
                    InfoRow(
                        label: "Amount",
                        value: "\(amount) sats",
                        valueColor: .primary
                    )
                }
                
                if let description = paymentInfo.description, !description.isEmpty {
                    InfoRow(
                        label: "Description",
                        value: description,
                        valueColor: .primary
                    )
                }
                
                if let destination = paymentInfo.destination {
                    InfoRow(
                        label: "To",
                        value: destination.count > 20 ? "\(destination.prefix(20))..." : destination,
                        valueColor: .secondary,
                        copyable: true
                    )
                }
                
                if let expiry = paymentInfo.expiry {
                    InfoRow(
                        label: "Expires",
                        value: expiry.formatted(.relative(presentation: .named)),
                        valueColor: paymentInfo.isExpired ? AppTheme.Colors.error : .primary
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle(
            borderColor: paymentInfo.type.color.opacity(0.3)
        )
    }
}

// MARK: - Extensions

extension PaymentStatus {
    var displayName: String {
        switch self {
        case .created: return "Created"
        case .pending: return "Pending"
        case .complete: return "Complete"
        case .failed: return "Failed"
        case .timedOut: return "Expired"
        case .refundable: return "Refundable"
        case .refundPending: return "Refund Pending"
        case .waitingFeeAcceptance: return "Fee Approval"
        }
    }
}

extension PaymentType {
    var displayName: String {
        switch self {
        case .send: return "Sent"
        case .receive: return "Received"
        }
    }
}
