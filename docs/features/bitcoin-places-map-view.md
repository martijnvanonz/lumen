# Bitcoin Places Map View Feature

## Overview

The Bitcoin Places Map View is an interactive map feature that displays Bitcoin-accepting merchants as custom pins on a map. This feature extends the existing Bitcoin Places list view with a visual, geographic representation of nearby merchants.

## Features

### 🗺️ Interactive Map
- **MapKit Integration**: Uses Apple's MapKit framework for native iOS map experience
- **User Location**: Shows user's current location with proper permissions handling
- **Custom Pins**: Bitcoin places displayed as custom pins with merchant type icons
- **Zoom & Pan**: Full gesture support for map navigation
- **Initial Centering**: Map centers on user location with appropriate zoom level

### 📍 Custom Map Pins
- **Merchant Type Icons**: Different icons based on business type (restaurant, cafe, hotel, etc.)
- **Color Coding**: Pin colors vary by merchant category for easy identification
- **Payment Method Indicators**: Small badges showing accepted payment methods (⚡Lightning, 🔗Onchain, 📱NFC)
- **Pin Callouts**: Tap pins to see merchant details including name, address, and distance
- **Navigation Integration**: "Navigate" button in callouts opens Apple Maps for directions

### 🎛️ User Interface
- **View Toggle**: Segmented control to switch between List and Map views
- **Search Radius**: Existing radius filtering (1km, 2.5km, 5km, 10km, 20km) works with map
- **Map Controls**: Floating buttons for zoom-to-user and refresh functionality
- **Clustering**: Pins automatically cluster when zoomed out to reduce clutter
- **Refresh Integration**: Pull-to-refresh and manual refresh update map pins

### 🔧 Technical Implementation

#### Files Created/Modified

**New Files:**
- `Views/BTCMap/BitcoinPlacesMapView.swift` - Main map view implementation
- `Views/BTCMap/BitcoinPlaceAnnotation.swift` - Custom annotation and annotation view classes

**Modified Files:**
- `Views/BTCMap/PlacesListView.swift` - Added view mode toggle and map integration
- `Services/BTCMap/BTCPlace.swift` - Added simple initializer for testing/previews

#### Architecture

```
PlacesListView
├── ViewMode enum (List/Map)
├── Segmented Control Toggle
└── Conditional View Rendering
    ├── PlacesList (existing)
    └── BitcoinPlacesMapViewWithControls (new)
        ├── BitcoinPlacesMapView (UIViewRepresentable)
        │   ├── MKMapView
        │   ├── BitcoinPlaceAnnotation (custom annotations)
        │   └── BitcoinPlaceAnnotationView (custom pin views)
        └── MapControlsOverlay (floating controls)
```

#### Key Components

**BitcoinPlaceAnnotation**
- Conforms to `MKAnnotation` protocol
- Stores `BTCPlace` reference and user location
- Provides coordinate, title, and subtitle for map display

**BitcoinPlaceAnnotationView**
- Custom `MKAnnotationView` subclass
- Creates visual pin with merchant icon and payment method indicators
- Handles callout configuration with navigation button

**BitcoinPlacesMapView**
- `UIViewRepresentable` wrapper for `MKMapView`
- Implements `MKMapViewDelegate` for custom pin rendering
- Handles annotation clustering and user interaction
- Manages map region updates based on user location

**MapControlsOverlay**
- SwiftUI overlay with floating action buttons
- Zoom-to-user functionality
- Refresh button with loading animation
- Positioned to avoid UI conflicts

## Usage

### For Users

1. **Access Map View**: Tap the Bitcoin Places card from the main wallet view
2. **Switch to Map**: Use the segmented control at the top to switch from List to Map view
3. **Explore Merchants**: 
   - Pan and zoom the map to explore different areas
   - Tap pins to see merchant details
   - Use the "Navigate" button to get directions
4. **Filter by Distance**: Use the menu (⋯) to adjust search radius
5. **Refresh Data**: Pull down or tap the refresh button to update merchant data
6. **Zoom to Location**: Tap the location button to center map on your current position

### For Developers

#### Adding New Pin Types
```swift
// In BitcoinPlaceAnnotationView.getPinColor(for:)
case "new_merchant_type":
    return .systemTeal
```

#### Customizing Payment Method Indicators
```swift
// In PaymentMethod enum
case newPaymentMethod = "new_method"

var icon: String {
    case .newPaymentMethod: return "new.icon"
}
```

#### Extending Map Functionality
```swift
// Add new map delegate methods in BitcoinPlacesMapView.Coordinator
func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    // Handle region changes
}
```

## Testing

### Preview Support
The map view includes SwiftUI preview support with sample data:

```swift
#Preview {
    var samplePlace = BTCPlace(id: 1, lat: 52.3676, lon: 4.9041, icon: "restaurant")
    samplePlace.name = "Bitcoin Cafe"
    // ... configure sample data
    
    return BitcoinPlacesMapViewWithControls(
        places: [samplePlace],
        userLocation: userLocation,
        searchRadius: 5.0
    )
}
```

### Manual Testing Checklist
- [ ] Map loads with user location centered
- [ ] Pins display with correct icons and colors
- [ ] Pin callouts show merchant information
- [ ] Navigation button opens Apple Maps
- [ ] View toggle switches between list and map
- [ ] Search radius filtering works on map
- [ ] Refresh updates map pins
- [ ] Clustering works when zoomed out
- [ ] Location permission handling works correctly

## Performance Considerations

- **Pin Clustering**: Reduces visual clutter and improves performance with many merchants
- **Annotation Reuse**: Uses `dequeueReusableAnnotationView` for memory efficiency
- **Region Updates**: Only updates map region when user moves significantly (>1km)
- **Lazy Loading**: Map view only created when map mode is selected

## Future Enhancements

### Potential Improvements
1. **Search Integration**: Add search bar to find specific merchants on map
2. **Filters**: Filter pins by payment method, merchant type, or verification status
3. **Directions Integration**: In-app directions instead of launching Apple Maps
4. **Merchant Details**: Full-screen detail view when tapping pins
5. **Offline Support**: Cache map tiles for offline viewing
6. **Custom Map Styles**: Different map appearances (satellite, hybrid)
7. **Heat Map**: Show merchant density in different areas
8. **Route Planning**: Multi-stop route planning for visiting multiple merchants

### Technical Debt
- Consider extracting pin styling logic into separate utility classes
- Add unit tests for annotation view creation and styling
- Implement proper error handling for map loading failures
- Add accessibility support for map pins and controls

## Dependencies

- **MapKit**: Apple's mapping framework (already included in iOS)
- **CoreLocation**: For location services (already used in project)
- **SwiftUI**: For UI components and integration
- **UIKit**: For custom annotation views and map controls

## Compatibility

- **iOS Version**: Requires iOS 14.0+ (same as existing app requirements)
- **Device Support**: iPhone and iPad compatible
- **Accessibility**: Basic VoiceOver support through MapKit defaults
- **Performance**: Optimized for devices with limited memory through annotation reuse
