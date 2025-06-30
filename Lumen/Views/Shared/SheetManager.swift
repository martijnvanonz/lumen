import SwiftUI

// MARK: - Sheet Management System

struct SheetManager {
    
    /// Present a standard sheet with navigation and done button
    static func standardSheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        showsDoneButton: Bool = true,
        showsRefreshButton: Bool = false,
        onDone: (() -> Void)? = nil,
        onRefresh: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        EmptyView()
            .sheet(isPresented: isPresented) {
                NavigationView {
                    content()
                        .standardToolbar(
                            title: title,
                            displayMode: .large,
                            showsDoneButton: showsDoneButton,
                            showsRefreshButton: showsRefreshButton,
                            onDone: onDone ?? { isPresented.wrappedValue = false },
                            onRefresh: onRefresh
                        )
                }
            }
    }
    
    /// Present a full screen cover with navigation
    static func fullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        showsDoneButton: Bool = true,
        onDone: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        EmptyView()
            .fullScreenCover(isPresented: isPresented) {
                NavigationView {
                    content()
                        .standardToolbar(
                            title: title,
                            displayMode: .large,
                            showsDoneButton: showsDoneButton,
                            onDone: onDone ?? { isPresented.wrappedValue = false }
                        )
                }
            }
    }
    
    /// Present a confirmation dialog with standard styling
    static func confirmationDialog<Content: View>(
        title: String,
        message: String? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping () -> Content
    ) -> some View {
        EmptyView()
            .confirmationDialog(
                title,
                isPresented: isPresented,
                titleVisibility: .visible
            ) {
                actions()
            } message: {
                if let message = message {
                    Text(message)
                }
            }
    }
    
    /// Present an alert with standard styling
    static func alert(
        title: String,
        message: String? = nil,
        isPresented: Binding<Bool>,
        primaryButton: Alert.Button? = nil,
        secondaryButton: Alert.Button? = nil
    ) -> some View {
        EmptyView()
            .alert(title, isPresented: isPresented) {
                if let primaryButton = primaryButton {
                    primaryButton
                }
                if let secondaryButton = secondaryButton {
                    secondaryButton
                }
                Button("OK") { }
            } message: {
                if let message = message {
                    Text(message)
                }
            }
    }
}

// MARK: - Sheet Presentation Styles

enum SheetPresentationStyle {
    case sheet
    case fullScreenCover
    case popover
}

// MARK: - Standard Sheet Wrapper

struct StandardSheetWrapper<Content: View>: View {
    let title: String
    let showsDoneButton: Bool
    let showsRefreshButton: Bool
    let onDone: (() -> Void)?
    let onRefresh: (() -> Void)?
    let content: Content
    
    @Environment(\.dismiss) private var dismiss
    
    init(
        title: String,
        showsDoneButton: Bool = true,
        showsRefreshButton: Bool = false,
        onDone: (() -> Void)? = nil,
        onRefresh: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showsDoneButton = showsDoneButton
        self.showsRefreshButton = showsRefreshButton
        self.onDone = onDone
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        NavigationView {
            content
                .standardToolbar(
                    title: title,
                    displayMode: .large,
                    showsDoneButton: showsDoneButton,
                    showsRefreshButton: showsRefreshButton,
                    onDone: onDone ?? { dismiss() },
                    onRefresh: onRefresh
                )
        }
    }
}

// MARK: - Modal Presentation Helper

struct ModalPresentation<Content: View>: ViewModifier {
    @Binding var isPresented: Bool
    let style: SheetPresentationStyle
    let title: String
    let showsDoneButton: Bool
    let onDone: (() -> Void)?
    let content: () -> Content
    
    func body(content: Content) -> some View {
        switch style {
        case .sheet:
            content
                .sheet(isPresented: $isPresented) {
                    StandardSheetWrapper(
                        title: title,
                        showsDoneButton: showsDoneButton,
                        onDone: onDone,
                        content: self.content
                    )
                }
        case .fullScreenCover:
            content
                .fullScreenCover(isPresented: $isPresented) {
                    StandardSheetWrapper(
                        title: title,
                        showsDoneButton: showsDoneButton,
                        onDone: onDone,
                        content: self.content
                    )
                }
        case .popover:
            content
                .popover(isPresented: $isPresented) {
                    StandardSheetWrapper(
                        title: title,
                        showsDoneButton: showsDoneButton,
                        onDone: onDone,
                        content: self.content
                    )
                }
        }
    }
}

// MARK: - View Extensions for Sheet Management

extension View {
    /// Present a modal with standard navigation
    func modal<Content: View>(
        isPresented: Binding<Bool>,
        style: SheetPresentationStyle = .sheet,
        title: String,
        showsDoneButton: Bool = true,
        onDone: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(ModalPresentation(
            isPresented: isPresented,
            style: style,
            title: title,
            showsDoneButton: showsDoneButton,
            onDone: onDone,
            content: content
        ))
    }
    
    /// Present a confirmation dialog with standard styling
    func confirmationDialog<Actions: View>(
        title: String,
        message: String? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping () -> Actions
    ) -> some View {
        confirmationDialog(
            title,
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            actions()
        } message: {
            if let message = message {
                Text(message)
            }
        }
    }
    
    /// Present a standard alert
    func standardAlert(
        title: String,
        message: String? = nil,
        isPresented: Binding<Bool>,
        primaryAction: (() -> Void)? = nil,
        primaryActionTitle: String = "OK",
        secondaryAction: (() -> Void)? = nil,
        secondaryActionTitle: String = "Cancel"
    ) -> some View {
        alert(title, isPresented: isPresented) {
            if let primaryAction = primaryAction {
                Button(primaryActionTitle, action: primaryAction)
            }
            if let secondaryAction = secondaryAction {
                Button(secondaryActionTitle, role: .cancel, action: secondaryAction)
            }
            if primaryAction == nil && secondaryAction == nil {
                Button("OK") { }
            }
        } message: {
            if let message = message {
                Text(message)
            }
        }
    }
}
