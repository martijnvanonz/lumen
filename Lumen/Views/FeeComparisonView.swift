import SwiftUI
import BreezSDKLiquid

struct FeeComparisonView: View {
    let lightningFeeSats: UInt64
    let paymentAmountSats: UInt64

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Fee Comparison")
                .font(DesignSystem.Typography.headline())
                .foregroundColor(DesignSystem.Colors.textPrimary)

            VStack(spacing: DesignSystem.Spacing.component) {
                // Lightning Network fee
                FeeComparisonRow(
                    title: "Lightning Network",
                    fee: lightningFeeSats,
                    amount: paymentAmountSats,
                    color: AppConstants.Colors.lightning,
                    icon: DesignSystem.Icons.lightning,
                    isRecommended: true
                )

                // Traditional payment comparisons
                FeeComparisonRow(
                    title: "Credit Card (\(String(format: "%.1f", AppConstants.Fees.creditCardRate * 100))%)",
                    fee: calculateCreditCardFee(for: paymentAmountSats),
                    amount: paymentAmountSats,
                    color: DesignSystem.Colors.info,
                    icon: "creditcard.fill"
                )

                FeeComparisonRow(
                    title: "Bank Wire ($\(String(format: "%.0f", AppConstants.Fees.bankWireFee)))",
                    fee: calculateBankWireFee(),
                    amount: paymentAmountSats,
                    color: DesignSystem.Colors.textSecondary,
                    icon: "building.columns.fill"
                )

                FeeComparisonRow(
                    title: "PayPal (\(String(format: "%.1f", AppConstants.Fees.paypalRate * 100))% + $\(String(format: "%.2f", AppConstants.Fees.paypalFixedFee)))",
                    fee: calculatePayPalFee(for: paymentAmountSats),
                    amount: paymentAmountSats,
                    color: Color.purple,
                    icon: "p.circle.fill"
                )
            }

            // Savings summary
            let creditCardFee = calculateCreditCardFee(for: paymentAmountSats)
            if lightningFeeSats < creditCardFee {
                let savings = creditCardFee - lightningFeeSats
                let savingsPercentage = Double(savings) / Double(creditCardFee) * 100

                HStack {
                    Image(systemName: DesignSystem.Icons.success)
                        .foregroundColor(DesignSystem.Colors.success)

                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Save")
                            .font(DesignSystem.Typography.caption(weight: .medium))
                            .foregroundColor(DesignSystem.Colors.success)

                        SatsAmountView(
                            amount: savings,
                            displayMode: .satsOnly,
                            size: .compact,
                            style: .success
                        )

                        Text("(\(String(format: "%.1f", savingsPercentage))%) vs credit cards")
                            .font(DesignSystem.Typography.caption(weight: .medium))
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
                .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .standardPadding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundTertiary)
        )
    }

    // MARK: - Fee Calculation Methods

    private func calculateCreditCardFee(for amount: UInt64) -> UInt64 {
        return UInt64(Double(amount) * AppConstants.Fees.creditCardRate)
    }

    private func calculateBankWireFee() -> UInt64 {
        let satsPerDollar = 100_000_000 / AppConstants.Fees.btcPriceForCalculation
        return UInt64(AppConstants.Fees.bankWireFee * satsPerDollar)
    }

    private func calculatePayPalFee(for amount: UInt64) -> UInt64 {
        let percentageFee = Double(amount) * AppConstants.Fees.paypalRate
        let satsPerDollar = 100_000_000 / AppConstants.Fees.btcPriceForCalculation
        let fixedFee = AppConstants.Fees.paypalFixedFee * satsPerDollar
        return UInt64(percentageFee + fixedFee)
    }
}

struct FeeComparisonRow: View {
    let title: String
    let fee: UInt64
    let amount: UInt64
    let color: Color
    let icon: String
    let isRecommended: Bool

    init(title: String, fee: UInt64, amount: UInt64, color: Color, icon: String, isRecommended: Bool = false) {
        self.title = title
        self.fee = fee
        self.amount = amount
        self.color = color
        self.icon = icon
        self.isRecommended = isRecommended
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.component) {
            // Icon
            Image(systemName: icon)
                .font(DesignSystem.Typography.title3())
                .foregroundColor(color)
                .frame(width: DesignSystem.Icons.sizeLarge)

            // Payment method info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs / 2) {
                HStack {
                    Text(title)
                        .font(DesignSystem.Typography.subheadline(weight: .medium))

                    if isRecommended {
                        Text("RECOMMENDED")
                            .font(DesignSystem.Typography.caption(weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.xs + 2)
                            .padding(.vertical, DesignSystem.Spacing.xs / 2)
                            .background(DesignSystem.Colors.success)
                            .cornerRadius(DesignSystem.CornerRadius.sm / 2)
                    }
                }

                HStack(spacing: DesignSystem.Spacing.xs) {
                    SatsAmountView(
                        amount: fee,
                        displayMode: .satsOnly,
                        size: .compact,
                        style: .secondary
                    )
                    Text("(\(feePercentage)%)")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()

            // Fee amount
            SatsAmountView(
                amount: fee,
                displayMode: .satsOnly,
                size: .regular,
                style: .primary
            )
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(isRecommended ? color.opacity(0.1) : Color.clear)
        )
    }

    private var feePercentage: String {
        let percentage = Double(fee) / Double(amount) * 100
        return String(format: "%.2f", percentage)
    }
}

// MARK: - Fee Education View

struct FeeEducationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Why Lightning Fees Are Lower")
                .font(DesignSystem.Typography.headline())

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.component) {
                EducationPoint(
                    icon: DesignSystem.Icons.network,
                    title: "Direct Peer-to-Peer",
                    description: "No intermediary banks or payment processors taking cuts"
                )

                EducationPoint(
                    icon: DesignSystem.Icons.lightning,
                    title: "Instant Settlement",
                    description: "No waiting periods or clearing houses to pay"
                )

                EducationPoint(
                    icon: "globe",
                    title: "Global Network",
                    description: "Same low fees whether paying locally or internationally"
                )

                EducationPoint(
                    icon: "lock.shield.fill",
                    title: "Cryptographic Security",
                    description: "No fraud protection fees - math guarantees security"
                )
            }
        }
        .standardPadding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundSecondary)
        )
    }
}

struct EducationPoint: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.component) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.title3())
                .foregroundColor(DesignSystem.Colors.info)
                .frame(width: DesignSystem.Icons.sizeLarge)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.subheadline(weight: .semibold))

                Text(description)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Fee Breakdown View

struct FeeBreakdownView: View {
    let preparedPayment: PrepareSendResponse

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.component) {
            Text("Fee Breakdown")
                .font(DesignSystem.Typography.headline())

            VStack(spacing: DesignSystem.Spacing.sm) {
                FeeBreakdownRow(
                    label: "Base Fee",
                    amount: (preparedPayment.feesSat ?? 0) / 2, // Simplified breakdown
                    description: "Fixed cost per transaction"
                )

                FeeBreakdownRow(
                    label: "Routing Fee",
                    amount: (preparedPayment.feesSat ?? 0) / 2,
                    description: "Cost to route through Lightning Network"
                )

                Divider()
                    .background(DesignSystem.Colors.borderPrimary)

                FeeBreakdownRow(
                    label: "Total Lightning Fee",
                    amount: preparedPayment.feesSat ?? 0,
                    description: "All fees included",
                    isTotal: true
                )
            }
        }
        .standardPadding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundTertiary)
        )
    }
}

struct FeeBreakdownRow: View {
    let label: String
    let amount: UInt64
    let description: String
    let isTotal: Bool

    init(label: String, amount: UInt64, description: String, isTotal: Bool = false) {
        self.label = label
        self.amount = amount
        self.description = description
        self.isTotal = isTotal
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(label)
                    .font(isTotal ? DesignSystem.Typography.subheadline(weight: .semibold) : DesignSystem.Typography.caption(weight: .medium))

                Spacer()

                SatsAmountView(
                    amount: amount,
                    displayMode: .satsOnly,
                    size: isTotal ? .regular : .compact,
                    style: isTotal ? .primary : .secondary
                )
            }

            if !description.isEmpty {
                HStack {
                    Text(description)
                        .font(DesignSystem.Typography.caption(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)

                    Spacer()
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FeeComparisonView(
            lightningFeeSats: 50,
            paymentAmountSats: 100000
        )
        
        FeeEducationView()
        
        // Mock PrepareSendResponse for preview
        // FeeBreakdownView(preparedPayment: mockPrepareSendResponse)
    }
    .padding()
}
