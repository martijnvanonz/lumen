import SwiftUI

/// Centralized app theme and design system
struct AppTheme {
    
    // MARK: - Colors
    
    struct Colors {
        // Primary colors
        static let primary = Color.blue
        static let secondary = Color.gray
        static let accent = Color.purple
        
        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Lightning Network
        static let lightning = Color.yellow
        
        // Payment types
        static let incoming = Color.green
        static let outgoing = Color.orange
        
        // Background colors
        static let cardBackground = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let overlayBackground = Color.black.opacity(0.3)
        
        // Border colors
        static let border = Color(.separator)
        static let focusedBorder = Color.blue.opacity(0.3)
    }
    
    // MARK: - Typography
    
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        static let headline = Font.headline
        static let subheadline = Font.subheadline
        static let body = Font.body
        static let callout = Font.callout
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        // Special fonts
        static let monospaced = Font.body.monospaced()
        static let balanceFont = Font.system(size: 36, weight: .bold, design: .rounded)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 40
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
    }
    
    // MARK: - Shadows
    
    struct Shadows {
        static let card = Color.black.opacity(0.1)
        static let cardRadius: CGFloat = 10
        static let cardOffset = CGSize(width: 0, height: 5)
        
        static let error = Color.red.opacity(0.2)
        static let errorRadius: CGFloat = 8
        static let errorOffset = CGSize(width: 0, height: 4)
        
        static let notification = Color.black.opacity(0.15)
        static let notificationRadius: CGFloat = 8
        static let notificationOffset = CGSize(width: 0, height: 2)
    }
    
    // MARK: - Animations
    
    struct Animations {
        static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let easeInOut = Animation.easeInOut(duration: 0.3)
        static let quick = Animation.easeInOut(duration: 0.2)
    }
    
    // MARK: - Icons
    
    struct Icons {
        // Payment types
        static let bolt11 = "bolt.fill"
        static let lnUrlPay = "at"
        static let bolt12Offer = "gift.fill"
        static let bitcoinAddress = "bitcoinsign.circle.fill"
        static let lnUrlWithdraw = "arrow.down.circle.fill"
        static let lnUrlAuth = "key.fill"
        
        // Payment directions
        static let incoming = "arrow.down.circle.fill"
        static let outgoing = "arrow.up.circle.fill"
        
        // Status icons
        static let success = "checkmark.circle.fill"
        static let error = "xmark.circle.fill"
        static let warning = "exclamationmark.triangle.fill"
        static let info = "info.circle.fill"
        static let pending = "clock"
        
        // Network
        static let wifi = "wifi"
        static let wifiSlash = "wifi.slash"
        static let cellular = "antenna.radiowaves.left.and.right"
        
        // Security
        static let faceID = "faceid"
        static let touchID = "touchid"
        static let lock = "lock.fill"
        static let shield = "lock.shield.fill"
        
        // Lightning
        static let lightning = "bolt.fill"
        static let lightningCircle = "bolt.circle.fill"
        
        // Actions
        static let send = "arrow.up.circle.fill"
        static let receive = "arrow.down.circle.fill"
        static let refresh = "arrow.clockwise"
        static let settings = "gear"
        static let info = "info.circle"
    }
}

// MARK: - Payment Status Extensions

extension PaymentStatus {
    var color: Color {
        switch self {
        case .created: return AppTheme.Colors.info
        case .pending: return AppTheme.Colors.warning
        case .complete: return AppTheme.Colors.success
        case .failed: return AppTheme.Colors.error
        case .timedOut: return AppTheme.Colors.error
        case .refundable: return AppTheme.Colors.warning
        case .refundPending: return AppTheme.Colors.warning
        case .waitingFeeAcceptance: return AppTheme.Colors.info
        }
    }
    
    var icon: String {
        switch self {
        case .created: return AppTheme.Icons.info
        case .pending: return AppTheme.Icons.pending
        case .complete: return AppTheme.Icons.success
        case .failed: return AppTheme.Icons.error
        case .timedOut: return AppTheme.Icons.error
        case .refundable: return AppTheme.Icons.warning
        case .refundPending: return AppTheme.Icons.pending
        case .waitingFeeAcceptance: return AppTheme.Icons.info
        }
    }
}

// MARK: - Payment Type Extensions

extension PaymentType {
    var color: Color {
        switch self {
        case .send: return AppTheme.Colors.outgoing
        case .receive: return AppTheme.Colors.incoming
        }
    }
    
    var icon: String {
        switch self {
        case .send: return AppTheme.Icons.outgoing
        case .receive: return AppTheme.Icons.incoming
        }
    }
}
