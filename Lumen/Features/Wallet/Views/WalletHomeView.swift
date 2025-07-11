import SwiftUI
import BreezSDKLiquid

/// Refactored wallet home view using new service architecture and UI components
/// This replaces the monolithic WalletView with a clean, focused implementation
struct WalletHomeView: View {
    
    // MARK: - View Models & Services
    
    @StateObject private var walletViewModel = WalletViewModel.create()
    @StateObject private var eventHandler = PaymentEventHandler.shared
    @StateObject private var errorHandler = ErrorHandler.shared
    
    // MARK: - UI State
    
    @State private var showingSendView = false
    @State private var showingReceiveView = false
    @State private var showingRefundView = false
    @State private var showingSettings = false
    @State private var showingWalletInfo = false
    @State private var refundableSwapsCount = 0
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Main content
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.card) {
                        // Balance card
                        WalletBalanceCard(
                            balance: walletViewModel.balance,
                            isLoading: walletViewModel.isLoadingBalance,
                            onInfoTap: { showingWalletInfo = true }
                        )
                        
                        // Action buttons
                        WalletActionButtons(
                            onSendTap: { showingSendView = true },
                            onReceiveTap: { showingReceiveView = true }
                        )
                        .enabled(walletViewModel.isConnected && !walletViewModel.isAnyOperationInProgress)
                        
                        // Refund notification
                        RefundNotificationCard(
                            refundCount: refundableSwapsCount,
                            onTap: { showingRefundView = true },
                            onDismiss: { refundableSwapsCount = 0 }
                        )
                        
                        // Bitcoin places
                        SmartNearbyPlacesCard()
                        
                        // Transaction history
                        EnhancedTransactionHistoryView()
                    }
                    .padding(.top, DesignSystem.Spacing.md)
                }
                .refreshable {
                    await refreshWalletData()
                }
                
                // Payment success overlay
                if eventHandler.showPaymentSuccess, let payment = eventHandler.lastSuccessfulPayment {
                    PaymentSuccessOverlay(payment: payment) {
                        eventHandler.dismissSuccessFeedback()
                    }
                }
            }
            .navigationTitle("Lumen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    walletToolbar
                }
            }
            .onAppear {
                Task {
                    await initializeWallet()
                    await checkRefundableSwaps()
                }
            }
        }
        .sheet(isPresented: $showingSendView) {
            // TODO: Implement SendPaymentSheet
            Text("Send Payment Sheet")
        }
        .sheet(isPresented: $showingReceiveView) {
            // TODO: Implement ReceivePaymentSheet
            Text("Receive Payment Sheet")
        }
        .sheet(isPresented: $showingRefundView) {
            // TODO: Implement RefundManagementView
            Text("Refund Management View")
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingWalletInfo) {
            WalletInfoView()
        }
        .errorAlert(errorHandler: errorHandler)
    }
    
    // MARK: - Toolbar
    
    @ViewBuilder
    private var walletToolbar: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Connection status
            ConnectionStatusIcon()
            
            // Refund badge (if any)
            CompactRefundBadge(
                refundCount: refundableSwapsCount,
                onTap: { showingRefundView = true }
            )
            
            // Settings button
            Button(action: { showingSettings = true }) {
                Image(systemName: DesignSystem.Icons.settings)
                    .font(DesignSystem.Typography.title3(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
        }
    }
    
    // MARK: - Wallet Operations
    
    private func initializeWallet() async {
        // Try to initialize from cache first for fast startup
        let cacheSuccess = await walletViewModel.initializeFromCache()
        
        if !cacheSuccess {
            // Fall back to full initialization
            await walletViewModel.initializeWallet()
        }
    }
    
    private func refreshWalletData() async {
        await walletViewModel.loadWalletData()
    }
    
    private func checkRefundableSwaps() async {
        // This would use the refund service to check for refundable swaps
        // For now, simplified implementation
        do {
            // Placeholder for refund checking logic
            refundableSwapsCount = 0
        } catch {
            print("Failed to check refundable swaps: \(error)")
        }
    }
}



// MARK: - Payment Success Overlay

/// Payment success overlay component
struct PaymentSuccessOverlay: View {
    let payment: PaymentEventHandler.PaymentInfo
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Success card
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Success icon
                Image(systemName: DesignSystem.Icons.success)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.success)
                
                // Success message
                Text(successMessage)
                    .font(DesignSystem.Typography.title2(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Amount
                AmountDisplayCard.payment(
                    payment.amountSat,
                    title: nil,
                    isReceived: payment.direction == .incoming
                )
                .style(.success)
                .size(.large)
                
                // Continue button
                StandardButton(title: "Continue", action: onDismiss)
                    .style(.success)
                    .size(.large)
            }
            .standardPadding()
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .fill(DesignSystem.Colors.backgroundPrimary)
                    .heavyShadow()
            )
            .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(DesignSystem.Animation.spring, value: true)
    }
    
    private var successMessage: String {
        switch payment.direction {
        case .outgoing:
            return "Payment Sent!"
        case .incoming:
            return "Payment Received!"
        }
    }
}

// MARK: - Preview

#Preview {
    WalletHomeView()
}
