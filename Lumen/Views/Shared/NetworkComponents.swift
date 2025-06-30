import SwiftUI
import Network

// MARK: - Network Status Indicator

struct NetworkStatusIndicator: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    let style: IndicatorStyle
    let showLabel: Bool
    
    enum IndicatorStyle {
        case icon, badge, full
    }
    
    init(style: IndicatorStyle = .icon, showLabel: Bool = false) {
        self.style = style
        self.showLabel = showLabel
    }
    
    var body: some View {
        switch style {
        case .icon:
            iconView
        case .badge:
            badgeView
        case .full:
            fullView
        }
    }
    
    private var iconView: some View {
        Image(systemName: networkMonitor.connectionType.icon)
            .font(AppTheme.Typography.caption)
            .foregroundColor(networkQuality.color)
    }
    
    private var badgeView: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: networkMonitor.connectionType.icon)
                .font(AppTheme.Typography.caption2)
            
            if showLabel {
                Text(networkQuality.displayName)
                    .font(AppTheme.Typography.caption2)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(networkQuality.color)
        )
    }
    
    private var fullView: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: networkMonitor.connectionType.icon)
                .foregroundColor(networkQuality.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Network: \(networkQuality.displayName)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(networkQuality.color)
                
                if networkMonitor.shouldWarnAboutExpensiveConnection() {
                    Text("Using cellular data")
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(AppTheme.Colors.warning)
                }
            }
            
            Spacer()
            
            if !networkMonitor.isConnected {
                Button("Retry") {
                    Task {
                        await networkMonitor.attemptReconnection()
                    }
                }
                .font(AppTheme.Typography.caption)
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(networkQuality.color.opacity(0.1))
        .if(networkQuality.shouldShowWarning) { view in
            view.cardStyle(
                cornerRadius: AppTheme.CornerRadius.small,
                backgroundColor: networkQuality.color.opacity(0.05),
                borderColor: networkQuality.color.opacity(0.2)
            )
        }
    }
    
    private var networkQuality: NetworkQuality {
        networkMonitor.getNetworkQuality()
    }
}

// MARK: - Connection Quality Badge

struct ConnectionQualityBadge: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    let showDetails: Bool
    
    init(showDetails: Bool = false) {
        self.showDetails = showDetails
    }
    
    var body: some View {
        let quality = networkMonitor.getNetworkQuality()
        
        HStack(spacing: AppTheme.Spacing.xs) {
            Circle()
                .fill(quality.color)
                .frame(width: 8, height: 8)
            
            Text(quality.displayName)
                .font(AppTheme.Typography.caption2)
                .foregroundColor(quality.color)
            
            if showDetails && networkMonitor.isConnected {
                Text("•")
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(.secondary)
                
                Text(connectionDetails)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(quality.color.opacity(0.1))
        )
    }
    
    private var connectionDetails: String {
        switch networkMonitor.connectionType {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return networkMonitor.isExpensive ? "Cellular (Expensive)" : "Cellular"
        case .ethernet:
            return "Ethernet"
        case .other:
            return "Connected"
        case .none:
            return "Offline"
        }
    }
}

// MARK: - Offline Overlay

struct OfflineOverlay: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    let style: OverlayStyle
    
    enum OverlayStyle {
        case fullScreen, banner, compact
    }
    
    init(style: OverlayStyle = .fullScreen) {
        self.style = style
    }
    
    var body: some View {
        if !networkMonitor.isConnected {
            switch style {
            case .fullScreen:
                fullScreenView
            case .banner:
                bannerView
            case .compact:
                compactView
            }
        }
    }
    
    private var fullScreenView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: AppTheme.Icons.wifiSlash)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.error)
            
            Text("You're Offline")
                .font(AppTheme.Typography.title2)
                .fontWeight(.bold)
            
            Text("Lightning payments require an internet connection. Please check your network settings and try again.")
                .font(AppTheme.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.lg)
            
            Button("Try Again") {
                Task {
                    await networkMonitor.attemptReconnection()
                }
            }
            .primaryButton()
            .padding(.horizontal, AppTheme.Spacing.xxxl)
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.overlayBackground)
        .ignoresSafeArea()
    }
    
    private var bannerView: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: AppTheme.Icons.wifiSlash)
                .foregroundColor(AppTheme.Colors.error)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("No Internet Connection")
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)
                
                Text("Check your connection and try again")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Retry") {
                Task {
                    await networkMonitor.attemptReconnection()
                }
            }
            .font(AppTheme.Typography.caption)
            .buttonStyle(.bordered)
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.error.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(AppTheme.Colors.error.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
    
    private var compactView: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: AppTheme.Icons.wifiSlash)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.error)
            
            Text("Offline")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.error)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(AppTheme.Colors.error.opacity(0.1))
        )
    }
}

// MARK: - Network Quality Extensions

extension NetworkMonitor {
    struct NetworkQuality {
        let displayName: String
        let color: Color
        let shouldShowWarning: Bool
        
        static let excellent = NetworkQuality(
            displayName: "Excellent",
            color: AppTheme.Colors.success,
            shouldShowWarning: false
        )
        
        static let good = NetworkQuality(
            displayName: "Good",
            color: AppTheme.Colors.success,
            shouldShowWarning: false
        )
        
        static let fair = NetworkQuality(
            displayName: "Fair",
            color: AppTheme.Colors.warning,
            shouldShowWarning: true
        )
        
        static let poor = NetworkQuality(
            displayName: "Poor",
            color: AppTheme.Colors.error,
            shouldShowWarning: true
        )
        
        static let offline = NetworkQuality(
            displayName: "Offline",
            color: AppTheme.Colors.error,
            shouldShowWarning: true
        )
    }
    
    func getNetworkQuality() -> NetworkQuality {
        if !isConnected {
            return .offline
        }
        
        switch connectionType {
        case .wifi:
            return .excellent
        case .ethernet:
            return .excellent
        case .cellular:
            return isExpensive ? .fair : .good
        case .other:
            return .good
        case .none:
            return .offline
        }
    }
}

// MARK: - Connection Type Extensions

extension NetworkMonitor.ConnectionType {
    var icon: String {
        switch self {
        case .wifi: return AppTheme.Icons.wifi
        case .cellular: return AppTheme.Icons.cellular
        case .ethernet: return "cable.connector"
        case .other: return "network"
        case .none: return AppTheme.Icons.wifiSlash
        }
    }
    
    var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .other: return "Connected"
        case .none: return "Offline"
        }
    }
}
