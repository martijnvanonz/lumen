import Foundation
import SwiftUI

/// Configuration manager for animated background settings
/// Handles persistence and provides default values for animation parameters
class AnimatedBackgroundConfiguration: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AnimatedBackgroundConfiguration()
    
    // MARK: - Published Properties
    
    @Published var animationSpeed: Double {
        didSet {
            UserDefaults.standard.set(animationSpeed, forKey: Keys.animationSpeed)
        }
    }
    
    @Published var noiseOpacity: Double {
        didSet {
            UserDefaults.standard.set(noiseOpacity, forKey: Keys.noiseOpacity)
        }
    }
    
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled)
        }
    }
    
    @Published var useHighPerformanceMode: Bool {
        didSet {
            UserDefaults.standard.set(useHighPerformanceMode, forKey: Keys.useHighPerformanceMode)
        }
    }
    
    // MARK: - Constants
    
    private enum Keys {
        static let animationSpeed = "AnimatedBackground.animationSpeed"
        static let noiseOpacity = "AnimatedBackground.noiseOpacity"
        static let isEnabled = "AnimatedBackground.isEnabled"
        static let useHighPerformanceMode = "AnimatedBackground.useHighPerformanceMode"
    }
    
    private enum Defaults {
        static let animationSpeed: Double = 1.0
        static let noiseOpacity: Double = 0.08
        static let isEnabled: Bool = true
        static let useHighPerformanceMode: Bool = false
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load saved values or use defaults
        self.animationSpeed = UserDefaults.standard.object(forKey: Keys.animationSpeed) as? Double ?? Defaults.animationSpeed
        self.noiseOpacity = UserDefaults.standard.object(forKey: Keys.noiseOpacity) as? Double ?? Defaults.noiseOpacity
        self.isEnabled = UserDefaults.standard.object(forKey: Keys.isEnabled) as? Bool ?? Defaults.isEnabled
        self.useHighPerformanceMode = UserDefaults.standard.object(forKey: Keys.useHighPerformanceMode) as? Bool ?? Defaults.useHighPerformanceMode
    }
    
    // MARK: - Public Methods
    
    /// Reset all settings to default values
    func resetToDefaults() {
        animationSpeed = Defaults.animationSpeed
        noiseOpacity = Defaults.noiseOpacity
        isEnabled = Defaults.isEnabled
        useHighPerformanceMode = Defaults.useHighPerformanceMode
    }
    
    /// Get optimized settings for low-end devices
    func applyLowEndDeviceOptimizations() {
        animationSpeed = 0.5  // Slower animation
        noiseOpacity = 0.04   // Less noise for better performance
        useHighPerformanceMode = false
    }
    
    /// Get optimized settings for high-end devices
    func applyHighEndDeviceOptimizations() {
        animationSpeed = 1.2  // Slightly faster animation
        noiseOpacity = 0.12   // More visible noise
        useHighPerformanceMode = true
    }
    
    /// Detect device performance tier and apply appropriate settings
    func applyDeviceOptimizations() {
        let deviceTier = DevicePerformanceTier.current
        
        switch deviceTier {
        case .low:
            applyLowEndDeviceOptimizations()
        case .medium:
            // Keep defaults
            break
        case .high:
            applyHighEndDeviceOptimizations()
        }
    }
}

// MARK: - Device Performance Detection

enum DevicePerformanceTier {
    case low
    case medium
    case high
    
    static var current: DevicePerformanceTier {
        let modelName = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        // Simple heuristic based on iOS version and available memory
        if #available(iOS 17.0, *) {
            // iOS 17+ devices are generally more capable
            return .high
        } else if #available(iOS 15.0, *) {
            return .medium
        } else {
            return .low
        }
    }
}

// MARK: - Configuration View Modifier

struct AnimatedBackgroundConfigured: ViewModifier {
    @StateObject private var config = AnimatedBackgroundConfiguration.shared
    
    func body(content: Content) -> some View {
        content
            .environmentObject(config)
    }
}

extension View {
    /// Apply animated background configuration to the view hierarchy
    func animatedBackgroundConfigured() -> some View {
        modifier(AnimatedBackgroundConfigured())
    }
}

// MARK: - Configured Background Views

/// Animated gradient background that uses global configuration
struct ConfiguredAnimatedGradientBackground: View {
    @EnvironmentObject private var config: AnimatedBackgroundConfiguration
    
    var body: some View {
        Group {
            if config.isEnabled {
                UniversalAnimatedGradientBackground(
                    animationSpeed: config.animationSpeed,
                    noiseOpacity: config.noiseOpacity
                )
            } else {
                // Static fallback
                SwiftUIGradientBackground()
            }
        }
    }
}

/// Fixed gradient container that uses global configuration
struct ConfiguredFixedGradientContainer<Content: View>: View {
    @EnvironmentObject private var config: AnimatedBackgroundConfiguration
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Configured animated background
            ConfiguredAnimatedGradientBackground()
            
            // Content overlay
            content
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Configured Animated Background")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
        
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.9))
            .frame(height: 120)
            .padding(.horizontal)
            .shadow(radius: 10)
        
        Spacer()
    }
    .padding(.top, 50)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ConfiguredAnimatedGradientBackground())
    .animatedBackgroundConfigured()
}
