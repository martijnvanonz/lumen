import SwiftUI
import MapKit
import CoreLocation

/// Interactive map view showing Bitcoin places as pins
struct BitcoinPlacesMapView: UIViewRepresentable {
    let places: [BTCPlace]
    let userLocation: CLLocation
    let searchRadius: Double
    
    @StateObject private var btcMapService = BTCMapService.shared
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.mapType = .standard
        
        // Register custom annotation view
        mapView.register(
            BitcoinPlaceAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: BitcoinPlaceAnnotationView.reuseIdentifier
        )
        
        // Set initial region centered on user location
        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: searchRadius * 2000, // Convert km to meters and add buffer
            longitudinalMeters: searchRadius * 2000
        )
        mapView.setRegion(region, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove existing annotations (except user location)
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        // Add new annotations
        let annotations = places.map { place in
            BitcoinPlaceAnnotation(place: place, userLocation: userLocation)
        }
        mapView.addAnnotations(annotations)
        
        // Update region if needed
        let currentCenter = mapView.region.center
        let userCenter = userLocation.coordinate
        let distance = CLLocation(latitude: currentCenter.latitude, longitude: currentCenter.longitude)
            .distance(from: userLocation)
        
        // Only update region if user has moved significantly (more than 1km)
        if distance > 1000 {
            let region = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: searchRadius * 2000,
                longitudinalMeters: searchRadius * 2000
            )
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: BitcoinPlacesMapView
        
        init(_ parent: BitcoinPlacesMapView) {
            self.parent = parent
        }
        
        // MARK: - MKMapViewDelegate
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let annotation = view.annotation as? BitcoinPlaceAnnotation else { return }

            // Open in Apple Maps for navigation
            let coordinate = CLLocationCoordinate2D(latitude: annotation.place.lat, longitude: annotation.place.lon)
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = annotation.place.name ?? BitcoinPlaceAnnotation.getBusinessTypeFromIcon(annotation.place.icon)

            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        }

        func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
            let cluster = MKClusterAnnotation(memberAnnotations: memberAnnotations)
            cluster.title = "\(memberAnnotations.count) Bitcoin Places"
            return cluster
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            if let cluster = annotation as? MKClusterAnnotation {
                let clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: "cluster") as? MKAnnotationView
                    ?? MKAnnotationView(annotation: cluster, reuseIdentifier: "cluster")
                
                clusterView.annotation = cluster
                clusterView.canShowCallout = true
                
                // Create cluster view
                let clusterSize: CGFloat = 40
                let containerView = UIView(frame: CGRect(x: 0, y: 0, width: clusterSize, height: clusterSize))
                
                // Background circle
                let backgroundView = UIView(frame: containerView.bounds)
                backgroundView.backgroundColor = .systemBlue
                backgroundView.layer.cornerRadius = clusterSize / 2
                backgroundView.layer.borderWidth = 3
                backgroundView.layer.borderColor = UIColor.white.cgColor
                backgroundView.layer.shadowColor = UIColor.black.cgColor
                backgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
                backgroundView.layer.shadowOpacity = 0.3
                backgroundView.layer.shadowRadius = 3
                
                // Count label
                let countLabel = UILabel(frame: containerView.bounds)
                countLabel.text = "\(cluster.memberAnnotations.count)"
                countLabel.textAlignment = .center
                countLabel.textColor = .white
                countLabel.font = .boldSystemFont(ofSize: 16)
                
                containerView.addSubview(backgroundView)
                containerView.addSubview(countLabel)
                
                // Remove existing subviews and add new one
                clusterView.subviews.forEach { $0.removeFromSuperview() }
                clusterView.addSubview(containerView)
                clusterView.frame = containerView.frame
                
                return clusterView
            }
            
            guard let bitcoinAnnotation = annotation as? BitcoinPlaceAnnotation else {
                return nil
            }
            
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: BitcoinPlaceAnnotationView.reuseIdentifier,
                for: annotation
            ) as? BitcoinPlaceAnnotationView ?? BitcoinPlaceAnnotationView(
                annotation: annotation,
                reuseIdentifier: BitcoinPlaceAnnotationView.reuseIdentifier
            )
            
            annotationView.annotation = annotation
            annotationView.clusteringIdentifier = "bitcoinPlace"
            
            return annotationView
        }
    }
}

/// Map controls overlay for zoom and refresh actions
struct MapControlsOverlay: View {
    let userLocation: CLLocation
    let onZoomToUser: () -> Void
    let onRefresh: () -> Void
    
    @StateObject private var btcMapService = BTCMapService.shared
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Zoom to user location button
                    Button(action: onZoomToUser) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    
                    // Refresh button
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .rotationEffect(.degrees(btcMapService.isLoading ? 360 : 0))
                            .animation(
                                btcMapService.isLoading ? 
                                Animation.linear(duration: 1).repeatForever(autoreverses: false) : 
                                .default,
                                value: btcMapService.isLoading
                            )
                    }
                    .disabled(btcMapService.isLoading)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 100) // Account for safe area and tab bar
            }
        }
    }
}

/// Complete map view with controls
struct BitcoinPlacesMapViewWithControls: View {
    let places: [BTCPlace]
    let userLocation: CLLocation
    let searchRadius: Double
    
    @StateObject private var btcMapService = BTCMapService.shared
    @State private var mapView: MKMapView?
    
    var body: some View {
        ZStack {
            BitcoinPlacesMapView(places: places, userLocation: userLocation, searchRadius: searchRadius)
                .onAppear { mapView = nil }
            
            MapControlsOverlay(
                userLocation: userLocation,
                onZoomToUser: zoomToUserLocation,
                onRefresh: refreshPlaces
            )
        }
    }
    
    private func zoomToUserLocation() {
        // This would need to be implemented with a more sophisticated approach
        // to communicate with the underlying MKMapView
        // For now, we'll trigger a refresh which will center on user location
        refreshPlaces()
    }
    
    private func refreshPlaces() {
        Task {
            await btcMapService.forceRefresh()
        }
    }
}

// MARK: - Preview

#Preview {
    // Create sample data for preview
    var samplePlace = BTCPlace(
        id: 1,
        lat: 52.3676,
        lon: 4.9041,
        icon: "restaurant"
    )
    samplePlace.name = "Bitcoin Cafe"
    samplePlace.address = "Dam Square 1, Amsterdam"
    samplePlace.acceptsLightning = true
    samplePlace.acceptsOnchain = true
    samplePlace.acceptsNFC = false

    let userLocation = CLLocation(latitude: 52.3676, longitude: 4.9041)

    return BitcoinPlacesMapViewWithControls(
        places: [samplePlace],
        userLocation: userLocation,
        searchRadius: 5.0
    )
}
