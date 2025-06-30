import SwiftUI

// MARK: - Comprehensive Settings View

struct SettingsView: View {
    @StateObject private var configSystem = ConfigurationSystem.shared
    @StateObject private var errorHandler = AdvancedErrorHandler.shared
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAbout = false
    @State private var showingErrorHistory = false
    @State private var showingPerformanceMetrics = false
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
                userProfileSection
                
                // Display Settings
                displaySettingsSection
                
                // Security Settings
                securitySettingsSection
                
                // Notification Settings
                notificationSettingsSection
                
                // Privacy Settings
                privacySettingsSection
                
                // Advanced Settings
                advancedSettingsSection
                
                // Debug Settings (if enabled)
                if configSystem.currentEnvironment.isDebugEnabled {
                    debugSettingsSection
                }
                
                // About Section
                aboutSection
            }
            .standardToolbar(
                title: "Settings",
                displayMode: .large,
                showsDoneButton: true,
                onDone: { dismiss() }
            )
        }
        .configuredTheme()
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingErrorHistory) {
            ErrorHistoryView()
        }
        .sheet(isPresented: $showingPerformanceMetrics) {
            PerformanceMetricsView()
        }
        .confirmationDialog(
            "Reset Settings",
            isPresented: $showingResetConfirmation
        ) {
            Button("Reset All Settings", role: .destructive) {
                configSystem.resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
    }
    
    // MARK: - User Profile Section
    
    private var userProfileSection: some View {
        FormSection(title: "Profile") {
            HStack(spacing: AppTheme.Spacing.md) {
                // Profile image placeholder
                Circle()
                    .fill(AppTheme.Colors.secondary.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.Colors.secondary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lightning Wallet")
                        .font(AppTheme.Typography.headline)
                    
                    Text("Powered by Breez SDK")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.sm)
        }
    }
    
    // MARK: - Display Settings Section
    
    private var displaySettingsSection: some View {
        FormSection(title: "Display") {
            // Theme selection
            SelectionRow(
                title: "Theme",
                icon: "paintbrush.fill",
                options: AppTheme.Mode.allCases,
                selection: $configSystem.userPreferences.display.theme
            ) { mode in
                mode.displayName
            }
            
            // Font size
            SelectionRow(
                title: "Font Size",
                icon: "textformat.size",
                options: DisplaySettings.FontSize.allCases,
                selection: $configSystem.userPreferences.display.fontSize
            ) { size in
                size.displayName
            }
            
            // Currency
            SelectionRow(
                title: "Currency",
                icon: "dollarsign.circle.fill",
                options: UserPreferences.Currency.allCases,
                selection: $configSystem.userPreferences.currency
            ) { currency in
                "\(currency.symbol) \(currency.displayName)"
            }
            
            // Display toggles
            ToggleRow(
                title: "Show Amounts in Sats",
                subtitle: "Display amounts in satoshis instead of Bitcoin",
                icon: "bitcoinsign.circle.fill",
                isOn: $configSystem.userPreferences.display.showAmountsInSats
            )
            
            ToggleRow(
                title: "Show USD Equivalent",
                subtitle: "Display USD value alongside Bitcoin amounts",
                icon: "dollarsign.circle",
                isOn: $configSystem.userPreferences.display.showUSDEquivalent
            )
            
            ToggleRow(
                title: "Animations",
                subtitle: "Enable smooth animations throughout the app",
                icon: "sparkles",
                isOn: $configSystem.userPreferences.display.animationsEnabled
            )
            
            ToggleRow(
                title: "Haptic Feedback",
                subtitle: "Feel vibrations for button taps and actions",
                icon: "iphone.radiowaves.left.and.right",
                isOn: $configSystem.userPreferences.display.hapticFeedbackEnabled
            )
        }
    }
    
    // MARK: - Security Settings Section
    
    private var securitySettingsSection: some View {
        FormSection(title: "Security") {
            ToggleRow(
                title: "Biometric Authentication",
                subtitle: "Use Face ID or Touch ID to secure your wallet",
                icon: AppTheme.Icons.faceID,
                isOn: $configSystem.userPreferences.security.biometricEnabled
            )
            
            ToggleRow(
                title: "Auto Lock",
                subtitle: "Automatically lock the app when inactive",
                icon: AppTheme.Icons.lock,
                isOn: $configSystem.userPreferences.security.autoLockEnabled
            )
            
            if configSystem.userPreferences.security.autoLockEnabled {
                SelectionRow(
                    title: "Auto Lock Timeout",
                    icon: "timer",
                    options: SecuritySettings.AutoLockTimeout.allCases,
                    selection: Binding(
                        get: { 
                            SecuritySettings.AutoLockTimeout(rawValue: configSystem.userPreferences.security.autoLockTimeout) ?? .fiveMinutes
                        },
                        set: { 
                            configSystem.userPreferences.security.autoLockTimeout = $0.rawValue
                        }
                    )
                ) { timeout in
                    timeout.displayName
                }
            }
            
            ToggleRow(
                title: "Require Biometric for Payments",
                subtitle: "Authenticate before sending payments",
                icon: "creditcard.fill",
                isOn: $configSystem.userPreferences.security.requireBiometricForPayments
            )
            
            ToggleRow(
                title: "Hide Balance on Lock Screen",
                subtitle: "Don't show wallet balance in notifications",
                icon: "eye.slash.fill",
                isOn: $configSystem.userPreferences.security.showBalanceOnLockScreen
            )
            
            ToggleRow(
                title: "Allow Screenshots",
                subtitle: "Enable taking screenshots within the app",
                icon: "camera.fill",
                isOn: $configSystem.userPreferences.security.allowScreenshots
            )
        }
    }
    
    // MARK: - Notification Settings Section
    
    private var notificationSettingsSection: some View {
        FormSection(title: "Notifications") {
            ToggleRow(
                title: "Payment Received",
                subtitle: "Get notified when you receive payments",
                icon: "arrow.down.circle.fill",
                isOn: $configSystem.userPreferences.notifications.paymentReceived
            )
            
            ToggleRow(
                title: "Payment Sent",
                subtitle: "Get notified when payments are sent",
                icon: "arrow.up.circle.fill",
                isOn: $configSystem.userPreferences.notifications.paymentSent
            )
            
            ToggleRow(
                title: "Payment Failed",
                subtitle: "Get notified when payments fail",
                icon: "xmark.circle.fill",
                isOn: $configSystem.userPreferences.notifications.paymentFailed
            )
            
            ToggleRow(
                title: "Network Status",
                subtitle: "Get notified about connection issues",
                icon: "wifi",
                isOn: $configSystem.userPreferences.notifications.networkStatus
            )
            
            ToggleRow(
                title: "Security Alerts",
                subtitle: "Get notified about security events",
                icon: "shield.fill",
                isOn: $configSystem.userPreferences.notifications.securityAlerts
            )
            
            Divider()
            
            ToggleRow(
                title: "Sound",
                subtitle: "Play sounds for notifications",
                icon: "speaker.wave.2.fill",
                isOn: $configSystem.userPreferences.notifications.soundEnabled
            )
            
            ToggleRow(
                title: "Vibration",
                subtitle: "Vibrate for notifications",
                icon: "iphone.radiowaves.left.and.right",
                isOn: $configSystem.userPreferences.notifications.vibrationEnabled
            )
        }
    }
    
    // MARK: - Privacy Settings Section
    
    private var privacySettingsSection: some View {
        FormSection(title: "Privacy") {
            ToggleRow(
                title: "Analytics",
                subtitle: "Help improve the app by sharing usage data",
                icon: "chart.bar.fill",
                isOn: $configSystem.userPreferences.privacy.analyticsEnabled
            )
            
            ToggleRow(
                title: "Crash Reporting",
                subtitle: "Automatically report crashes to help fix bugs",
                icon: "exclamationmark.triangle.fill",
                isOn: $configSystem.userPreferences.privacy.crashReportingEnabled
            )
        }
    }
    
    // MARK: - Advanced Settings Section
    
    private var advancedSettingsSection: some View {
        FormSection(title: "Advanced") {
            NavigationLink("Feature Flags") {
                FeatureFlagsView()
            }
            
            NavigationLink("Error History") {
                ErrorHistoryView()
            }
            
            if configSystem.currentEnvironment.isDebugEnabled {
                NavigationLink("Performance Metrics") {
                    PerformanceMetricsView()
                }
            }
            
            Button("Reset All Settings") {
                showingResetConfirmation = true
            }
            .foregroundColor(AppTheme.Colors.error)
        }
    }
    
    // MARK: - Debug Settings Section
    
    private var debugSettingsSection: some View {
        FormSection(title: "Debug") {
            SelectionRow(
                title: "Environment",
                icon: "gear",
                options: ConfigurationSystem.Environment.allCases,
                selection: $configSystem.currentEnvironment
            ) { env in
                env.displayName
            }
            
            ToggleRow(
                title: "Debug Mode",
                subtitle: "Enable debug features and logging",
                icon: "ladybug.fill",
                isOn: $configSystem.featureFlags.debugMode
            )
            
            ToggleRow(
                title: "Performance Monitoring",
                subtitle: "Track app performance metrics",
                icon: "speedometer",
                isOn: $configSystem.featureFlags.performanceMonitoring
            )
            
            ToggleRow(
                title: "Network Logging",
                subtitle: "Log all network requests and responses",
                icon: "network",
                isOn: $configSystem.featureFlags.networkLogging
            )
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        FormSection(title: "About") {
            InfoRow(label: "Version", value: Bundle.main.appVersion)
            InfoRow(label: "Build", value: Bundle.main.buildNumber)
            InfoRow(label: "Environment", value: configSystem.currentEnvironment.displayName)
            
            NavigationLink("About Lumen") {
                AboutView()
            }
            
            NavigationLink("Privacy Policy") {
                WebView(url: "https://lumen.app/privacy")
            }
            
            NavigationLink("Terms of Service") {
                WebView(url: "https://lumen.app/terms")
            }
        }
    }
}

// MARK: - Feature Flags View

struct FeatureFlagsView: View {
    @StateObject private var configSystem = ConfigurationSystem.shared
    
    var body: some View {
        List {
            FormSection(title: "Payment Features") {
                ToggleRow(
                    title: "Advanced Payment Options",
                    subtitle: "Enable advanced payment features",
                    isOn: $configSystem.featureFlags.advancedPaymentOptions
                )
                
                ToggleRow(
                    title: "Multi-Currency Support",
                    subtitle: "Support for multiple currencies",
                    isOn: $configSystem.featureFlags.multiCurrencySupport
                )
                
                ToggleRow(
                    title: "NFC Payments",
                    subtitle: "Enable Near Field Communication payments",
                    isOn: $configSystem.featureFlags.nfcPayments
                )
            }
            
            FormSection(title: "Interface Features") {
                ToggleRow(
                    title: "Advanced Charts",
                    subtitle: "Show detailed payment analytics",
                    isOn: $configSystem.featureFlags.advancedCharts
                )
                
                ToggleRow(
                    title: "Smart Notifications",
                    subtitle: "AI-powered notification insights",
                    isOn: $configSystem.featureFlags.smartNotifications
                )
                
                ToggleRow(
                    title: "Voice Commands",
                    subtitle: "Control app with voice commands",
                    isOn: $configSystem.featureFlags.voiceCommands
                )
            }
            
            FormSection(title: "Experimental") {
                ToggleRow(
                    title: "Experimental Features",
                    subtitle: "Enable bleeding-edge features (may be unstable)",
                    isOn: $configSystem.featureFlags.experimentalFeatures
                )
            }
        }
        .navigationTitle("Feature Flags")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Performance Metrics View

struct PerformanceMetricsView: View {
    @StateObject private var monitor = PerformanceMonitor.shared
    
    var body: some View {
        List {
            ForEach(monitor.metrics.allOperations(), id: \.self) { operation in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(operation)
                        .font(AppTheme.Typography.headline)
                    
                    if let avg = monitor.metrics.averageDuration(for: operation) {
                        HStack {
                            Text("Average:")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(String(format: "%.3f", avg))s")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(colorForDuration(avg))
                        }
                    }
                    
                    if let max = monitor.metrics.maxDuration(for: operation) {
                        HStack {
                            Text("Maximum:")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(String(format: "%.3f", max))s")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
        .navigationTitle("Performance Metrics")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            Button("Clear") {
                monitor.metrics = PerformanceMetrics()
            }
        }
    }
    
    private func colorForDuration(_ duration: TimeInterval) -> Color {
        if duration <= PerformanceConstants.Thresholds.fastRender {
            return AppTheme.Colors.success
        } else if duration <= PerformanceConstants.Thresholds.acceptableRender {
            return AppTheme.Colors.warning
        } else {
            return AppTheme.Colors.error
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // App icon and name
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppTheme.Colors.lightning)
                    
                    Text("Lumen")
                        .font(AppTheme.Typography.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Lightning Wallet")
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(.secondary)
                }
                
                // Description
                Text("Lumen is a modern Lightning Network wallet built with SwiftUI and powered by the Breez SDK. Send and receive Bitcoin payments instantly with low fees.")
                    .font(AppTheme.Typography.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Features
                VStack(spacing: AppTheme.Spacing.lg) {
                    FeatureRow(
                        icon: AppTheme.Icons.lightning,
                        title: "Lightning Fast",
                        description: "Instant Bitcoin payments with minimal fees",
                        iconColor: AppTheme.Colors.lightning
                    )
                    
                    FeatureRow(
                        icon: AppTheme.Icons.shield,
                        title: "Secure by Design",
                        description: "Protected by biometric authentication and encryption",
                        iconColor: AppTheme.Colors.success
                    )
                    
                    FeatureRow(
                        icon: "icloud.fill",
                        title: "iCloud Backup",
                        description: "Seamlessly restore your wallet on any device",
                        iconColor: AppTheme.Colors.info
                    )
                }
                .padding(.horizontal)
                
                // Version info
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Version \(Bundle.main.appVersion)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Build \(Bundle.main.buildNumber)")
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Web View

struct WebView: View {
    let url: String
    
    var body: some View {
        // In a real implementation, you'd use WKWebView
        VStack {
            Text("Web content would load here")
            Text(url)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Web View")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Bundle Extensions

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}
