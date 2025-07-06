import SwiftUI
import CoreLocation

/// View for requesting location permission with clear explanation
struct LocationPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager.shared
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                // Title and Description
                VStack(spacing: 16) {
                    Text("Find Bitcoin Places Near You")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("We use your location to show nearby businesses that accept Bitcoin payments. Your location stays private and is never shared with third parties.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                // Privacy Features
                VStack(spacing: 16) {
                    PrivacyFeatureRow(
                        icon: "lock.shield.fill",
                        title: "Privacy First",
                        description: "Your location is only used locally on your device"
                    )
                    
                    PrivacyFeatureRow(
                        icon: "location.slash.fill",
                        title: "No Tracking",
                        description: "We don't store or share your location data"
                    )
                    
                    PrivacyFeatureRow(
                        icon: "gearshape.fill",
                        title: "Full Control",
                        description: "You can disable location access anytime in settings"
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: handlePrimaryAction) {
                        Text(locationManager.actionButtonText)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Skip for Now")
                            .font(.body)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("Location Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onReceive(locationManager.$authorizationStatus) { status in
            // Auto-dismiss when permission is granted
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        }
    }
    
    private func handlePrimaryAction() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestLocationPermission()
        case .denied, .restricted:
            locationManager.openSettings()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.toggleLocationServices()
        @unknown default:
            locationManager.requestLocationPermission()
        }
    }
}

// MARK: - Privacy Feature Row

struct PrivacyFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - No Location View

struct NoLocationView: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var showingLocationPermission = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.slash.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Location Required")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(getLocationMessage())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            Button(action: handleLocationAction) {
                Text(locationManager.actionButtonText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingLocationPermission) {
            LocationPermissionView()
        }
    }
    
    private func getLocationMessage() -> String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "We need your location to show nearby Bitcoin places. Your location stays private and is only used on your device."
        case .denied, .restricted:
            return "Location access is disabled. Enable location access in Settings to see nearby Bitcoin places."
        case .authorizedWhenInUse, .authorizedAlways:
            return "Location services are available but disabled. Enable location to see nearby Bitcoin places."
        @unknown default:
            return "We need your location to show nearby Bitcoin places."
        }
    }
    
    private func handleLocationAction() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            showingLocationPermission = true
        case .denied, .restricted:
            locationManager.openSettings()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.toggleLocationServices()
        @unknown default:
            showingLocationPermission = true
        }
    }
}

// MARK: - Preview

#Preview {
    LocationPermissionView()
}

#Preview("No Location") {
    NoLocationView()
}
