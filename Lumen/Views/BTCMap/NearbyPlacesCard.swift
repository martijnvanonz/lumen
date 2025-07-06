import SwiftUI
import CoreLocation

/// Card component showing nearby Bitcoin places count and access
struct NearbyPlacesCard: View {
    @StateObject private var btcMapService = BTCMapService.shared
    @StateObject private var locationManager = LocationManager.shared
    @State private var showingPlaces = false
    @State private var showingLocationPermission = false
    
    var nearbyCount: Int {
        guard let userLocation = locationManager.userLocation else { return 0 }
        return btcMapService.getNearbyPlacesCount(userLocation: userLocation)
    }
    
    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: "map.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(getMainText())
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(getSubText())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow or action icon
                Image(systemName: getActionIcon())
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingPlaces) {
            PlacesListView()
        }
        .sheet(isPresented: $showingLocationPermission) {
            LocationPermissionView()
        }
        .onAppear {
            // Refresh data when card appears
            Task {
                await btcMapService.refreshIfNeeded()
            }
        }
    }
    
    private func getMainText() -> String {
        if !locationManager.hasLocationPermission {
            return "Find Bitcoin places near you"
        }
        
        if locationManager.userLocation == nil {
            return "Getting your location..."
        }
        
        if nearbyCount == 0 {
            return "No Bitcoin places found nearby"
        }
        
        return "\(nearbyCount) place\(nearbyCount == 1 ? "" : "s") to spend bitcoin near you"
    }
    
    private func getSubText() -> String {
        if !locationManager.hasLocationPermission {
            return "Enable location to discover merchants"
        }
        
        if locationManager.userLocation == nil {
            return "Please wait while we get your location"
        }
        
        if nearbyCount == 0 {
            return "Try expanding your search radius in settings"
        }
        
        return "Tap to explore nearby merchants"
    }
    
    private func getActionIcon() -> String {
        if !locationManager.hasLocationPermission {
            return "location.circle"
        }
        
        if locationManager.userLocation == nil {
            return "location.circle"
        }
        
        return "chevron.right"
    }
    
    private func handleTap() {
        print("🔍 NearbyPlacesCard: handleTap() called")
        print("🔍 NearbyPlacesCard: hasLocationPermission = \(locationManager.hasLocationPermission)")
        print("🔍 NearbyPlacesCard: userLocation = \(locationManager.userLocation?.description ?? "nil")")
        print("🔍 NearbyPlacesCard: authorizationStatus = \(locationManager.authorizationStatus)")

        if !locationManager.hasLocationPermission {
            print("🔍 NearbyPlacesCard: No permission, showing location permission view")
            showingLocationPermission = true
        } else if locationManager.userLocation != nil {
            print("🔍 NearbyPlacesCard: Have location, showing places")
            showingPlaces = true
        } else {
            print("🔍 NearbyPlacesCard: Have permission but no location, starting updates")
            // Location permission granted but no location yet
            locationManager.startLocationUpdates()
        }
    }
}

// MARK: - Loading State Card

struct NearbyPlacesLoadingCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "map.circle")
                .font(.title2)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Loading Bitcoin places...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Please wait while we fetch nearby merchants")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ProgressView()
                .scaleEffect(0.8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Error State Card

struct NearbyPlacesErrorCard: View {
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        Button(action: onRetry) {
            HStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Failed to load places")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Tap to retry")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.orange)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Smart Card Wrapper

struct SmartNearbyPlacesCard: View {
    @StateObject private var btcMapService = BTCMapService.shared
    
    var body: some View {
        Group {
            if btcMapService.isLoading && btcMapService.allPlaces.isEmpty {
                NearbyPlacesLoadingCard()
            } else if let errorMessage = btcMapService.errorMessage, btcMapService.allPlaces.isEmpty {
                NearbyPlacesErrorCard(errorMessage: errorMessage) {
                    Task {
                        await btcMapService.forceRefresh()
                    }
                }
            } else {
                NearbyPlacesCard()
            }
        }
    }
}

// MARK: - Preview

#Preview("Normal State") {
    VStack(spacing: 16) {
        NearbyPlacesCard()
        NearbyPlacesLoadingCard()
        NearbyPlacesErrorCard(errorMessage: "Network error") {
            print("Retry tapped")
        }
    }
    .padding()
}
