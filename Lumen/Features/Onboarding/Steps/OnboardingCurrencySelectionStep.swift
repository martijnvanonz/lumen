import SwiftUI
import BreezSDKLiquid

/// Currency selection step for onboarding flow
/// Uses new design system and improved currency selection UI
struct OnboardingCurrencySelectionStep: View {
    
    // MARK: - Configuration
    
    let onContinue: () -> Void
    
    // MARK: - State
    
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var searchText = ""
    
    // MARK: - Computed Properties
    
    private var filteredCurrencies: [FiatCurrency] {
        if searchText.isEmpty {
            return currencyManager.availableCurrencies
        } else {
            return currencyManager.availableCurrencies.filter { currency in
                currency.id.localizedCaseInsensitiveContains(searchText) ||
                currency.info.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var canContinue: Bool {
        currencyManager.selectedCurrency != nil
    }
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Header
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: "globe")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.warning)
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Choose Your Currency")
                        .font(DesignSystem.Typography.largeTitle(weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Select your preferred currency for displaying Bitcoin values. You can change this later in settings.")
                        .font(DesignSystem.Typography.body(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .padding(.top, DesignSystem.Spacing.lg)
            
            // Search and currency selection
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Search bar
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    TextField("Search currencies...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                
                // Currency grid
                if currencyManager.isLoadingCurrencies {
                    LoadingStateView.minimal("Loading currencies...")
                        .frame(height: 200)
                } else {
                    currencyGrid
                }
            }
            
            Spacer()
            
            // Continue button
            StandardButton(title: "Continue", action: onContinue)
                .style(canContinue ? .primary : .secondary)
                .enabled(canContinue)
                .size(.large)
                .enabled(canContinue)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .onAppear {
            loadCurrenciesIfNeeded()
        }
    }
    
    // MARK: - Currency Grid
    
    @ViewBuilder
    private var currencyGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.sm), count: 3),
                spacing: DesignSystem.Spacing.sm
            ) {
                ForEach(filteredCurrencies, id: \.id) { currency in
                    CurrencySelectionCard(
                        currency: currency,
                        isSelected: currencyManager.selectedCurrency?.id == currency.id,
                        onTap: {
                            currencyManager.setSelectedCurrency(currency)
                        }
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .frame(maxHeight: 300)
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrenciesIfNeeded() {
        if currencyManager.availableCurrencies.isEmpty {
            Task {
                await currencyManager.loadAvailableCurrencies(setDefaultIfNone: false)
            }
        }
    }
}

// MARK: - Currency Selection Card

/// Individual currency selection card component
struct CurrencySelectionCard: View {
    let currency: FiatCurrency
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Currency icon/flag placeholder
                Image(systemName: currency.icon)
                    .font(DesignSystem.Typography.title2())
                
                // Currency code
                Text(currency.id.uppercased())
                    .font(DesignSystem.Typography.subheadline(weight: .semibold))
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                
                // Currency name (truncated)
                Text(currency.info.name)
                    .font(DesignSystem.Typography.caption(weight: .regular))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(isSelected ? DesignSystem.Colors.warning : DesignSystem.Colors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(
                                isSelected ? DesignSystem.Colors.warning : DesignSystem.Colors.borderPrimary,
                                lineWidth: isSelected ? 2 : AppConstants.UI.borderWidthThin
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(DesignSystem.Animation.fast, value: isSelected)
        .animation(DesignSystem.Animation.fast, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    @State private var isPressed = false
}

// MARK: - Enhanced Currency Selection

/// Enhanced currency selection with popular currencies section
struct EnhancedOnboardingCurrencySelectionStep: View {
    
    // MARK: - Configuration
    
    let onContinue: () -> Void
    
    // MARK: - State
    
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var searchText = ""
    @State private var showingAllCurrencies = false
    
    // MARK: - Popular Currencies
    
    private let popularCurrencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD"]
    
    // MARK: - Computed Properties
    
    private var filteredPopularCurrencies: [FiatCurrency] {
        currencyManager.availableCurrencies.filter { currency in
            popularCurrencies.contains(currency.id.uppercased())
        }
    }
    
    private var filteredAllCurrencies: [FiatCurrency] {
        if searchText.isEmpty {
            return currencyManager.availableCurrencies
        } else {
            return currencyManager.availableCurrencies.filter { currency in
                currency.id.localizedCaseInsensitiveContains(searchText) ||
                currency.info.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var canContinue: Bool {
        currencyManager.selectedCurrency != nil
    }
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Header
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "globe")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.warning)
                
                Text("Choose Your Currency")
                    .font(DesignSystem.Typography.title2(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Select your preferred currency for displaying Bitcoin values")
                    .font(DesignSystem.Typography.subheadline(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.md)
            }
            .padding(.top, DesignSystem.Spacing.md)
            
            if currencyManager.isLoadingCurrencies {
                LoadingStateView.minimal("Loading currencies...")
                    .frame(maxHeight: .infinity)
            } else {
                // Currency selection content
                VStack(spacing: DesignSystem.Spacing.lg) {
                    if !showingAllCurrencies {
                        // Popular currencies section
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Text("Popular Currencies")
                                .font(DesignSystem.Typography.headline(weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.sm), count: 3),
                                spacing: DesignSystem.Spacing.sm
                            ) {
                                ForEach(filteredPopularCurrencies, id: \.id) { currency in
                                    CurrencySelectionCard(
                                        currency: currency,
                                        isSelected: currencyManager.selectedCurrency?.id == currency.id,
                                        onTap: {
                                            currencyManager.setSelectedCurrency(currency)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Show all currencies button
                            StandardButton(title: "Show All Currencies", action: {
                                showingAllCurrencies = true
                            })
                            .style(.outline)
                            .size(.regular)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                    } else {
                        // All currencies with search
                        VStack(spacing: DesignSystem.Spacing.md) {
                            // Search bar
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                TextField("Search currencies...", text: $searchText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // All currencies grid
                            ScrollView {
                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.sm), count: 3),
                                    spacing: DesignSystem.Spacing.sm
                                ) {
                                    ForEach(filteredAllCurrencies, id: \.id) { currency in
                                        CurrencySelectionCard(
                                            currency: currency,
                                            isSelected: currencyManager.selectedCurrency?.id == currency.id,
                                            onTap: {
                                                currencyManager.setSelectedCurrency(currency)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                            }
                            
                            // Back to popular button
                            StandardButton(title: "Back to Popular", action: {
                                showingAllCurrencies = false
                                searchText = ""
                            })
                            .style(.outline)
                            .size(.compact)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Continue button
            StandardButton(title: "Continue", action: onContinue)
                .style(canContinue ? .primary : .secondary)
                .enabled(canContinue)
                .size(.large)
                .enabled(canContinue)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.lg)
        }
        .onAppear {
            loadCurrenciesIfNeeded()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrenciesIfNeeded() {
        if currencyManager.availableCurrencies.isEmpty {
            Task {
                await currencyManager.loadAvailableCurrencies(setDefaultIfNone: false)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        OnboardingCurrencySelectionStep {
            print("Continue tapped")
        }
    }
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                DesignSystem.Colors.primary.opacity(0.1),
                DesignSystem.Colors.secondary.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
