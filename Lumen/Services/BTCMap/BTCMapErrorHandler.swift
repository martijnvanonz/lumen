import Foundation
import CoreLocation
import SwiftUI

/// Centralized error handling for BTC Map functionality
struct BTCMapErrorHandler {
    
    // MARK: - Error Types
    
    enum BTCMapErrorType {
        case noLocationPermission
        case locationServicesDisabled
        case locationUnavailable
        case networkError(Error)
        case apiError(String)
        case noPlacesFound(radius: Double)
        case cacheError
        case decodingError
        
        var title: String {
            switch self {
            case .noLocationPermission:
                return "Location Permission Required"
            case .locationServicesDisabled:
                return "Location Services Disabled"
            case .locationUnavailable:
                return "Location Unavailable"
            case .networkError:
                return "Network Error"
            case .apiError:
                return "API Error"
            case .noPlacesFound:
                return "No Places Found"
            case .cacheError:
                return "Cache Error"
            case .decodingError:
                return "Data Error"
            }
        }
        
        var message: String {
            switch self {
            case .noLocationPermission:
                return "We need your location to show nearby Bitcoin places. Your location stays private and is only used on your device."
            case .locationServicesDisabled:
                return "Location services are disabled. Please enable them in Settings to see nearby Bitcoin places."
            case .locationUnavailable:
                return "Unable to determine your location. Please check your connection and try again."
            case .networkError(let error):
                return "Network connection failed: \(error.localizedDescription). Please check your internet connection."
            case .apiError(let message):
                return "Failed to load Bitcoin places: \(message)"
            case .noPlacesFound(let radius):
                return "No Bitcoin-accepting businesses found within \(Int(radius)) km of your location. Try expanding your search radius."
            case .cacheError:
                return "Failed to save or load cached data. Some features may not work offline."
            case .decodingError:
                return "Failed to process Bitcoin places data. Please try refreshing."
            }
        }
        
        var icon: String {
            switch self {
            case .noLocationPermission:
                return "location.slash.circle"
            case .locationServicesDisabled:
                return "location.slash"
            case .locationUnavailable:
                return "location.circle"
            case .networkError:
                return "wifi.slash"
            case .apiError:
                return "server.rack"
            case .noPlacesFound:
                return "map.circle"
            case .cacheError:
                return "externaldrive.trianglebadge.exclamationmark"
            case .decodingError:
                return "exclamationmark.triangle"
            }
        }
        
        var color: Color {
            switch self {
            case .noLocationPermission, .locationServicesDisabled:
                return .blue
            case .locationUnavailable, .networkError, .apiError, .cacheError, .decodingError:
                return .orange
            case .noPlacesFound:
                return .gray
            }
        }
        
        var primaryAction: ErrorAction? {
            switch self {
            case .noLocationPermission:
                return ErrorAction(title: "Enable Location", action: .requestLocation)
            case .locationServicesDisabled:
                return ErrorAction(title: "Open Settings", action: .openSettings)
            case .locationUnavailable, .networkError, .apiError, .decodingError:
                return ErrorAction(title: "Try Again", action: .retry)
            case .noPlacesFound:
                return ErrorAction(title: "Expand Search", action: .expandRadius)
            case .cacheError:
                return ErrorAction(title: "Clear Cache", action: .clearCache)
            }
        }
        
        var secondaryAction: ErrorAction? {
            switch self {
            case .noLocationPermission, .locationServicesDisabled:
                return ErrorAction(title: "Skip", action: .dismiss)
            case .noPlacesFound:
                return ErrorAction(title: "Refresh", action: .retry)
            default:
                return nil
            }
        }
    }
    
    // MARK: - Error Action
    
    struct ErrorAction {
        let title: String
        let action: ActionType
        
        enum ActionType {
            case requestLocation
            case openSettings
            case retry
            case expandRadius
            case clearCache
            case dismiss
        }
    }
    
    // MARK: - Static Methods
    
    /// Convert Core Location errors to BTCMapErrorType
    static func handleLocationError(_ error: Error) -> BTCMapErrorType {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                return .noLocationPermission
            case .locationUnknown:
                return .locationUnavailable
            case .network:
                return .networkError(error)
            default:
                return .locationUnavailable
            }
        }
        return .locationUnavailable
    }
    
    /// Convert network errors to BTCMapErrorType
    static func handleNetworkError(_ error: Error) -> BTCMapErrorType {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError(error)
            case .timedOut:
                return .apiError("Request timed out")
            case .cannotFindHost, .cannotConnectToHost:
                return .apiError("Cannot connect to server")
            default:
                return .networkError(error)
            }
        }
        return .networkError(error)
    }
    
    /// Check if error is recoverable
    static func isRecoverable(_ errorType: BTCMapErrorType) -> Bool {
        switch errorType {
        case .locationUnavailable, .networkError, .apiError, .decodingError:
            return true
        case .noLocationPermission, .locationServicesDisabled, .noPlacesFound, .cacheError:
            return false
        }
    }
    
    /// Get user-friendly error message for logging
    static func getLogMessage(_ errorType: BTCMapErrorType) -> String {
        switch errorType {
        case .noLocationPermission:
            return "User has not granted location permission"
        case .locationServicesDisabled:
            return "Location services are disabled system-wide"
        case .locationUnavailable:
            return "Unable to determine user location"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        case .noPlacesFound(let radius):
            return "No places found within \(radius)km radius"
        case .cacheError:
            return "Cache operation failed"
        case .decodingError:
            return "Failed to decode API response"
        }
    }
}

// MARK: - Error View Component

struct BTCMapErrorView: View {
    let errorType: BTCMapErrorHandler.BTCMapErrorType
    let onPrimaryAction: (() -> Void)?
    let onSecondaryAction: (() -> Void)?
    
    init(
        errorType: BTCMapErrorHandler.BTCMapErrorType,
        onPrimaryAction: (() -> Void)? = nil,
        onSecondaryAction: (() -> Void)? = nil
    ) {
        self.errorType = errorType
        self.onPrimaryAction = onPrimaryAction
        self.onSecondaryAction = onSecondaryAction
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: errorType.icon)
                .font(.system(size: 60))
                .foregroundColor(errorType.color)
            
            // Title and Message
            VStack(spacing: 8) {
                Text(errorType.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(errorType.message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                if let primaryAction = errorType.primaryAction {
                    Button(action: { onPrimaryAction?() }) {
                        Text(primaryAction.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(errorType.color)
                            .cornerRadius(12)
                    }
                }
                
                if let secondaryAction = errorType.secondaryAction {
                    Button(action: { onSecondaryAction?() }) {
                        Text(secondaryAction.title)
                            .font(.body)
                            .foregroundColor(errorType.color)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(errorType.color.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        BTCMapErrorView(
            errorType: .noLocationPermission,
            onPrimaryAction: { print("Primary action") },
            onSecondaryAction: { print("Secondary action") }
        )
        
        BTCMapErrorView(
            errorType: .noPlacesFound(radius: 5.0),
            onPrimaryAction: { print("Expand search") },
            onSecondaryAction: { print("Refresh") }
        )
    }
}
