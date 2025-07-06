import Foundation
import CoreLocation
import SwiftUI

/// Manages location services for Bitcoin Places feature
@MainActor
class LocationManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = LocationManager()
    
    // MARK: - Published Properties
    
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults.standard
    private let locationEnabledKey = "btc_places_location_enabled"
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        print("🔍 LocationManager: Initializing...")
        setupLocationManager()
        loadSettings()
        print("🔍 LocationManager: Initialization complete")
        print("🔍 LocationManager: Initial authorization status: \(authorizationStatus)")
        print("🔍 LocationManager: Location services enabled: \(CLLocationManager.locationServicesEnabled())")
    }
    
    // MARK: - Public Methods
    
    /// Request location permission from user
    func requestLocationPermission() {
        print("🔍 LocationManager: requestLocationPermission() called")
        print("🔍 LocationManager: Current authorization status: \(authorizationStatus)")

        switch authorizationStatus {
        case .notDetermined:
            print("🔍 LocationManager: Status is notDetermined, requesting authorization...")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("🔍 LocationManager: Status is denied/restricted, showing error message")
            // Guide user to settings
            errorMessage = "Location access is required to show nearby Bitcoin places. Please enable location access in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            print("🔍 LocationManager: Status is already authorized, starting location updates")
            startLocationUpdates()
        @unknown default:
            print("🔍 LocationManager: Unknown authorization status")
            break
        }
    }
    
    /// Start location updates
    func startLocationUpdates() {
        print("🔍 LocationManager: startLocationUpdates() called")
        print("🔍 LocationManager: Authorization status: \(authorizationStatus)")
        print("🔍 LocationManager: Location services enabled: \(CLLocationManager.locationServicesEnabled())")

        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("🔍 LocationManager: Authorization not granted, cannot start updates")
            return
        }

        guard CLLocationManager.locationServicesEnabled() else {
            print("🔍 LocationManager: Location services disabled system-wide")
            errorMessage = "Location services are disabled. Please enable them in Settings."
            return
        }

        print("🔍 LocationManager: Starting location updates...")
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
        saveSettings()
        errorMessage = nil
        print("🔍 LocationManager: Location updates started successfully")
    }
    
    /// Stop location updates
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
        userLocation = nil
        saveSettings()
    }
    
    /// Toggle location services on/off
    func toggleLocationServices() {
        if isLocationEnabled {
            stopLocationUpdates()
        } else {
            requestLocationPermission()
        }
    }
    
    /// Check if location permission is granted
    var hasLocationPermission: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    /// Check if we can request location permission
    var canRequestPermission: Bool {
        return authorizationStatus == .notDetermined
    }
    
    /// Open iOS Settings app
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100 // Update every 100 meters
        
        authorizationStatus = locationManager.authorizationStatus
    }
    
    private func loadSettings() {
        isLocationEnabled = userDefaults.bool(forKey: locationEnabledKey)
        
        // Auto-start if previously enabled and permission granted
        if isLocationEnabled && hasLocationPermission {
            startLocationUpdates()
        }
    }
    
    private func saveSettings() {
        userDefaults.set(isLocationEnabled, forKey: locationEnabledKey)
    }
    
    private func handleLocationError(_ error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                errorMessage = "Location access denied. Enable location access in Settings to see nearby Bitcoin places."
            case .locationUnknown:
                errorMessage = "Unable to determine your location. Please try again."
            case .network:
                errorMessage = "Network error while getting location. Please check your connection."
            default:
                errorMessage = "Location error: \(clError.localizedDescription)"
            }
        } else {
            errorMessage = "Location error: \(error.localizedDescription)"
        }
        
        print("❌ LocationManager: \(errorMessage ?? "Unknown error")")
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: @preconcurrency CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Only update if the location is significantly different or it's the first location
        if let currentLocation = userLocation {
            let distance = location.distance(from: currentLocation)
            guard distance > 100 else { return } // Only update if moved more than 100 meters
        }
        
        userLocation = location
        errorMessage = nil
        
        print("📍 LocationManager: Updated location to \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        handleLocationError(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔍 LocationManager: didChangeAuthorization called with status: \(status)")
        print("🔍 LocationManager: Previous status was: \(authorizationStatus)")

        authorizationStatus = status

        switch status {
        case .notDetermined:
            print("📍 LocationManager: Authorization not determined")

        case .denied, .restricted:
            print("📍 LocationManager: Authorization denied/restricted")
            stopLocationUpdates()
            errorMessage = "Location access is required to show nearby Bitcoin places."

        case .authorizedWhenInUse:
            print("📍 LocationManager: Authorization granted (when in use)")
            print("📍 LocationManager: isLocationEnabled = \(isLocationEnabled)")
            // Auto-enable location services when permission is granted
            if !isLocationEnabled {
                print("📍 LocationManager: Auto-enabling location services")
                isLocationEnabled = true
                saveSettings()
            }
            startLocationUpdates()

        case .authorizedAlways:
            print("📍 LocationManager: Authorization granted (always)")
            print("📍 LocationManager: isLocationEnabled = \(isLocationEnabled)")
            // Auto-enable location services when permission is granted
            if !isLocationEnabled {
                print("📍 LocationManager: Auto-enabling location services")
                isLocationEnabled = true
                saveSettings()
            }
            startLocationUpdates()

        @unknown default:
            print("📍 LocationManager: Unknown authorization status")
        }
    }
}

// MARK: - Location Permission Status

extension LocationManager {
    
    /// Get user-friendly description of current location status
    var locationStatusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Location permission not requested"
        case .denied:
            return "Location access denied"
        case .restricted:
            return "Location access restricted"
        case .authorizedWhenInUse:
            return isLocationEnabled ? "Location enabled" : "Location available but disabled"
        case .authorizedAlways:
            return isLocationEnabled ? "Location enabled" : "Location available but disabled"
        @unknown default:
            return "Unknown location status"
        }
    }
    
    /// Get appropriate action text for current status
    var actionButtonText: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Enable Location"
        case .denied, .restricted:
            return "Open Settings"
        case .authorizedWhenInUse, .authorizedAlways:
            return isLocationEnabled ? "Disable Location" : "Enable Location"
        @unknown default:
            return "Enable Location"
        }
    }
}
