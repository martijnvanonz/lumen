import SwiftUI

/// Reusable button component with consistent styling and behavior
/// Supports different styles, sizes, states, and loading indicators
struct StandardButton: View {
    
    // MARK: - Configuration
    
    let title: String
    let action: () -> Void
    
    // MARK: - Styling Options
    
    var style: ButtonStyle = .primary
    var size: ButtonSize = .regular
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var icon: String? = nil
    var iconPosition: IconPosition = .leading
    
    // MARK: - Button Styles
    
    enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case destructive
        case success
        case outline
        case ghost
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return DesignSystem.Colors.primary
            case .secondary:
                return DesignSystem.Colors.secondary
            case .tertiary:
                return DesignSystem.Colors.backgroundSecondary
            case .destructive:
                return DesignSystem.Colors.error
            case .success:
                return DesignSystem.Colors.success
            case .outline, .ghost:
                return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive, .success:
                return .white
            case .secondary:
                return .white
            case .tertiary:
                return DesignSystem.Colors.textPrimary
            case .outline:
                return DesignSystem.Colors.primary
            case .ghost:
                return DesignSystem.Colors.textSecondary
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .outline:
                return DesignSystem.Colors.primary
            case .ghost:
                return DesignSystem.Colors.borderSecondary
            default:
                return nil
            }
        }
    }
    
    // MARK: - Button Sizes
    
    enum ButtonSize {
        case compact
        case regular
        case large
        case huge
        
        var height: CGFloat {
            switch self {
            case .compact:
                return AppConstants.UI.buttonHeightCompact
            case .regular:
                return AppConstants.UI.buttonHeight
            case .large:
                return AppConstants.UI.buttonHeightLarge
            case .huge:
                return AppConstants.UI.buttonHeightLarge + 8
            }
        }
        
        var font: Font {
            switch self {
            case .compact:
                return DesignSystem.Typography.caption(weight: .medium)
            case .regular:
                return DesignSystem.Typography.subheadline(weight: .medium)
            case .large:
                return DesignSystem.Typography.headline(weight: .semibold)
            case .huge:
                return DesignSystem.Typography.title3(weight: .semibold)
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .compact:
                return EdgeInsets(
                    top: DesignSystem.Spacing.sm,
                    leading: DesignSystem.Spacing.md,
                    bottom: DesignSystem.Spacing.sm,
                    trailing: DesignSystem.Spacing.md
                )
            case .regular:
                return EdgeInsets(
                    top: DesignSystem.Spacing.md,
                    leading: DesignSystem.Spacing.lg,
                    bottom: DesignSystem.Spacing.md,
                    trailing: DesignSystem.Spacing.lg
                )
            case .large, .huge:
                return EdgeInsets(
                    top: DesignSystem.Spacing.lg,
                    leading: DesignSystem.Spacing.xl,
                    bottom: DesignSystem.Spacing.lg,
                    trailing: DesignSystem.Spacing.xl
                )
            }
        }
    }
    
    // MARK: - Icon Position
    
    enum IconPosition {
        case leading
        case trailing
    }
    
    // MARK: - View Body
    
    var body: some View {
        Button(action: isEnabled && !isLoading ? action : {}) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Leading icon
                if iconPosition == .leading {
                    iconView
                }
                
                // Loading indicator or title
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(size.font)
                        .fontWeight(.medium)
                }
                
                // Trailing icon
                if iconPosition == .trailing {
                    iconView
                }
            }
            .foregroundColor(effectiveForegroundColor)
            .padding(size.padding)
            .frame(minHeight: size.height)
            .frame(maxWidth: .infinity)
            .background(effectiveBackgroundColor)
            .overlay(borderOverlay)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(effectiveOpacity)
            .animation(DesignSystem.Animation.fast, value: isPressed)
            .animation(DesignSystem.Animation.fast, value: isEnabled)
            .animation(DesignSystem.Animation.fast, value: isLoading)
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(PressableButtonStyle())
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var iconView: some View {
        if let icon = icon {
            Image(systemName: icon)
                .font(iconFont)
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        if let borderColor = style.borderColor {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(borderColor, lineWidth: AppConstants.UI.borderWidthStandard)
        }
    }
    
    // MARK: - Computed Properties
    
    private var effectiveBackgroundColor: Color {
        if !isEnabled {
            return DesignSystem.Colors.backgroundSecondary
        }
        return style.backgroundColor
    }
    
    private var effectiveForegroundColor: Color {
        if !isEnabled {
            return DesignSystem.Colors.textSecondary
        }
        return style.foregroundColor
    }
    
    private var effectiveOpacity: Double {
        if !isEnabled {
            return 0.6
        }
        return 1.0
    }
    
    private var iconFont: Font {
        switch size {
        case .compact:
            return DesignSystem.Typography.caption(weight: .medium)
        case .regular:
            return DesignSystem.Typography.subheadline(weight: .medium)
        case .large:
            return DesignSystem.Typography.headline(weight: .medium)
        case .huge:
            return DesignSystem.Typography.title3(weight: .medium)
        }
    }
    
    @State private var isPressed = false
}

// MARK: - Button Style for Press Animation

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - Convenience Initializers

extension StandardButton {
    
    /// Primary button with default styling
    static func primary(
        _ title: String,
        action: @escaping () -> Void
    ) -> StandardButton {
        StandardButton(title: title, action: action)
            .style(.primary)
    }
    
    /// Secondary button
    static func secondary(
        _ title: String,
        action: @escaping () -> Void
    ) -> StandardButton {
        StandardButton(title: title, action: action)
            .style(.secondary)
    }
    
    /// Destructive button for dangerous actions
    static func destructive(
        _ title: String,
        action: @escaping () -> Void
    ) -> StandardButton {
        StandardButton(title: title, action: action)
            .style(.destructive)
    }
    
    /// Success button for positive actions
    static func success(
        _ title: String,
        action: @escaping () -> Void
    ) -> StandardButton {
        StandardButton(title: title, action: action)
            .style(.success)
    }
    
    /// Outline button
    static func outline(
        _ title: String,
        action: @escaping () -> Void
    ) -> StandardButton {
        StandardButton(title: title, action: action)
            .style(.outline)
    }
    
    /// Ghost button for subtle actions
    static func ghost(
        _ title: String,
        action: @escaping () -> Void
    ) -> StandardButton {
        StandardButton(title: title, action: action)
            .style(.ghost)
    }
}

// MARK: - Modifier Extensions

extension StandardButton {
    
    /// Set button style
    func style(_ style: ButtonStyle) -> StandardButton {
        var button = self
        button.style = style
        return button
    }
    
    /// Set button size
    func size(_ size: ButtonSize) -> StandardButton {
        var button = self
        button.size = size
        return button
    }
    
    /// Set loading state
    func loading(_ isLoading: Bool) -> StandardButton {
        var button = self
        button.isLoading = isLoading
        return button
    }
    
    /// Set enabled state
    func enabled(_ isEnabled: Bool) -> StandardButton {
        var button = self
        button.isEnabled = isEnabled
        return button
    }
    
    /// Add icon
    func icon(_ icon: String, position: IconPosition = .leading) -> StandardButton {
        var button = self
        button.icon = icon
        button.iconPosition = position
        return button
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Different styles
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Button Styles")
                    .font(DesignSystem.Typography.headline())
                
                StandardButton.primary("Primary Button") {}
                StandardButton.secondary("Secondary Button") {}
                StandardButton.outline("Outline Button") {}
                StandardButton.ghost("Ghost Button") {}
                StandardButton.destructive("Destructive Button") {}
                StandardButton.success("Success Button") {}
            }
            
            // Different sizes
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Button Sizes")
                    .font(DesignSystem.Typography.headline())
                
                StandardButton(title: "Compact", action: {}).size(.compact)
                StandardButton(title: "Regular", action: {}).size(.regular)
                StandardButton(title: "Large", action: {}).size(.large)
                StandardButton(title: "Huge", action: {}).size(.huge)
            }
            
            // States
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Button States")
                    .font(DesignSystem.Typography.headline())
                
                StandardButton(title: "Loading", action: {}).loading(true)
                StandardButton(title: "Disabled", action: {}).enabled(false)
                StandardButton(title: "With Icon", action: {}).icon(DesignSystem.Icons.lightning)
                StandardButton(title: "Trailing Icon", action: {}).icon("arrow.right", position: .trailing)
            }
        }
        .padding()
    }
}
