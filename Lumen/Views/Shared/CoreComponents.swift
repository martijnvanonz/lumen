import SwiftUI

// MARK: - Loading View

struct LoadingView: View {
    let text: String
    let scale: CGFloat
    
    init(text: String = "Loading...", scale: CGFloat = 1.2) {
        self.text = text
        self.scale = scale
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView()
                .scaleEffect(scale)
            
            Text(text)
                .font(AppTheme.Typography.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .secondaryButton()
                    .padding(.horizontal, AppTheme.Spacing.xxxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Card Container

struct CardContainer<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let backgroundColor: Color
    let borderColor: Color?
    
    init(
        padding: CGFloat = AppTheme.Spacing.lg,
        cornerRadius: CGFloat = AppTheme.CornerRadius.large,
        backgroundColor: Color = AppTheme.Colors.cardBackground,
        borderColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
    }
    
    var body: some View {
        content
            .padding(padding)
            .cardStyle(
                cornerRadius: cornerRadius,
                backgroundColor: backgroundColor,
                borderColor: borderColor
            )
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let status: StatusType
    let size: CGFloat
    let showAnimation: Bool
    
    enum StatusType {
        case success
        case error
        case warning
        case info
        case pending
        case loading
        
        var color: Color {
            switch self {
            case .success: return AppTheme.Colors.success
            case .error: return AppTheme.Colors.error
            case .warning: return AppTheme.Colors.warning
            case .info: return AppTheme.Colors.info
            case .pending: return AppTheme.Colors.warning
            case .loading: return AppTheme.Colors.primary
            }
        }
        
        var icon: String {
            switch self {
            case .success: return AppTheme.Icons.success
            case .error: return AppTheme.Icons.error
            case .warning: return AppTheme.Icons.warning
            case .info: return AppTheme.Icons.info
            case .pending: return AppTheme.Icons.pending
            case .loading: return AppTheme.Icons.pending
            }
        }
    }
    
    init(status: StatusType, size: CGFloat = 40, showAnimation: Bool = true) {
        self.status = status
        self.size = size
        self.showAnimation = showAnimation
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(status.color.opacity(0.1))
                .frame(width: size, height: size)
            
            if status == .loading && showAnimation {
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: status.color))
            } else {
                Image(systemName: status.icon)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(status.color)
            }
        }
    }
}

// MARK: - Enhanced Action Button

struct EnhancedActionButton: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        color: Color,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.secondaryBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    let valueColor: Color
    let copyable: Bool
    
    init(
        label: String,
        value: String,
        valueColor: Color = .primary,
        copyable: Bool = false
    ) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.copyable = copyable
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(value)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(valueColor)
                    .multilineTextAlignment(.trailing)
                
                if copyable {
                    Button {
                        UIPasteboard.general.string = value
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let iconColor: Color
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color = AppTheme.Colors.primary
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(iconColor)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Feature Row (for onboarding)

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    
    init(
        icon: String,
        title: String,
        description: String,
        iconColor: Color = AppTheme.Colors.primary
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.iconColor = iconColor
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}
