import SwiftUI

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowOffset: CGSize
    let backgroundColor: Color
    let borderColor: Color?
    let borderWidth: CGFloat
    
    init(
        cornerRadius: CGFloat = AppTheme.CornerRadius.large,
        shadowColor: Color = AppTheme.Shadows.card,
        shadowRadius: CGFloat = AppTheme.Shadows.cardRadius,
        shadowOffset: CGSize = AppTheme.Shadows.cardOffset,
        backgroundColor: Color = AppTheme.Colors.cardBackground,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 1
    ) {
        self.cornerRadius = cornerRadius
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(color: shadowColor, radius: shadowRadius, x: shadowOffset.width, y: shadowOffset.height)
                    .overlay(
                        borderColor.map { color in
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(color, lineWidth: borderWidth)
                        }
                    )
            )
    }
}

// MARK: - Button Style Modifiers

struct PrimaryButtonStyle: ViewModifier {
    let isEnabled: Bool
    let isLoading: Bool
    
    init(isEnabled: Bool = true, isLoading: Bool = false) {
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isEnabled ? AppTheme.Colors.primary : AppTheme.Colors.secondary)
            )
            .opacity(isLoading ? 0.7 : 1.0)
            .disabled(!isEnabled || isLoading)
            .overlay(
                isLoading ? ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8) : nil
            )
    }
}

struct SecondaryButtonStyle: ViewModifier {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.headline)
            .foregroundColor(isEnabled ? AppTheme.Colors.primary : AppTheme.Colors.secondary)
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(isEnabled ? AppTheme.Colors.primary : AppTheme.Colors.secondary, lineWidth: 1)
                    )
            )
            .disabled(!isEnabled)
    }
}

// MARK: - Sheet Presentation Modifier

struct StandardSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let sheetContent: () -> SheetContent
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                NavigationView {
                    sheetContent()
                }
            }
    }
}

// MARK: - Standard Toolbar Modifier

struct StandardToolbarModifier: ViewModifier {
    let title: String
    let displayMode: NavigationBarItem.TitleDisplayMode
    let showsDoneButton: Bool
    let showsRefreshButton: Bool
    let onDone: (() -> Void)?
    let onRefresh: (() -> Void)?
    
    init(
        title: String,
        displayMode: NavigationBarItem.TitleDisplayMode = .large,
        showsDoneButton: Bool = false,
        showsRefreshButton: Bool = false,
        onDone: (() -> Void)? = nil,
        onRefresh: (() -> Void)? = nil
    ) {
        self.title = title
        self.displayMode = displayMode
        self.showsDoneButton = showsDoneButton
        self.showsRefreshButton = showsRefreshButton
        self.onDone = onDone
        self.onRefresh = onRefresh
    }
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
            .toolbar {
                if showsDoneButton, let onDone = onDone {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done", action: onDone)
                    }
                }
                
                if showsRefreshButton, let onRefresh = onRefresh {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            onRefresh()
                        } label: {
                            Image(systemName: AppTheme.Icons.refresh)
                        }
                    }
                }
            }
    }
}

// MARK: - Text Field Style Modifier

struct StandardTextFieldStyle: ViewModifier {
    let cornerRadius: CGFloat
    let borderColor: Color
    let backgroundColor: Color
    
    init(
        cornerRadius: CGFloat = AppTheme.CornerRadius.small,
        borderColor: Color = AppTheme.Colors.border,
        backgroundColor: Color = AppTheme.Colors.cardBackground
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
    }
    
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Loading State Modifier

struct LoadingStateModifier: ViewModifier {
    let isLoading: Bool
    let loadingText: String
    
    init(isLoading: Bool, loadingText: String = "Loading...") {
        self.isLoading = isLoading
        self.loadingText = loadingText
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)
            
            if isLoading {
                VStack(spacing: AppTheme.Spacing.lg) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text(loadingText)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.secondary)
                }
                .padding(AppTheme.Spacing.xxl)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(AppTheme.Colors.cardBackground)
                        .shadow(color: AppTheme.Shadows.card, radius: AppTheme.Shadows.cardRadius)
                )
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(
        cornerRadius: CGFloat = AppTheme.CornerRadius.large,
        shadowColor: Color = AppTheme.Shadows.card,
        backgroundColor: Color = AppTheme.Colors.cardBackground,
        borderColor: Color? = nil
    ) -> some View {
        modifier(CardStyle(
            cornerRadius: cornerRadius,
            shadowColor: shadowColor,
            backgroundColor: backgroundColor,
            borderColor: borderColor
        ))
    }
    
    func primaryButton(isEnabled: Bool = true, isLoading: Bool = false) -> some View {
        modifier(PrimaryButtonStyle(isEnabled: isEnabled, isLoading: isLoading))
    }
    
    func secondaryButton(isEnabled: Bool = true) -> some View {
        modifier(SecondaryButtonStyle(isEnabled: isEnabled))
    }
    
    func standardSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(StandardSheetModifier(isPresented: isPresented, sheetContent: content))
    }
    
    func standardToolbar(
        title: String,
        displayMode: NavigationBarItem.TitleDisplayMode = .large,
        showsDoneButton: Bool = false,
        showsRefreshButton: Bool = false,
        onDone: (() -> Void)? = nil,
        onRefresh: (() -> Void)? = nil
    ) -> some View {
        modifier(StandardToolbarModifier(
            title: title,
            displayMode: displayMode,
            showsDoneButton: showsDoneButton,
            showsRefreshButton: showsRefreshButton,
            onDone: onDone,
            onRefresh: onRefresh
        ))
    }
    
    func standardTextField() -> some View {
        modifier(StandardTextFieldStyle())
    }
    
    func loadingState(isLoading: Bool, loadingText: String = "Loading...") -> some View {
        modifier(LoadingStateModifier(isLoading: isLoading, loadingText: loadingText))
    }
}
