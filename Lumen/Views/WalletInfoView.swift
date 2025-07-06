import SwiftUI
import BreezSDKLiquid

// MARK: - Helper Functions

/// Format sats amount as string for InfoRow usage
private func formatSatsString(_ sats: UInt64, formatLarge: Bool = false) -> String {
    if formatLarge {
        let formatted = formatLargeAmount(sats)
        return sats >= 1_000 ? formatted : "\(sats) sats"
    } else {
        return "\(sats) sats"
    }
}

/// Format large amounts with K/M/BTC suffixes
private func formatLargeAmount(_ sats: UInt64) -> String {
    if sats >= 100_000_000 {
        let btc = Double(sats) / 100_000_000
        return String(format: "%.2f BTC", btc)
    } else if sats >= 1_000_000 {
        let millions = Double(sats) / 1_000_000
        return String(format: "%.1fM", millions)
    } else if sats >= 1_000 {
        let thousands = Double(sats) / 1_000
        return String(format: "%.1fK", thousands)
    } else {
        return "\(sats)"
    }
}

struct WalletInfoView: View {
    @StateObject private var walletManager = WalletManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var walletInfo: GetInfoResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        LoadingInfoView()
                    } else if let walletInfo = walletInfo {
                        WalletDetailsView(walletInfo: walletInfo)
                    } else if let errorMessage = errorMessage {
                        ErrorInfoView(message: errorMessage) {
                            Task { await loadWalletInfo() }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Wallet Info")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Refresh") {
                        Task { await loadWalletInfo() }
                    }
                    .disabled(isLoading)
                }
            }
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
        }
    }
}

// MARK: - Connection Status Card

struct ConnectionStatusCard: View {
    let walletInfo: GetInfoResponse
    
    var body: some View {
        InfoCard(
            title: L("connection_status"),
            icon: "wifi",
            iconColor: .green
        ) {
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    label: "Status",
                    value: L("connected"),
                    valueColor: .green
                )

                InfoRow(
                    label: L("liquid_tip"),
                    value: "\(walletInfo.blockchainInfo.liquidTip)"
                )

                if walletInfo.walletInfo.pendingReceiveSat > 0 {
                    InfoRow(
                        label: L("pending_receive"),
                        value: formatSatsString(walletInfo.walletInfo.pendingReceiveSat),
                        valueColor: .orange
                    )
                }

                if walletInfo.walletInfo.pendingSendSat > 0 {
                    InfoRow(
                        label: L("pending_send"),
                        value: formatSatsString(walletInfo.walletInfo.pendingSendSat),
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
            title: L("balance_details"),
            icon: "bitcoinsign.circle",
            iconColor: .orange
        ) {
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    label: L("total_balance"),
                    value: formatSatsString(walletInfo.walletInfo.balanceSat, formatLarge: true),
                    valueColor: .primary,
                    isHighlighted: true
                )

                if walletInfo.walletInfo.pendingReceiveSat > 0 {
                    InfoRow(
                        label: L("pending_receive"),
                        value: formatSatsString(walletInfo.walletInfo.pendingReceiveSat),
                        valueColor: .green
                    )
                }

                if walletInfo.walletInfo.pendingSendSat > 0 {
                    InfoRow(
                        label: L("pending_send"),
                        value: formatSatsString(walletInfo.walletInfo.pendingSendSat),
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
    @StateObject private var walletManager = WalletManager.shared
    @State private var lightningLimits: LightningPaymentLimitsResponse?
    @State private var onchainLimits: OnchainPaymentLimitsResponse?
    @State private var isLoadingLimits = false
    @State private var limitsError: String?

    var body: some View {
        InfoCard(
            title: "Payment Limits",
            icon: "gauge",
            iconColor: .red
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if isLoadingLimits {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading limits...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let error = limitsError {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(
                            label: "Status",
                            value: "Error loading limits",
                            valueColor: .red
                        )

                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)

                        Button("Retry") {
                            Task { await loadLimits() }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                } else {
                    // Lightning Limits
                    if let lightningLimits = lightningLimits {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("⚡ Lightning")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)

                            InfoRow(
                                label: "Send Range",
                                value: "\(lightningLimits.send.minSat) - \(formatLargeAmount(lightningLimits.send.maxSat)) sats"
                            )

                            InfoRow(
                                label: "Receive Range",
                                value: "\(lightningLimits.receive.minSat) - \(formatLargeAmount(lightningLimits.receive.maxSat)) sats"
                            )
                        }
                    }

                    // Onchain Limits
                    if let onchainLimits = onchainLimits {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("₿ Bitcoin")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)

                            InfoRow(
                                label: "Send Range",
                                value: "\(onchainLimits.send.minSat) - \(formatLargeAmount(onchainLimits.send.maxSat)) sats"
                            )

                            InfoRow(
                                label: "Receive Range",
                                value: "\(onchainLimits.receive.minSat) - \(formatLargeAmount(onchainLimits.receive.maxSat)) sats"
                            )
                        }
                    }

                    if lightningLimits == nil && onchainLimits == nil {
                        InfoRow(
                            label: "Status",
                            value: "No limits loaded",
                            valueColor: .secondary
                        )
                    }
                }
            }
        }
        .onAppear {
            Task { await loadLimits() }
        }
    }

    private func loadLimits() async {
        isLoadingLimits = true
        limitsError = nil

        // Load Lightning limits
        do {
            let limits = try await walletManager.fetchLightningLimits()
            await MainActor.run {
                lightningLimits = limits
            }
        } catch {
            await MainActor.run {
                limitsError = "Lightning limits: \(error.localizedDescription)"
            }
        }

        // Load Onchain limits
        do {
            let limits = try await walletManager.fetchOnchainLimits()
            await MainActor.run {
                onchainLimits = limits
            }
        } catch {
            await MainActor.run {
                if limitsError == nil {
                    limitsError = "Onchain limits: \(error.localizedDescription)"
                } else {
                    limitsError = "Both Lightning and Onchain limits failed to load"
                }
            }
        }

        await MainActor.run {
            isLoadingLimits = false
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
