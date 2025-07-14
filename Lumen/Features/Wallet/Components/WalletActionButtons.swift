import SwiftUI

/// Wallet action buttons component for send and receive operations
/// Uses the new StandardButton component for consistent styling
struct WalletActionButtons: View {
    
    // MARK: - Configuration
    
    let onSendTap: () -> Void
    let onReceiveTap: () -> Void
    
    // MARK: - Styling Options
    
    var isEnabled: Bool = true
    var layout: ButtonLayout = .horizontal
    
    // MARK: - Button Layout
    
    enum ButtonLayout {
        case horizontal
        case vertical
        case grid
    }
    
    // MARK: - View Body
    
    var body: some View {
        Group {
            switch layout {
            case .horizontal:
                horizontalLayout
            case .vertical:
                verticalLayout
            case .grid:
                gridLayout
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
    
    // MARK: - Layout Views
    
    @ViewBuilder
    private var horizontalLayout: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            sendButton
            receiveButton
        }
    }
    
    @ViewBuilder
    private var verticalLayout: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            sendButton
            receiveButton
        }
    }
    
    @ViewBuilder
    private var gridLayout: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
            ],
            spacing: DesignSystem.Spacing.md
        ) {
            sendButton
            receiveButton
        }
    }
    
    // MARK: - Button Components
    
    @ViewBuilder
    private var sendButton: some View {
        StandardButton(title: "Send", action: onSendTap)
            .style(.primary)
            .size(.large)
            .icon(DesignSystem.Icons.send)
            .enabled(isEnabled)
    }
    
    @ViewBuilder
    private var receiveButton: some View {
        StandardButton(title: "Receive", action: onReceiveTap)
            .style(.secondary)
            .size(.large)
            .icon(DesignSystem.Icons.receive)
            .enabled(isEnabled)
    }
}

// MARK: - Enhanced Action Buttons

/// Enhanced wallet action buttons with additional actions
struct EnhancedWalletActionButtons: View {
    
    // MARK: - Configuration
    
    let onSendTap: () -> Void
    let onReceiveTap: () -> Void
    let onScanTap: (() -> Void)?
    let onAddBitcoinTap: (() -> Void)?
    
    // MARK: - Styling Options
    
    var isEnabled: Bool = true
    var showSecondaryActions: Bool = true
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Primary actions
            HStack(spacing: DesignSystem.Spacing.md) {
                StandardButton(title: "Send", action: onSendTap)
                    .style(.primary)
                    .size(.large)
                    .icon(DesignSystem.Icons.send)
                    .enabled(isEnabled)
                
                StandardButton(title: "Receive", action: onReceiveTap)
                    .style(.secondary)
                    .size(.large)
                    .icon(DesignSystem.Icons.receive)
                    .enabled(isEnabled)
            }
            
            // Secondary actions
            if showSecondaryActions {
                HStack(spacing: DesignSystem.Spacing.md) {
                    if let onScanTap = onScanTap {
                        StandardButton(title: "Scan", action: onScanTap)
                            .style(.outline)
                            .size(.regular)
                            .icon(DesignSystem.Icons.scan)
                            .enabled(isEnabled)
                    }
                    
                    if let onAddBitcoinTap = onAddBitcoinTap {
                        StandardButton(title: "Add Bitcoin", action: onAddBitcoinTap)
                            .style(.outline)
                            .size(.regular)
                            .icon(DesignSystem.Icons.bitcoin)
                            .enabled(isEnabled)
                    }
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

// MARK: - Compact Action Buttons

/// Compact wallet action buttons for smaller spaces
struct CompactWalletActionButtons: View {
    
    // MARK: - Configuration
    
    let onSendTap: () -> Void
    let onReceiveTap: () -> Void
    let onScanTap: (() -> Void)?
    
    // MARK: - Styling Options
    
    var isEnabled: Bool = true
    
    // MARK: - View Body
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Send button
            Button(action: onSendTap) {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: DesignSystem.Icons.send)
                        .font(DesignSystem.Typography.title3(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text("Send")
                        .font(DesignSystem.Typography.caption(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: AppConstants.UI.borderWidthThin)
                        )
                )
            }
            .disabled(!isEnabled)
            
            // Receive button
            Button(action: onReceiveTap) {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: DesignSystem.Icons.receive)
                        .font(DesignSystem.Typography.title3(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.secondary)
                    
                    Text("Receive")
                        .font(DesignSystem.Typography.caption(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(DesignSystem.Colors.secondary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .stroke(DesignSystem.Colors.secondary.opacity(0.3), lineWidth: AppConstants.UI.borderWidthThin)
                        )
                )
            }
            .disabled(!isEnabled)
            
            // Scan button (optional)
            if let onScanTap = onScanTap {
                Button(action: onScanTap) {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: DesignSystem.Icons.scan)
                            .font(DesignSystem.Typography.title3(weight: .medium))
                            .foregroundColor(DesignSystem.Colors.info)
                        
                        Text("Scan")
                            .font(DesignSystem.Typography.caption(weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(DesignSystem.Colors.info.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                    .stroke(DesignSystem.Colors.info.opacity(0.3), lineWidth: AppConstants.UI.borderWidthThin)
                            )
                    )
                }
                .disabled(!isEnabled)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

// MARK: - Modifier Extensions

extension WalletActionButtons {
    
    /// Set button layout
    func layout(_ layout: ButtonLayout) -> WalletActionButtons {
        var buttons = self
        buttons.layout = layout
        return buttons
    }
    
    /// Set enabled state
    func enabled(_ isEnabled: Bool) -> WalletActionButtons {
        var buttons = self
        buttons.isEnabled = isEnabled
        return buttons
    }
}

extension EnhancedWalletActionButtons {
    
    /// Show/hide secondary actions
    func secondaryActions(_ show: Bool) -> EnhancedWalletActionButtons {
        var buttons = self
        buttons.showSecondaryActions = show
        return buttons
    }
    
    /// Set enabled state
    func enabled(_ isEnabled: Bool) -> EnhancedWalletActionButtons {
        var buttons = self
        buttons.isEnabled = isEnabled
        return buttons
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.xl) {
        // Standard horizontal layout
        WalletActionButtons(
            onSendTap: { print("Send tapped") },
            onReceiveTap: { print("Receive tapped") }
        )
        
        // Enhanced with secondary actions
        EnhancedWalletActionButtons(
            onSendTap: { print("Send tapped") },
            onReceiveTap: { print("Receive tapped") },
            onScanTap: { print("Scan tapped") },
            onAddBitcoinTap: { print("Add Bitcoin tapped") }
        )
        
        // Compact layout
        CompactWalletActionButtons(
            onSendTap: { print("Send tapped") },
            onReceiveTap: { print("Receive tapped") },
            onScanTap: { print("Scan tapped") }
        )
        
        // Vertical layout
        WalletActionButtons(
            onSendTap: { print("Send tapped") },
            onReceiveTap: { print("Receive tapped") }
        )
        .layout(.vertical)
    }
    .padding()
    .background(DesignSystem.Colors.backgroundSecondary)
}
