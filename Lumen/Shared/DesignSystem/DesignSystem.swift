import SwiftUI

/// Design System for Lumen Lightning Wallet
/// Provides consistent design tokens, component styles, and theming
/// across the entire application. This ensures visual consistency
/// and makes it easy to update the app's appearance globally.
struct DesignSystem {
    
    // MARK: - Typography System
    
    struct Typography {
        
        // MARK: - Text Styles
        
        /// Large title for main headings
        static func largeTitle(weight: Font.Weight = .bold) -> Font {
            .system(size: AppConstants.Typography.sizeLargeTitle, weight: weight, design: .default)
        }
        
        /// Title for section headings
        static func title(weight: Font.Weight = .semibold) -> Font {
            .system(size: AppConstants.Typography.sizeTitle, weight: weight, design: .default)
        }
        
        /// Title 2 for subsection headings
        static func title2(weight: Font.Weight = .semibold) -> Font {
            .system(size: AppConstants.Typography.sizeTitle2, weight: weight, design: .default)
        }
        
        /// Title 3 for smaller headings
        static func title3(weight: Font.Weight = .medium) -> Font {
            .system(size: AppConstants.Typography.sizeTitle3, weight: weight, design: .default)
        }
        
        /// Headline for important text
        static func headline(weight: Font.Weight = .semibold) -> Font {
            .system(size: AppConstants.Typography.sizeHeadline, weight: weight, design: .default)
        }
        
        /// Body text for main content
        static func body(weight: Font.Weight = .regular) -> Font {
            .system(size: AppConstants.Typography.sizeBody, weight: weight, design: .default)
        }
        
        /// Subheadline for secondary content
        static func subheadline(weight: Font.Weight = .regular) -> Font {
            .system(size: AppConstants.Typography.sizeSubheadline, weight: weight, design: .default)
        }
        
        /// Footnote for small text
        static func footnote(weight: Font.Weight = .regular) -> Font {
            .system(size: AppConstants.Typography.sizeFootnote, weight: weight, design: .default)
        }
        
        /// Caption for very small text
        static func caption(weight: Font.Weight = .regular) -> Font {
            .system(size: AppConstants.Typography.sizeCaption, weight: weight, design: .default)
        }
        
        // MARK: - Specialized Typography
        
        /// Monospace font for addresses and technical data
        static func monospace(size: CGFloat = AppConstants.Typography.sizeBody) -> Font {
            .system(size: size, weight: .regular, design: .monospaced)
        }
        
        /// Numeric font for amounts and numbers
        static func numeric(size: CGFloat = AppConstants.Typography.sizeBody, weight: Font.Weight = .medium) -> Font {
            .system(size: size, weight: weight, design: .default)
                .monospacedDigit()
        }
    }
    
    // MARK: - Color System
    
    struct Colors {
        
        // MARK: - Semantic Colors
        
        /// Primary brand color
        static let primary = AppConstants.Colors.lightning
        
        /// Secondary brand color
        static let secondary = AppConstants.Colors.bitcoin
        
        /// Accent color for highlights
        static let accent = AppConstants.Colors.liquid
        
        // MARK: - Status Colors
        
        /// Success state color
        static let success = AppConstants.Colors.success
        
        /// Warning state color
        static let warning = AppConstants.Colors.warning
        
        /// Error state color
        static let error = AppConstants.Colors.error
        
        /// Information color
        static let info = AppConstants.Colors.info
        
        // MARK: - Background Colors
        
        /// Primary background color
        static let backgroundPrimary = AppConstants.Colors.cardBackground
        
        /// Secondary background color
        static let backgroundSecondary = AppConstants.Colors.secondaryBackground
        
        /// Tertiary background color
        static let backgroundTertiary = AppConstants.Colors.tertiaryBackground
        
        // MARK: - Text Colors
        
        /// Primary text color
        static let textPrimary = Color.primary
        
        /// Secondary text color
        static let textSecondary = Color.secondary
        
        /// Tertiary text color
        static let textTertiary = Color(.tertiaryLabel)
        
        /// Placeholder text color
        static let textPlaceholder = Color(.placeholderText)
        
        // MARK: - Border Colors
        
        /// Primary border color
        static let borderPrimary = AppConstants.Colors.borderPrimary
        
        /// Secondary border color
        static let borderSecondary = AppConstants.Colors.borderSecondary
        
        /// Accent border color
        static let borderAccent = AppConstants.Colors.borderAccent
    }
    
    // MARK: - Spacing System
    
    struct Spacing {
        
        /// Extra small spacing (4pt)
        static let xs = AppConstants.UI.paddingXSmall
        
        /// Small spacing (8pt)
        static let sm = AppConstants.UI.paddingSmall
        
        /// Medium spacing (16pt) - Most common
        static let md = AppConstants.UI.paddingStandard
        
        /// Large spacing (24pt)
        static let lg = AppConstants.UI.paddingLarge
        
        /// Extra large spacing (32pt)
        static let xl = AppConstants.UI.paddingXLarge
        
        /// Component spacing (12pt)
        static let component = AppConstants.UI.componentSpacing
        
        /// Item spacing (8pt)
        static let item = AppConstants.UI.itemSpacing
        
        /// Card spacing (24pt)
        static let card = AppConstants.UI.cardSpacing
        
        /// Section spacing (32pt)
        static let section = AppConstants.UI.sectionSpacing
    }
    
    // MARK: - Corner Radius System
    
    struct CornerRadius {
        
        /// Small corner radius (8pt)
        static let sm = AppConstants.UI.cornerRadiusSmall
        
        /// Standard corner radius (12pt) - Most common
        static let md = AppConstants.UI.cornerRadiusStandard
        
        /// Large corner radius (16pt)
        static let lg = AppConstants.UI.cornerRadiusLarge
        
        /// Extra large corner radius (20pt)
        static let xl = AppConstants.UI.cornerRadiusXLarge
    }
    
    // MARK: - Shadow System
    
    struct Shadow {
        
        /// Light shadow for subtle elevation
        static let light = Shadow(
            color: Color.black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
        
        /// Medium shadow for cards
        static let medium = Shadow(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        
        /// Heavy shadow for modals
        static let heavy = Shadow(
            color: Color.black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
        
        struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
    
    // MARK: - Animation System
    
    struct Animation {
        
        /// Fast animation for quick interactions
        static let fast = SwiftUI.Animation.easeInOut(duration: AppConstants.UI.animationFast)
        
        /// Standard animation for most interactions
        static let standard = SwiftUI.Animation.easeInOut(duration: AppConstants.UI.animationStandard)
        
        /// Slow animation for dramatic effects
        static let slow = SwiftUI.Animation.easeInOut(duration: AppConstants.UI.animationSlow)
        
        /// Spring animation for bouncy effects
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
        
        /// Smooth animation for continuous changes
        static let smooth = SwiftUI.Animation.easeOut(duration: AppConstants.UI.animationStandard)
    }
    
    // MARK: - Icon System
    
    struct Icons {
        
        /// Small icon size (16pt)
        static let sizeSmall = AppConstants.UI.iconSizeSmall
        
        /// Standard icon size (20pt)
        static let sizeStandard = AppConstants.UI.iconSizeStandard
        
        /// Large icon size (24pt)
        static let sizeLarge = AppConstants.UI.iconSizeLarge
        
        /// Extra large icon size (32pt)
        static let sizeXLarge = AppConstants.UI.iconSizeXLarge
        
        // MARK: - Common Icons
        
        static let lightning = "bolt.fill"
        static let bitcoin = "bitcoinsign.circle.fill"
        static let wallet = "wallet.pass.fill"
        static let send = "arrow.up.circle.fill"
        static let receive = "arrow.down.circle.fill"
        static let settings = "gearshape.fill"
        static let scan = "qrcode.viewfinder"
        static let copy = "doc.on.doc.fill"
        static let share = "square.and.arrow.up.fill"
        static let success = "checkmark.circle.fill"
        static let error = "exclamationmark.triangle.fill"
        static let warning = "exclamationmark.circle.fill"
        static let info = "info.circle.fill"
        static let loading = "arrow.triangle.2.circlepath"
        static let network = "wifi"
        static let networkOff = "wifi.slash"
    }
}

// MARK: - View Extensions for Design System

extension View {
    
    // MARK: - Typography Modifiers
    
    func designSystemFont(_ style: (Font.Weight) -> Font, weight: Font.Weight = .regular) -> some View {
        self.font(style(weight))
    }
    
    // MARK: - Spacing Modifiers
    
    func designSystemPadding(_ edges: Edge.Set = .all, _ length: CGFloat) -> some View {
        self.padding(edges, length)
    }
    
    func standardPadding() -> some View {
        self.padding(DesignSystem.Spacing.md)
    }
    
    func cardPadding() -> some View {
        self.padding(DesignSystem.Spacing.card)
    }
    
    // MARK: - Background Modifiers
    
    func cardBackground() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundPrimary)
        )
    }
    
    func secondaryBackground() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundSecondary)
        )
    }
    
    // MARK: - Border Modifiers
    
    func standardBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.borderPrimary, lineWidth: AppConstants.UI.borderWidthThin)
        )
    }
    
    func accentBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.borderAccent, lineWidth: AppConstants.UI.borderWidthStandard)
        )
    }
    
    // MARK: - Shadow Modifiers
    
    func lightShadow() -> some View {
        let shadow = DesignSystem.Shadow.light
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func mediumShadow() -> some View {
        let shadow = DesignSystem.Shadow.medium
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func heavyShadow() -> some View {
        let shadow = DesignSystem.Shadow.heavy
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
