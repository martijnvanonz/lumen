import Foundation

/// Manages caching for BTC Map data with smart expiration and offline support
class BTCMapCache {
    
    // MARK: - Singleton
    
    static let shared = BTCMapCache()
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    // Cache keys
    private let snapshotCacheKey = "btc_map_snapshot_cache"
    private let snapshotTimestampKey = "btc_map_snapshot_timestamp"
    private let detailsCacheKey = "btc_map_details_cache"
    private let detailsTimestampKey = "btc_map_details_timestamp"
    
    // Cache settings
    private let snapshotExpirationHours = 24 // Refresh snapshot daily
    private let detailsExpirationDays = 7   // Keep details for a week
    private let maxDetailsCache = 500       // Maximum number of cached place details
    
    // MARK: - Initialization
    
    private init() {
        cleanupExpiredCache()
    }
    
    // MARK: - Snapshot Cache
    
    /// Cache the places snapshot
    func cacheSnapshot(_ places: [BTCPlace]) {
        do {
            let data = try JSONEncoder().encode(places)
            userDefaults.set(data, forKey: snapshotCacheKey)
            userDefaults.set(Date(), forKey: snapshotTimestampKey)
            
            print("✅ BTCMapCache: Cached \(places.count) places in snapshot")
        } catch {
            print("❌ BTCMapCache: Failed to cache snapshot: \(error)")
        }
    }
    
    /// Load cached snapshot
    func loadSnapshot() -> [BTCPlace]? {
        guard let data = userDefaults.data(forKey: snapshotCacheKey),
              let places = try? JSONDecoder().decode([BTCPlace].self, from: data) else {
            return nil
        }
        
        print("✅ BTCMapCache: Loaded \(places.count) places from snapshot cache")
        return places
    }
    
    /// Check if snapshot cache is expired
    func isSnapshotExpired() -> Bool {
        guard let timestamp = userDefaults.object(forKey: snapshotTimestampKey) as? Date else {
            return true // No timestamp means expired
        }
        
        let hoursSinceCache = Calendar.current.dateComponents([.hour], from: timestamp, to: Date()).hour ?? 0
        return hoursSinceCache >= snapshotExpirationHours
    }
    
    /// Get snapshot cache age in hours
    func getSnapshotCacheAge() -> Int {
        guard let timestamp = userDefaults.object(forKey: snapshotTimestampKey) as? Date else {
            return -1
        }
        
        return Calendar.current.dateComponents([.hour], from: timestamp, to: Date()).hour ?? 0
    }
    
    // MARK: - Details Cache
    
    /// Cache place details
    func cacheDetails(_ place: BTCPlace) {
        var detailsCache = loadDetailsCache()
        
        // Add/update the place
        detailsCache[place.id] = CachedPlaceDetails(
            place: place,
            cachedAt: Date()
        )
        
        // Limit cache size (remove oldest entries)
        if detailsCache.count > maxDetailsCache {
            let sortedEntries = detailsCache.sorted { $0.value.cachedAt < $1.value.cachedAt }
            let entriesToRemove = sortedEntries.prefix(detailsCache.count - maxDetailsCache)
            
            for entry in entriesToRemove {
                detailsCache.removeValue(forKey: entry.key)
            }
            
            print("🧹 BTCMapCache: Cleaned up \(entriesToRemove.count) old cache entries")
        }
        
        saveDetailsCache(detailsCache)
        print("✅ BTCMapCache: Cached details for place \(place.id)")
    }
    
    /// Load cached place details
    func loadDetails(for placeId: Int) -> BTCPlace? {
        let detailsCache = loadDetailsCache()
        
        guard let cachedDetails = detailsCache[placeId] else {
            return nil
        }
        
        // Check if cache is expired
        let daysSinceCache = Calendar.current.dateComponents([.day], from: cachedDetails.cachedAt, to: Date()).day ?? 0
        
        if daysSinceCache >= detailsExpirationDays {
            print("⏰ BTCMapCache: Details cache expired for place \(placeId)")
            return nil
        }
        
        print("✅ BTCMapCache: Loaded cached details for place \(placeId)")
        return cachedDetails.place
    }
    
    /// Check if details are cached and not expired
    func hasValidDetails(for placeId: Int) -> Bool {
        return loadDetails(for: placeId) != nil
    }
    
    // MARK: - Cache Management
    
    /// Clear all cached data
    func clearAllCache() {
        userDefaults.removeObject(forKey: snapshotCacheKey)
        userDefaults.removeObject(forKey: snapshotTimestampKey)
        userDefaults.removeObject(forKey: detailsCacheKey)
        userDefaults.removeObject(forKey: detailsTimestampKey)
        
        print("🧹 BTCMapCache: Cleared all cache")
    }
    
    /// Clear only expired cache entries
    func cleanupExpiredCache() {
        // Clean up expired details
        var detailsCache = loadDetailsCache()
        let initialCount = detailsCache.count
        
        detailsCache = detailsCache.filter { _, cachedDetails in
            let daysSinceCache = Calendar.current.dateComponents([.day], from: cachedDetails.cachedAt, to: Date()).day ?? 0
            return daysSinceCache < detailsExpirationDays
        }
        
        if detailsCache.count < initialCount {
            saveDetailsCache(detailsCache)
            print("🧹 BTCMapCache: Cleaned up \(initialCount - detailsCache.count) expired detail entries")
        }
    }
    
    /// Get cache statistics
    func getCacheStats() -> CacheStats {
        let snapshotSize = userDefaults.data(forKey: snapshotCacheKey)?.count ?? 0
        let detailsCount = loadDetailsCache().count
        let snapshotAge = getSnapshotCacheAge()
        
        return CacheStats(
            snapshotSizeBytes: snapshotSize,
            detailsCount: detailsCount,
            snapshotAgeHours: snapshotAge,
            isSnapshotExpired: isSnapshotExpired()
        )
    }
    
    // MARK: - Private Methods
    
    private func loadDetailsCache() -> [Int: CachedPlaceDetails] {
        guard let data = userDefaults.data(forKey: detailsCacheKey),
              let cache = try? JSONDecoder().decode([Int: CachedPlaceDetails].self, from: data) else {
            return [:]
        }
        
        return cache
    }
    
    private func saveDetailsCache(_ cache: [Int: CachedPlaceDetails]) {
        do {
            let data = try JSONEncoder().encode(cache)
            userDefaults.set(data, forKey: detailsCacheKey)
            userDefaults.set(Date(), forKey: detailsTimestampKey)
        } catch {
            print("❌ BTCMapCache: Failed to save details cache: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct CachedPlaceDetails: Codable {
    let place: BTCPlace
    let cachedAt: Date
}

struct CacheStats {
    let snapshotSizeBytes: Int
    let detailsCount: Int
    let snapshotAgeHours: Int
    let isSnapshotExpired: Bool
    
    var snapshotSizeMB: Double {
        Double(snapshotSizeBytes) / (1024 * 1024)
    }
    
    var description: String {
        return """
        Snapshot: \(String(format: "%.1f", snapshotSizeMB)) MB, \(snapshotAgeHours)h old
        Details: \(detailsCount) places cached
        Status: \(isSnapshotExpired ? "Expired" : "Fresh")
        """
    }
}
