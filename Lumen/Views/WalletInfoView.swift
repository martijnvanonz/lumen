import SwiftUI
import BreezSDKLiquid

struct WalletInfoView: View {
    @StateObject private var walletManager = WalletManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var walletInfo: GetInfoResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    if isLoading {
                        LoadingView(text: "Loading wallet information...")
                    } else if let walletInfo = walletInfo {
                        WalletDetailsView(walletInfo: walletInfo)
                    } else if let errorMessage = errorMessage {
                        EmptyStateView(
                            icon: AppTheme.Icons.error,
                            title: "Error Loading Info",
                            message: errorMessage,
                            actionTitle: "Try Again"
                        ) {
                            Task { await loadWalletInfo() }
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .standardToolbar(
                title: "Wallet Info",
                displayMode: .large,
                showsDoneButton: true,
                showsRefreshButton: true,
                onDone: { dismiss() },
                onRefresh: { Task { await loadWalletInfo() } }
            )
            .refreshable {
                await loadWalletInfo()
            }
            .onAppear {
                Task { await loadWalletInfo() }
            }
        }
    }
    
    private func loadWalletInfo() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let info = try await walletManager.getWalletInfo()
            await MainActor.run {
                walletInfo = info
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Wallet Details View

struct WalletDetailsView: View {
    let walletInfo: GetInfoResponse
    
    var body: some View {
        VStack(spacing: 20) {
            // Connection Status
            ConnectionStatusCard(walletInfo: walletInfo)
            
            // Node Information
            NodeInfoCard(walletInfo: walletInfo)
            
            // Balance Information
            BalanceInfoCard(walletInfo: walletInfo)
            
            // Network Information
            NetworkInfoCard(walletInfo: walletInfo)
            
            // Limits Information
            LimitsInfoCard(walletInfo: walletInfo)

            // Debug Section (Development only)
            DebugActionsCard()
        }
    }
}

// MARK: - Connection Status Card

struct ConnectionStatusCard: View {
    let walletInfo: GetInfoResponse
    
    var body: some View {
        InfoCard(
            title: "Connection Status",
            icon: "wifi",
            iconColor: .green
        ) {
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    label: "Status",
                    value: "Connected",
                    valueColor: .green
                )
                
                InfoRow(
                    label: "Liquid Tip",
                    value: "\(walletInfo.blockchainInfo.liquidTip)"
                )
                
                if walletInfo.walletInfo.pendingReceiveSat > 0 {
                    InfoRow(
                        label: "Pending Receive",
                        value: "\(walletInfo.walletInfo.pendingReceiveSat) sats",
                        valueColor: .orange
                    )
                }
                
                if walletInfo.walletInfo.pendingSendSat > 0 {
                    InfoRow(
                        label: "Pending Send",
                        value: "\(walletInfo.walletInfo.pendingSendSat) sats",
                        valueColor: .orange
                    )
                }
            }
        }
    }
}

// MARK: - Node Information Card

struct NodeInfoCard: View {
    let walletInfo: GetInfoResponse
    
    var body: some View {
        InfoCard(
            title: "Node Information",
            icon: "server.rack",
            iconColor: .blue
        ) {
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    label: "Node ID",
                    value: walletInfo.walletInfo.pubkey,
                    isMonospace: true,
                    isCopyable: true
                )
            }
        }
    }
}

// MARK: - Balance Information Card

struct BalanceInfoCard: View {
    let walletInfo: GetInfoResponse
    
    var body: some View {
        InfoCard(
            title: "Balance Details",
            icon: "bitcoinsign.circle",
            iconColor: .orange
        ) {
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    label: "Total Balance",
                    value: "\(walletInfo.walletInfo.balanceSat) sats",
                    valueColor: .primary,
                    isHighlighted: true
                )
                
                if walletInfo.walletInfo.pendingReceiveSat > 0 {
                    InfoRow(
                        label: "Pending Receive",
                        value: "\(walletInfo.walletInfo.pendingReceiveSat) sats",
                        valueColor: .green
                    )
                }
                
                if walletInfo.walletInfo.pendingSendSat > 0 {
                    InfoRow(
                        label: "Pending Send",
                        value: "\(walletInfo.walletInfo.pendingSendSat) sats",
                        valueColor: .orange
                    )
                }
            }
        }
    }
}

// MARK: - Network Information Card

struct NetworkInfoCard: View {
    let walletInfo: GetInfoResponse
    
    var body: some View {
        InfoCard(
            title: "Network Information",
            icon: "globe",
            iconColor: .purple
        ) {
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    label: "Bitcoin Tip",
                    value: "\(walletInfo.blockchainInfo.bitcoinTip)"
                )

                InfoRow(
                    label: "Liquid Tip",
                    value: "\(walletInfo.blockchainInfo.liquidTip)"
                )
            }
        }
    }
}

// MARK: - Limits Information Card

struct LimitsInfoCard: View {
    let walletInfo: GetInfoResponse
    
    var body: some View {
        InfoCard(
            title: "Payment Limits",
            icon: "gauge",
            iconColor: .red
        ) {
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    label: "Status",
                    value: "Limits available via API"
                )

                // TODO: Implement limits fetching using fetchLightningLimits() and fetchOnchainLimits()
                Text("Payment limits can be fetched using dedicated API calls")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Reusable Components

struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(iconColor)
            }
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(iconColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let valueColor: Color
    let isMonospace: Bool
    let isCopyable: Bool
    let isHighlighted: Bool
    
    init(
        label: String,
        value: String,
        valueColor: Color = .secondary,
        isMonospace: Bool = false,
        isCopyable: Bool = false,
        isHighlighted: Bool = false
    ) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.isMonospace = isMonospace
        self.isCopyable = isCopyable
        self.isHighlighted = isHighlighted
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(isHighlighted ? .subheadline : .caption)
                    .fontWeight(isHighlighted ? .semibold : .medium)
                    .foregroundColor(isHighlighted ? .primary : .secondary)
                
                Spacer()
                
                if isCopyable {
                    Button(action: {
                        UIPasteboard.general.string = value
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Group {
                if isCopyable {
                    Text(value)
                        .font(isHighlighted ? .headline : .subheadline)
                        .fontWeight(isHighlighted ? .semibold : .regular)
                        .font(isMonospace ? .system(.subheadline, design: .monospaced) : .subheadline)
                        .foregroundStyle(valueColor)
                        .textSelection(.enabled)
                        .lineLimit(isMonospace ? nil : 1)
                } else {
                    Text(value)
                        .font(isHighlighted ? .headline : .subheadline)
                        .fontWeight(isHighlighted ? .semibold : .regular)
                        .font(isMonospace ? .system(.subheadline, design: .monospaced) : .subheadline)
                        .foregroundStyle(valueColor)
                        .lineLimit(isMonospace ? nil : 1)
                }
            }
        }
        .padding(.vertical, isHighlighted ? 4 : 0)
        .background(
            isHighlighted ? 
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1)) : nil
        )
    }
}

// MARK: - Debug Actions Card

struct DebugActionsCard: View {
    @StateObject private var walletManager = WalletManager.shared
    @State private var showingResetConfirmation = false
    @State private var isResetting = false

    var body: some View {
        InfoCard(
            title: "Debug Actions",
            icon: "wrench.and.screwdriver",
            iconColor: .orange
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("⚠️ Development Tools")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.semibold)

                Button(action: {
                    showingResetConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash.circle")
                        Text("Reset Wallet")
                        Spacer()
                        if isResetting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .foregroundColor(.red)
                }
                .disabled(isResetting)
                .alert("Reset Wallet", isPresented: $showingResetConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset", role: .destructive) {
                        Task {
                            await resetWallet()
                        }
                    }
                } message: {
                    Text("This will delete your wallet data and mnemonic. You'll need to create a new wallet. This action cannot be undone.")
                }

                Text("Use this to recover from corrupted wallet state or invalid mnemonic errors.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func resetWallet() async {
        isResetting = true

        do {
            try await walletManager.resetWallet()
            print("✅ Wallet reset successful")
        } catch {
            print("❌ Wallet reset failed: \(error)")
        }

        isResetting = false
    }
}

// MARK: - Loading and Error States

struct LoadingInfoView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading wallet information...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct ErrorInfoView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Failed to Load Wallet Info")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

#Preview {
    WalletInfoView()
}
