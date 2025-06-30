import SwiftUI

// MARK: - Master Import File for Shared Components
// This file ensures all shared components are available throughout the app

// Re-export all shared components for easy importing
@_exported import struct AppTheme
@_exported import struct ViewModifiers
@_exported import struct CoreComponents
@_exported import struct PaymentComponents
@_exported import struct FormComponents
@_exported import struct NetworkComponents
@_exported import struct SheetManager

// MARK: - Quick Access Extensions

extension View {
    /// Quick access to all shared styling
    var theme: AppTheme.Type { AppTheme.self }
    
    /// Quick access to shared colors
    var colors: AppTheme.Colors.Type { AppTheme.Colors.self }
    
    /// Quick access to shared typography
    var typography: AppTheme.Typography.Type { AppTheme.Typography.self }
    
    /// Quick access to shared spacing
    var spacing: AppTheme.Spacing.Type { AppTheme.Spacing.self }
    
    /// Quick access to shared icons
    var icons: AppTheme.Icons.Type { AppTheme.Icons.self }
}

// MARK: - Component Shortcuts

typealias Loading = LoadingView
typealias Empty = EmptyStateView
typealias Card = CardContainer
typealias Status = StatusIndicator
typealias ActionBtn = EnhancedActionButton
typealias Info = InfoRow
typealias Section = SectionHeader
typealias Feature = FeatureRow

// Payment Components
typealias PaymentStatus = PaymentStatusBadge
typealias PaymentAmount = PaymentAmountView
typealias PaymentRow = PaymentRowView
typealias FeeDisplay = FeeDisplayView
typealias PaymentInfo = PaymentInputInfoCard

// Form Components
typealias TextField = StandardTextField
typealias AmountField = AmountInputField
typealias DescriptionField = DescriptionInputField
typealias FormSection = FormSection
typealias Toggle = ToggleRow

// Network Components
typealias NetworkStatus = NetworkStatusIndicator
typealias ConnectionBadge = ConnectionQualityBadge
typealias OfflineView = OfflineOverlay

// MARK: - Common Patterns

struct CommonPatterns {
    
    /// Standard loading state
    static func loading(_ text: String = "Loading...") -> some View {
        LoadingView(text: text)
    }
    
    /// Standard empty state
    static func empty(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        EmptyStateView(
            icon: icon,
            title: title,
            message: message,
            actionTitle: actionTitle,
            action: action
        )
    }
    
    /// Standard error state
    static func error(
        message: String,
        actionTitle: String = "Try Again",
        action: @escaping () -> Void
    ) -> some View {
        EmptyStateView(
            icon: AppTheme.Icons.error,
            title: "Something went wrong",
            message: message,
            actionTitle: actionTitle,
            action: action
        )
    }
    
    /// Standard success state
    static func success(
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        EmptyStateView(
            icon: AppTheme.Icons.success,
            title: title,
            message: message,
            actionTitle: actionTitle,
            action: action
        )
    }
    
    /// Standard form section
    static func formSection<Content: View>(
        title: String,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        FormSection(title: title, footer: footer, content: content)
    }
    
    /// Standard card container
    static func card<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        CardContainer(content: content)
    }
    
    /// Standard info row
    static func infoRow(
        label: String,
        value: String,
        copyable: Bool = false
    ) -> some View {
        InfoRow(label: label, value: value, copyable: copyable)
    }
}

// MARK: - Animation Presets

struct AnimationPresets {
    static let spring = AppTheme.Animations.spring
    static let easeInOut = AppTheme.Animations.easeInOut
    static let quick = AppTheme.Animations.quick
    
    static let bounce = Animation.interpolatingSpring(stiffness: 300, damping: 10)
    static let slide = Animation.easeInOut(duration: 0.4)
    static let fade = Animation.easeInOut(duration: 0.2)
}

// MARK: - Color Presets

struct ColorPresets {
    static let primary = AppTheme.Colors.primary
    static let secondary = AppTheme.Colors.secondary
    static let success = AppTheme.Colors.success
    static let warning = AppTheme.Colors.warning
    static let error = AppTheme.Colors.error
    static let info = AppTheme.Colors.info
    static let lightning = AppTheme.Colors.lightning
    static let incoming = AppTheme.Colors.incoming
    static let outgoing = AppTheme.Colors.outgoing
}

// MARK: - Spacing Presets

struct SpacingPresets {
    static let xs = AppTheme.Spacing.xs
    static let sm = AppTheme.Spacing.sm
    static let md = AppTheme.Spacing.md
    static let lg = AppTheme.Spacing.lg
    static let xl = AppTheme.Spacing.xl
    static let xxl = AppTheme.Spacing.xxl
    static let xxxl = AppTheme.Spacing.xxxl
    static let huge = AppTheme.Spacing.huge
}

// MARK: - Typography Presets

struct TypographyPresets {
    static let largeTitle = AppTheme.Typography.largeTitle
    static let title = AppTheme.Typography.title
    static let title2 = AppTheme.Typography.title2
    static let title3 = AppTheme.Typography.title3
    static let headline = AppTheme.Typography.headline
    static let subheadline = AppTheme.Typography.subheadline
    static let body = AppTheme.Typography.body
    static let callout = AppTheme.Typography.callout
    static let caption = AppTheme.Typography.caption
    static let caption2 = AppTheme.Typography.caption2
    static let monospaced = AppTheme.Typography.monospaced
    static let balance = AppTheme.Typography.balanceFont
}

// MARK: - Icon Presets

struct IconPresets {
    static let success = AppTheme.Icons.success
    static let error = AppTheme.Icons.error
    static let warning = AppTheme.Icons.warning
    static let info = AppTheme.Icons.info
    static let pending = AppTheme.Icons.pending
    static let lightning = AppTheme.Icons.lightning
    static let send = AppTheme.Icons.send
    static let receive = AppTheme.Icons.receive
    static let refresh = AppTheme.Icons.refresh
    static let settings = AppTheme.Icons.settings
    static let wifi = AppTheme.Icons.wifi
    static let wifiSlash = AppTheme.Icons.wifiSlash
    static let cellular = AppTheme.Icons.cellular
    static let faceID = AppTheme.Icons.faceID
    static let touchID = AppTheme.Icons.touchID
    static let lock = AppTheme.Icons.lock
    static let shield = AppTheme.Icons.shield
}

// MARK: - Development Helpers

#if DEBUG
struct ComponentPreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Loading states
                LoadingView(text: "Loading...")
                    .frame(height: 100)
                
                // Empty states
                EmptyStateView(
                    icon: AppTheme.Icons.info,
                    title: "No Data",
                    message: "Nothing to show here",
                    actionTitle: "Refresh"
                ) { }
                
                // Buttons
                VStack(spacing: AppTheme.Spacing.md) {
                    Button("Primary Button") { }
                        .primaryButton()
                    
                    Button("Secondary Button") { }
                        .secondaryButton()
                }
                
                // Cards
                CardContainer {
                    VStack {
                        Text("Card Content")
                        Text("More content here")
                    }
                }
                
                // Status indicators
                HStack {
                    StatusIndicator(status: .success)
                    StatusIndicator(status: .error)
                    StatusIndicator(status: .warning)
                    StatusIndicator(status: .loading)
                }
                
                // Network components
                NetworkStatusIndicator(style: .full)
                ConnectionQualityBadge(showDetails: true)
            }
            .padding()
        }
    }
}

#Preview {
    ComponentPreview()
}
#endif
