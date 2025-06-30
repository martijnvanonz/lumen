import SwiftUI

// MARK: - Standard Text Field

struct StandardTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let autocapitalization: TextInputAutocapitalization
    let isEnabled: Bool
    let errorMessage: String?
    let maxLength: Int?
    
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .sentences,
        isEnabled: Bool = true,
        errorMessage: String? = nil,
        maxLength: Int? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
        self.isEnabled = isEnabled
        self.errorMessage = errorMessage
        self.maxLength = maxLength
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(.primary)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(1...6)
                }
            }
            .focused($isFocused)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(autocapitalization)
            .disabled(!isEnabled)
            .onChange(of: text) { _, newValue in
                if let maxLength = maxLength, newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
            }
            .standardTextField()
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(
                        errorMessage != nil ? AppTheme.Colors.error :
                        isFocused ? AppTheme.Colors.focusedBorder : AppTheme.Colors.border,
                        lineWidth: 1
                    )
            )
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.error)
            }
            
            if let maxLength = maxLength {
                HStack {
                    Spacer()
                    Text("\(text.count)/\(maxLength)")
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Amount Input Field

struct AmountInputField: View {
    let title: String
    @Binding var amount: String
    let currency: String
    let isEnabled: Bool
    let errorMessage: String?
    let onAmountChanged: ((String) -> Void)?
    
    @FocusState private var isFocused: Bool
    
    init(
        title: String = "Amount",
        amount: Binding<String>,
        currency: String = "sats",
        isEnabled: Bool = true,
        errorMessage: String? = nil,
        onAmountChanged: ((String) -> Void)? = nil
    ) {
        self.title = title
        self._amount = amount
        self.currency = currency
        self.isEnabled = isEnabled
        self.errorMessage = errorMessage
        self.onAmountChanged = onAmountChanged
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(.primary)
            
            HStack {
                TextField("0", text: $amount)
                    .focused($isFocused)
                    .keyboardType(.numberPad)
                    .disabled(!isEnabled)
                    .onChange(of: amount) { _, newValue in
                        // Filter to only allow numbers
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            amount = filtered
                        }
                        onAmountChanged?(filtered)
                    }
                
                Text(currency)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.trailing, AppTheme.Spacing.sm)
            }
            .standardTextField()
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(
                        errorMessage != nil ? AppTheme.Colors.error :
                        isFocused ? AppTheme.Colors.focusedBorder : AppTheme.Colors.border,
                        lineWidth: 1
                    )
            )
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.error)
            }
        }
    }
}

// MARK: - Description Input Field

struct DescriptionInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let maxLength: Int
    let isEnabled: Bool
    
    @FocusState private var isFocused: Bool
    
    init(
        title: String = "Description",
        placeholder: String = "Optional description...",
        text: Binding<String>,
        maxLength: Int = 200,
        isEnabled: Bool = true
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.maxLength = maxLength
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text, axis: .vertical)
                .focused($isFocused)
                .lineLimit(3...6)
                .disabled(!isEnabled)
                .onChange(of: text) { _, newValue in
                    if newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                }
                .standardTextField()
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(
                            isFocused ? AppTheme.Colors.focusedBorder : AppTheme.Colors.border,
                            lineWidth: 1
                        )
                )
            
            HStack {
                Spacer()
                Text("\(text.count)/\(maxLength)")
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Form Section

struct FormSection<Content: View>: View {
    let title: String?
    let footer: String?
    let content: Content
    
    init(
        title: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            if let title = title {
                SectionHeader(title: title)
            }
            
            VStack(spacing: AppTheme.Spacing.lg) {
                content
            }
            .padding(AppTheme.Spacing.lg)
            .cardStyle()
            
            if let footer = footer {
                Text(footer)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }
        }
    }
}

// MARK: - Toggle Row

struct ToggleRow: View {
    let title: String
    let subtitle: String?
    let icon: String?
    @Binding var isOn: Bool
    let isEnabled: Bool
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isOn: Binding<Bool>,
        isEnabled: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._isOn = isOn
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 24)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .disabled(!isEnabled)
        }
    }
}

// MARK: - Selection Row

struct SelectionRow<T: Hashable>: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let options: [T]
    @Binding var selection: T
    let displayName: (T) -> String
    
    @State private var showingPicker = false
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        options: [T],
        selection: Binding<T>,
        displayName: @escaping (T) -> String
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.options = options
        self._selection = selection
        self.displayName = displayName
    }
    
    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Colors.primary)
                        .frame(width: 24)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(displayName(selection))
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog(title, isPresented: $showingPicker) {
            ForEach(options, id: \.self) { option in
                Button(displayName(option)) {
                    selection = option
                }
            }
        }
    }
}
