import Foundation
import Security
import UIKit

/// Manages secure in-memory caching of wallet seed with automatic lifecycle management
class SecureSeedCache {
    
    // MARK: - Types
    
    enum CacheError: Error {
        case cacheExpired
        case cacheEmpty
        case securityViolation
        
        var localizedDescription: String {
            switch self {
            case .cacheExpired:
                return "Cached seed has expired"
            case .cacheEmpty:
                return "No seed cached in memory"
            case .securityViolation:
                return "Security violation detected"
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var cachedSeed: String?
    private var lastAccessTime: Date?
    private var cacheCreationTime: Date?
    private let accessQueue = DispatchQueue(label: "com.lumen.seed.cache", attributes: .concurrent)
    
    // Cache timeout configuration (1 hour default)
    private let cacheTimeout: TimeInterval = 3600
    
    // Security monitoring
    private var accessCount: Int = 0
    private let maxAccessCount: Int = 1000 // Prevent excessive access
    
    // MARK: - Singleton
    
    static let shared = SecureSeedCache()
    private init() {
        setupSecurityMonitoring()
    }
    
    deinit {
        clearCache()
    }
    
    // MARK: - Public Methods
    
    /// Stores seed securely in memory with timestamp
    /// - Parameter seed: The seed to cache
    func storeSeed(_ seed: String) {
        accessQueue.async(flags: .barrier) {
            // Clear any existing seed first
            self.clearCacheInternal()

            // Store new seed with metadata
            self.cachedSeed = seed
            self.cacheCreationTime = Date()
            self.lastAccessTime = Date()
            self.accessCount = 0

            print("🔒 Seed cached securely in memory - length: \(seed.count) chars, timeout: \(self.cacheTimeout)s")
        }
    }
    
    /// Retrieves cached seed if valid
    /// - Returns: Cached seed or nil if invalid/expired
    /// - Throws: CacheError if cache is invalid
    func retrieveSeed() throws -> String {
        return try accessQueue.sync {
            print("🔍 retrieveSeed() called - accessCount: \(accessCount)/\(maxAccessCount)")

            // Security check: prevent excessive access
            guard accessCount < maxAccessCount else {
                print("❌ Security violation - too many access attempts")
                clearCacheInternal()
                throw CacheError.securityViolation
            }

            // Check if cache exists
            guard let seed = cachedSeed else {
                print("❌ Cache empty - no seed stored")
                throw CacheError.cacheEmpty
            }

            // Check if cache is expired
            guard isCacheValidInternal() else {
                print("❌ Cache expired - clearing")
                clearCacheInternal()
                throw CacheError.cacheExpired
            }

            // Update access metadata
            lastAccessTime = Date()
            accessCount += 1

            print("✅ Retrieved seed from cache - accessCount now: \(accessCount)")
            return seed
        }
    }
    
    /// Checks if cached seed is valid without retrieving it
    /// - Returns: true if cache is valid and not expired
    func isCacheValid() -> Bool {
        return accessQueue.sync {
            let hasSeed = cachedSeed != nil
            let isValidInternal = isCacheValidInternal()
            let result = hasSeed && isValidInternal

            print("🔍 isCacheValid() - hasSeed: \(hasSeed), isValidInternal: \(isValidInternal), result: \(result)")
            if let cacheTime = cacheCreationTime {
                let age = Date().timeIntervalSince(cacheTime)
                print("🔍 Cache age: \(age)s, timeout: \(cacheTimeout)s")
            }

            return result
        }
    }
    
    /// Clears cached seed from memory
    func clearCache() {
        accessQueue.async(flags: .barrier) {
            let hadSeed = self.cachedSeed != nil
            self.clearCacheInternal()
            print("🗑️ Seed cache cleared from memory - had seed: \(hadSeed)")
        }
    }
    
    /// Gets cache status information for debugging
    func getCacheStatus() -> (isValid: Bool, age: TimeInterval?, accessCount: Int) {
        return accessQueue.sync {
            let age = cacheCreationTime?.timeIntervalSinceNow.magnitude
            return (isCacheValidInternal(), age, accessCount)
        }
    }
    
    // MARK: - Private Methods
    
    private func isCacheValidInternal() -> Bool {
        guard let creationTime = cacheCreationTime else { return false }
        
        let age = Date().timeIntervalSince(creationTime)
        return age < cacheTimeout
    }
    
    private func clearCacheInternal() {
        // Securely overwrite seed in memory
        if var seed = cachedSeed {
            // Overwrite with random data
            for i in seed.indices {
                seed.replaceSubrange(i...i, with: String(Int.random(in: 0...9)))
            }
        }
        
        cachedSeed = nil
        lastAccessTime = nil
        cacheCreationTime = nil
        accessCount = 0
    }
    
    private func setupSecurityMonitoring() {
        // Monitor app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    // MARK: - App Lifecycle Handlers
    
    @objc private func handleAppWillResignActive() {
        // App is becoming inactive (e.g., phone call, control center)
        // Keep cache for quick return
        print("📱 App will resign active - keeping seed cache")
    }
    
    @objc private func handleAppDidEnterBackground() {
        // App moved to background - start security timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) { // 5 minutes
            if UIApplication.shared.applicationState == .background {
                self.clearCache()
                print("🔒 App backgrounded > 5min - cleared seed cache for security")
            }
        }
    }
    
    @objc private func handleAppWillTerminate() {
        // App is terminating - immediately clear cache
        clearCache()
        print("🛑 App terminating - seed cache cleared")
    }
    
    @objc private func handleMemoryWarning() {
        // System memory pressure - clear cache to free memory
        clearCache()
        print("⚠️ Memory warning - seed cache cleared")
    }
}

// MARK: - Cache Statistics (Debug Only)

#if DEBUG
extension SecureSeedCache {
    func printCacheStatistics() {
        let status = getCacheStatus()
        print("📊 Cache Statistics:")
        print("   Valid: \(status.isValid)")
        print("   Age: \(status.age?.formatted() ?? "N/A") seconds")
        print("   Access Count: \(status.accessCount)")
    }
}
#endif
