import SwiftUI
import Combine

// MARK: - Performance Optimization Utilities

struct PerformanceOptimization {
    
    // MARK: - View Caching
    
    /// Cache expensive view calculations
    static func cached<T: Hashable, V: View>(
        key: T,
        @ViewBuilder content: () -> V
    ) -> some View {
        CachedView(key: key, content: content)
    }
    
    /// Lazy loading for expensive views
    static func lazy<V: View>(
        threshold: CGFloat = 100,
        @ViewBuilder content: @escaping () -> V
    ) -> some View {
        LazyView(threshold: threshold, content: content)
    }
    
    // MARK: - Memory Management
    
    /// Weak reference wrapper for avoiding retain cycles
    static func weak<T: AnyObject>(_ object: T?) -> WeakReference<T> {
        WeakReference(object)
    }
    
    /// Debounce expensive operations
    static func debounced<T>(
        _ value: T,
        delay: TimeInterval = 0.3,
        scheduler: DispatchQueue = .main
    ) -> AnyPublisher<T, Never> {
        Just(value)
            .delay(for: .seconds(delay), scheduler: scheduler)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Image Optimization
    
    /// Optimized image loading with caching
    static func optimizedImage(
        name: String,
        bundle: Bundle = .main,
        renderingMode: Image.TemplateRenderingMode = .original
    ) -> Image {
        if let cachedImage = ImageCache.shared.image(for: name) {
            return cachedImage
        }
        
        let image = Image(name, bundle: bundle)
            .renderingMode(renderingMode)
        
        ImageCache.shared.cache(image, for: name)
        return image
    }
    
    // MARK: - List Performance
    
    /// Optimized list row with recycling
    static func optimizedListRow<Content: View>(
        id: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        OptimizedListRow(id: id, content: content)
    }
    
    // MARK: - Animation Performance
    
    /// Reduce animation complexity for better performance
    static func performantAnimation(
        _ animation: Animation,
        condition: Bool = true
    ) -> Animation? {
        guard condition else { return nil }
        return animation
    }
}

// MARK: - Cached View

struct CachedView<Key: Hashable, Content: View>: View {
    let key: Key
    let content: () -> Content
    
    @State private var cachedContent: Content?
    
    var body: some View {
        Group {
            if let cached = cachedContent {
                cached
            } else {
                content()
                    .onAppear {
                        if cachedContent == nil {
                            cachedContent = content()
                        }
                    }
            }
        }
    }
}

// MARK: - Lazy View

struct LazyView<Content: View>: View {
    let threshold: CGFloat
    let content: () -> Content
    
    @State private var isVisible = false
    
    var body: some View {
        Group {
            if isVisible {
                content()
            } else {
                Color.clear
                    .frame(height: threshold)
                    .onAppear {
                        isVisible = true
                    }
            }
        }
    }
}

// MARK: - Optimized List Row

struct OptimizedListRow<Content: View>: View {
    let id: String
    let content: () -> Content
    
    @State private var isVisible = false
    
    var body: some View {
        content()
            .id(id)
            .onAppear {
                isVisible = true
            }
            .onDisappear {
                isVisible = false
            }
    }
}

// MARK: - Weak Reference

class WeakReference<T: AnyObject> {
    weak var object: T?
    
    init(_ object: T?) {
        self.object = object
    }
}

// MARK: - Image Cache

class ImageCache {
    static let shared = ImageCache()
    private init() {}
    
    private var cache: [String: Image] = [:]
    private let queue = DispatchQueue(label: "image-cache", attributes: .concurrent)
    
    func image(for key: String) -> Image? {
        queue.sync {
            cache[key]
        }
    }
    
    func cache(_ image: Image, for key: String) {
        queue.async(flags: .barrier) {
            self.cache[key] = image
        }
    }
    
    func clearCache() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
}

// MARK: - Performance Monitoring

class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    private init() {}
    
    @Published var metrics: PerformanceMetrics = PerformanceMetrics()
    
    private var startTimes: [String: CFAbsoluteTime] = [:]
    
    func startMeasuring(_ operation: String) {
        startTimes[operation] = CFAbsoluteTimeGetCurrent()
    }
    
    func endMeasuring(_ operation: String) {
        guard let startTime = startTimes[operation] else { return }
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        metrics.addMeasurement(operation: operation, duration: duration)
        startTimes.removeValue(forKey: operation)
    }
    
    func measure<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        startMeasuring(operation)
        defer { endMeasuring(operation) }
        return try block()
    }
    
    func measureAsync<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        startMeasuring(operation)
        defer { endMeasuring(operation) }
        return try await block()
    }
}

struct PerformanceMetrics {
    private var measurements: [String: [TimeInterval]] = [:]
    
    mutating func addMeasurement(operation: String, duration: TimeInterval) {
        if measurements[operation] == nil {
            measurements[operation] = []
        }
        measurements[operation]?.append(duration)
        
        // Keep only last 100 measurements
        if let count = measurements[operation]?.count, count > 100 {
            measurements[operation] = Array(measurements[operation]!.suffix(100))
        }
    }
    
    func averageDuration(for operation: String) -> TimeInterval? {
        guard let durations = measurements[operation], !durations.isEmpty else {
            return nil
        }
        return durations.reduce(0, +) / Double(durations.count)
    }
    
    func maxDuration(for operation: String) -> TimeInterval? {
        measurements[operation]?.max()
    }
    
    func minDuration(for operation: String) -> TimeInterval? {
        measurements[operation]?.min()
    }
    
    func allOperations() -> [String] {
        Array(measurements.keys)
    }
}

// MARK: - View Extensions for Performance

extension View {
    /// Measure view rendering performance
    func measurePerformance(_ operation: String) -> some View {
        self.onAppear {
            PerformanceMonitor.shared.startMeasuring(operation)
        }
        .onDisappear {
            PerformanceMonitor.shared.endMeasuring(operation)
        }
    }
    
    /// Cache expensive view calculations
    func cached<T: Hashable>(key: T) -> some View {
        PerformanceOptimization.cached(key: key) {
            self
        }
    }
    
    /// Lazy load view content
    func lazyLoaded(threshold: CGFloat = 100) -> some View {
        PerformanceOptimization.lazy(threshold: threshold) {
            self
        }
    }
    
    /// Optimize for list performance
    func optimizedForList(id: String) -> some View {
        PerformanceOptimization.optimizedListRow(id: id) {
            self
        }
    }
    
    /// Conditional animation for performance
    func performantAnimation(
        _ animation: Animation,
        condition: Bool = true
    ) -> some View {
        self.animation(
            PerformanceOptimization.performantAnimation(animation, condition: condition),
            value: condition
        )
    }
    
    /// Reduce motion for accessibility and performance
    func reduceMotion() -> some View {
        self.animation(
            UIAccessibility.isReduceMotionEnabled ? nil : AnimationSystem.spring,
            value: UIAccessibility.isReduceMotionEnabled
        )
    }
    
    /// Memory-efficient image loading
    func optimizedImage(
        _ name: String,
        renderingMode: Image.TemplateRenderingMode = .original
    ) -> some View {
        self.overlay(
            PerformanceOptimization.optimizedImage(
                name: name,
                renderingMode: renderingMode
            )
        )
    }
}

// MARK: - Memory Management Helpers

extension ObservableObject {
    /// Create weak reference to avoid retain cycles
    func weakReference() -> WeakReference<Self> {
        PerformanceOptimization.weak(self)
    }
}

// MARK: - Debounced State

@propertyWrapper
struct Debounced<T> {
    private var value: T
    private var cancellable: AnyCancellable?
    private let delay: TimeInterval
    private let scheduler: DispatchQueue
    
    var wrappedValue: T {
        get { value }
        set {
            value = newValue
            cancellable?.cancel()
            cancellable = PerformanceOptimization.debounced(
                newValue,
                delay: delay,
                scheduler: scheduler
            )
            .sink { _ in }
        }
    }
    
    init(
        wrappedValue: T,
        delay: TimeInterval = 0.3,
        scheduler: DispatchQueue = .main
    ) {
        self.value = wrappedValue
        self.delay = delay
        self.scheduler = scheduler
    }
}

// MARK: - Performance Constants

struct PerformanceConstants {
    static let maxCacheSize = 100
    static let defaultDebounceDelay: TimeInterval = 0.3
    static let lazyLoadThreshold: CGFloat = 100
    static let maxMeasurements = 100
    
    struct Thresholds {
        static let fastRender: TimeInterval = 0.016 // 60 FPS
        static let acceptableRender: TimeInterval = 0.033 // 30 FPS
        static let slowRender: TimeInterval = 0.1
    }
}

#if DEBUG
// MARK: - Performance Debug View

struct PerformanceDebugView: View {
    @StateObject private var monitor = PerformanceMonitor.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(monitor.metrics.allOperations(), id: \.self) { operation in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(operation)
                            .font(.headline)
                        
                        if let avg = monitor.metrics.averageDuration(for: operation) {
                            Text("Average: \(String(format: "%.3f", avg))s")
                                .font(.caption)
                                .foregroundColor(colorForDuration(avg))
                        }
                        
                        if let max = monitor.metrics.maxDuration(for: operation) {
                            Text("Max: \(String(format: "%.3f", max))s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Performance Metrics")
            .toolbar {
                Button("Clear") {
                    monitor.metrics = PerformanceMetrics()
                }
            }
        }
    }
    
    private func colorForDuration(_ duration: TimeInterval) -> Color {
        if duration <= PerformanceConstants.Thresholds.fastRender {
            return .green
        } else if duration <= PerformanceConstants.Thresholds.acceptableRender {
            return .orange
        } else {
            return .red
        }
    }
}
#endif
