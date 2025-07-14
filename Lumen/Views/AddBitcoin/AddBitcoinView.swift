import SwiftUI

struct AddBitcoinView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingReceiveOnchain = false
    @State private var showingReceiveLiquid = false
    @State private var showingBuyBitcoin = false

    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.card) {
                // Header
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Add Bitcoin")
                        .font(DesignSystem.Typography.largeTitle())

                    Text("Transfer from your exchange or buy instantly")
                        .font(DesignSystem.Typography.subheadline())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, DesignSystem.Spacing.md)

                // Options
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Receive Bitcoin (Onchain)
                    AddBitcoinOptionCard(
                        title: "Receive Bitcoin",
                        subtitle: "From exchange or wallet (onchain)",
                        icon: DesignSystem.Icons.bitcoin,
                        iconColor: AppConstants.Colors.bitcoin,
                        action: {
                            showingReceiveOnchain = true
                        }
                    )

                    // Receive Liquid Bitcoin
                    AddBitcoinOptionCard(
                        title: "Receive Liquid Bitcoin",
                        subtitle: "From exchange or wallet (liquid)",
                        icon: "drop.circle.fill",
                        iconColor: AppConstants.Colors.liquid,
                        action: {
                            showingReceiveLiquid = true
                        }
                    )

                    // Buy Bitcoin
                    AddBitcoinOptionCard(
                        title: "Buy Bitcoin",
                        subtitle: "Purchase directly with fiat via Moonpay",
                        icon: "creditcard.circle.fill",
                        iconColor: DesignSystem.Colors.success,
                        action: {
                            showingBuyBitcoin = true
                        }
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.md)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingReceiveOnchain) {
            ReceiveOnchainView()
        }
        .sheet(isPresented: $showingReceiveLiquid) {
            ReceiveLiquidView()
        }
        .sheet(isPresented: $showingBuyBitcoin) {
            BuyBitcoinView()
        }
    }
}

// MARK: - Add Bitcoin Option Card

struct AddBitcoinOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icon
                Image(systemName: icon)
                    .font(DesignSystem.Typography.title())
                    .foregroundColor(iconColor)
                    .frame(width: AppConstants.UI.iconSizeXLarge + 8, height: AppConstants.UI.iconSizeXLarge + 8)

                // Text content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(DesignSystem.Typography.subheadline())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.subheadline())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.lg - 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(iconColor.opacity(0.2), lineWidth: AppConstants.UI.borderWidthThin)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    AddBitcoinView()
}
