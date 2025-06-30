import Foundation
import Network
import SwiftUI

/// Monitors network connectivity and handles offline scenarios
class NetworkMonitor: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    @Published var isExpensive = false
    @Published var isConstrained = false
    
    // MARK: - Types
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
        
        var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .unknown: return "Unknown"
            }
        }
        
        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .unknown: return "questionmark.circle"
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var lastConnectionTime: Date?
    private var reconnectionAttempts = 0
    private let maxReconnectionAttempts = 5
    
    // MARK: - Singleton
    
    static let shared = NetworkMonitor()
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring Methods
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    private func updateConnectionStatus(_ path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
        
        // Handle connection state changes
        if !wasConnected && isConnected {
            handleReconnection()
        } else if wasConnected && !isConnected {
            handleDisconnection()
        }
        
        // Log connection changes
        if wasConnected != isConnected {
            print("🌐 Network status changed: \(isConnected ? "Connected" : "Disconnected") via \(connectionType.displayName)")
        }
    }
    
    private func handleReconnection() {
        lastConnectionTime = Date()
        reconnectionAttempts = 0

        // Notify other components about reconnection
        NotificationCenter.default.post(name: .networkReconnected, object: nil)

        // Connection status is now shown via the top-right icon instead of toast notifications
    }
    
    private func handleDisconnection() {
        // Notify other components about disconnection
        NotificationCenter.default.post(name: .networkDisconnected, object: nil)

        // Connection status is now shown via the top-right icon instead of toast notifications
    }
    
    // MARK: - Public Methods
    
    /// Check if network is available for Lightning operations
    func isNetworkAvailableForLightning() -> Bool {
        return isConnected && !isConstrained
    }
    
    /// Get network quality assessment
    func getNetworkQuality() -> NetworkQuality {
        if !isConnected {
            return .offline
        }
        
        if isConstrained {
            return .poor
        }
        
        if isExpensive {
            return .limited
        }
        
        switch connectionType {
        case .wifi, .ethernet:
            return .excellent
        case .cellular:
            return .good
        case .unknown:
            return .poor
        }
    }
    
    enum NetworkQuality {
        case offline
        case poor
        case limited
        case good
        case excellent
        
        var displayName: String {
            switch self {
            case .offline: return "Offline"
            case .poor: return "Poor"
            case .limited: return "Limited"
            case .good: return "Good"
            case .excellent: return "Excellent"
            }
        }
        
        var color: Color {
            switch self {
            case .offline: return .red
            case .poor: return .red
            case .limited: return .orange
            case .good: return .yellow
            case .excellent: return .green
            }
        }
        
        var shouldShowWarning: Bool {
            switch self {
            case .offline, .poor, .limited:
                return true
            case .good, .excellent:
                return false
            }
        }
    }
    
    /// Attempt to reconnect (for manual retry scenarios)
    func attemptReconnection() async -> Bool {
        guard reconnectionAttempts < maxReconnectionAttempts else {
            return false
        }
        
        reconnectionAttempts += 1
        
        // Wait before retry (exponential backoff)
        let delay = min(pow(2.0, Double(reconnectionAttempts)), 30.0)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        return isConnected
    }
    
    /// Get connection status summary
    func getConnectionSummary() -> String {
        if !isConnected {
            return "No internet connection"
        }
        
        var summary = "Connected via \(connectionType.displayName)"
        
        if isExpensive {
            summary += " (expensive)"
        }
        
        if isConstrained {
            summary += " (limited)"
        }
        
        return summary
    }
    
    /// Check if we should warn about expensive connection
    func shouldWarnAboutExpensiveConnection() -> Bool {
        return isConnected && isExpensive && connectionType == .cellular
    }
    
    /// Get time since last connection
    func getTimeSinceLastConnection() -> TimeInterval? {
        guard let lastConnectionTime = lastConnectionTime else { return nil }
        return Date().timeIntervalSince(lastConnectionTime)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let networkReconnected = Notification.Name("networkReconnected")
    static let networkDisconnected = Notification.Name("networkDisconnected")
}

// MARK: - Network Status (now handled by ConnectionStatusIcon in top-right corner)

// MARK: - Offline Mode View

struct OfflineModeView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            VStack(spacing: 16) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("You're Offline")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Lightning payments require an internet connection. Please check your network settings and try again.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Try Again") {
                    Task {
                        await networkMonitor.attemptReconnection()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

// Preview removed - NetworkStatusView replaced by ConnectionStatusIcon in navigation bar
