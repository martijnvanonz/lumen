import SwiftUI
import CoreLocation
import MapKit

/// Main view showing list of nearby Bitcoin places
struct PlacesListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var btcMapService = BTCMapService.shared
    @StateObject private var locationManager = LocationManager.shared
    @State private var showingLocationPermission = false
    @State private var searchRadius: Double = 5.0
    
    var nearbyPlaces: [BTCPlace] {
        guard let userLocation = locationManager.userLocation else { return [] }
        return btcMapService.getNearbyPlaces(userLocation: userLocation, radius: searchRadius)
    }
    
    var body: some View {
        NavigationView {
            Group {
                if !locationManager.hasLocationPermission {
                    NoLocationView()
                } else if locationManager.userLocation == nil {
                    LocationLoadingView()
                } else if nearbyPlaces.isEmpty {
                    NoPlacesView(searchRadius: searchRadius)
                } else {
                    PlacesList(places: nearbyPlaces, userLocation: locationManager.userLocation!)
                }
            }
            .navigationTitle("Bitcoin Places")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Search Radius") {
                            ForEach([1.0, 2.5, 5.0, 10.0, 20.0], id: \.self) { radius in
                                Button("\(Int(radius)) km") {
                                    searchRadius = radius
                                }
                            }
                        }
                        
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            Task {
                                await btcMapService.forceRefresh()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                await btcMapService.forceRefresh()
            }
        }
        .sheet(isPresented: $showingLocationPermission) {
            LocationPermissionView()
        }
    }
}

// MARK: - Places List

struct PlacesList: View {
    let places: [BTCPlace]
    let userLocation: CLLocation
    
    var body: some View {
        List(places) { place in
            PlaceRowView(place: place, userLocation: userLocation)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Place Row View

struct PlaceRowView: View {
    let place: BTCPlace
    let userLocation: CLLocation
    @State private var placeDetails: BTCPlace?
    @State private var isLoadingDetails = false
    
    var displayPlace: BTCPlace {
        placeDetails ?? place
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: displayPlace.systemIcon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Name and loading indicator
                HStack {
                    Text(displayPlace.name ?? "Loading...")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if isLoadingDetails {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                    
                    Spacer()
                }
                
                // Address
                if let address = displayPlace.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Distance and status
                HStack(spacing: 8) {
                    Text("\(String(format: "%.1f", place.distance(from: userLocation))) km away")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if displayPlace.isRecentlyVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    if displayPlace.isBoosted {
                        Text("PROMOTED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                // Payment methods
                if !displayPlace.paymentMethods.isEmpty {
                    PaymentMethodBadges(methods: displayPlace.paymentMethods)
                }
            }
            
            // Navigation button
            Button(action: { openInMaps() }) {
                Image(systemName: "location.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .onAppear {
            loadPlaceDetails()
        }
    }
    
    private func loadPlaceDetails() {
        // Skip if we already have details or are loading
        guard placeDetails == nil && !isLoadingDetails else { return }
        
        // Skip if we already have a name (basic details available)
        guard place.name == nil else {
            placeDetails = place
            return
        }
        
        isLoadingDetails = true
        
        Task {
            do {
                let details = try await BTCMapService.shared.fetchPlaceDetails(id: place.id)
                await MainActor.run {
                    placeDetails = details
                    isLoadingDetails = false
                }
            } catch {
                await MainActor.run {
                    // Fallback to basic place data
                    placeDetails = place
                    isLoadingDetails = false
                }
                print("❌ Failed to load details for place \(place.id): \(error)")
            }
        }
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = displayPlace.name ?? "Bitcoin Place"
        
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Payment Method Badges

struct PaymentMethodBadges: View {
    let methods: [PaymentMethod]
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(methods, id: \.rawValue) { method in
                PaymentMethodBadge(method: method)
            }
        }
    }
}

struct PaymentMethodBadge: View {
    let method: PaymentMethod
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: method.icon)
                .font(.caption2)
            
            Text(method.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(badgeColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(badgeColor.opacity(0.15))
        .cornerRadius(6)
    }
    
    private var badgeColor: Color {
        switch method {
        case .lightning:
            return .yellow
        case .onchain:
            return .orange
        case .nfc:
            return .blue
        }
    }
}

// MARK: - Empty States

struct LocationLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Getting your location...")
                .font(.headline)
            
            Text("Please wait while we determine your location to show nearby Bitcoin places.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
}

struct NoPlacesView: View {
    let searchRadius: Double
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Bitcoin Places Found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("No Bitcoin-accepting businesses found within \(Int(searchRadius)) km of your location. Try expanding your search radius.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
}

// MARK: - Preview

#Preview {
    PlacesListView()
}
