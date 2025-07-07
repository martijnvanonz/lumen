import SwiftUI
import BreezSDKLiquid

// MARK: - Connection Status Icon (Top-Right Corner)

struct ConnectionStatusIcon: View {
    @StateObject private var eventHandler = PaymentEventHandler.shared

    var body: some View {
        Group {
            switch eventHandler.connectionStatus {
            case .connected:
                Image(systemName: "wifi")
                    .foregroundColor(.green)
                    .font(.system(size: 16, weight: .medium))

            case .connecting, .syncing:
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: .orange))

            case .disconnected:
                Image(systemName: "wifi.slash")
                    .foregroundColor(.red)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .frame(width: 20, height: 20)
        .animation(.easeInOut(duration: 0.3), value: eventHandler.connectionStatus)
    }
}

#Preview {
    ConnectionStatusIcon()
}
