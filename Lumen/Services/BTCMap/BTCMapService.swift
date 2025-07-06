import Foundation
import CoreLocation
import Combine

/// Service for interacting with BTC Map API and managing Bitcoin places data
@MainActor
class BTCMapService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = BTCMapService()
    
    // MARK: - Published Properties
    
    @Published var allPlaces: [BTCPlace] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let snapshotURL = "https://cdn.static.btcmap.org/api/v4/places.json"
    private let detailsBaseURL = "https://api.btcmap.org/v4/places"
    private let cache = BTCMapCache.shared
    
    // MARK: - Initialization
    
    private init() {
        loadCachedData()
    }
    
    // MARK: - Public Methods
    
    /// Fetch the latest snapshot of all Bitcoin places
    func fetchSnapshot() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let url = URL(string: snapshotURL)!
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw BTCMapError.invalidResponse
            }
            
            let places = try JSONDecoder().decode([BTCPlace].self, from: data)
            
            await MainActor.run {
                self.allPlaces = places
                self.lastUpdated = Date()
                self.isLoading = false
                self.cache.cacheSnapshot(places)
            }
            
            print("✅ BTCMapService: Fetched \(places.count) places from snapshot")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch Bitcoin places: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            print("❌ BTCMapService: Failed to fetch snapshot: \(error)")
        }
    }
    
    /// Get nearby places within specified radius (in kilometers)
    func getNearbyPlaces(userLocation: CLLocation, radius: Double = 5.0) -> [BTCPlace] {
        return allPlaces
            .filter { place in
                let distance = place.distance(from: userLocation)
                return distance <= radius
            }
            .sorted { place1, place2 in
                place1.distance(from: userLocation) < place2.distance(from: userLocation)
            }
    }
    
    /// Get count of nearby places
    func getNearbyPlacesCount(userLocation: CLLocation, radius: Double = 5.0) -> Int {
        return getNearbyPlaces(userLocation: userLocation, radius: radius).count
    }
    
    /// Fetch detailed information for a specific place
    func fetchPlaceDetails(id: Int) async throws -> BTCPlace {
        // Check cache first
        if let cachedPlace = cache.loadDetails(for: id) {
            return cachedPlace
        }
        
        // Fetch from API
        let fields = "id,name,address,phone,website,opening_hours,comments,verified_at,boosted_until,payment:lightning,payment:onchain,payment:lightning_contactless"
        let urlString = "\(detailsBaseURL)/\(id)?fields=\(fields)"
        
        guard let url = URL(string: urlString) else {
            throw BTCMapError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BTCMapError.invalidResponse
        }
        
        var place = try JSONDecoder().decode(BTCPlace.self, from: data)
        place.updatedAt = ISO8601DateFormatter().string(from: Date())

        // Cache the detailed place
        cache.cacheDetails(place)

        return place
    }
    
    /// Refresh places data if needed (daily check)
    func refreshIfNeeded() async {
        guard cache.isSnapshotExpired() else { return }
        await fetchSnapshot()
    }
    
    /// Force refresh places data
    func forceRefresh() async {
        await fetchSnapshot()
    }
    
    // MARK: - Private Methods

    private func loadCachedData() {
        // Load snapshot cache
        if let places = cache.loadSnapshot() {
            allPlaces = places
            print("✅ BTCMapService: Loaded \(places.count) places from cache")
        }

        // Set last updated based on cache age
        if !cache.isSnapshotExpired() {
            // Estimate last updated time based on cache age
            let cacheAge = cache.getSnapshotCacheAge()
            lastUpdated = Calendar.current.date(byAdding: .hour, value: -cacheAge, to: Date())
        }
    }
}

// MARK: - Error Types

enum BTCMapError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
