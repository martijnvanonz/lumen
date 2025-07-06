import Foundation
import MapKit
import SwiftUI
import CoreLocation
import Combine

/// Custom annotation for Bitcoin places on the map
class BitcoinPlaceAnnotation: NSObject, MKAnnotation {
    private(set) var place: BTCPlace
    let userLocation: CLLocation?
    @Published var isLoadingDetails = false

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
    }
    
    var title: String? {
        // Use actual name if available
        if let name = place.name {
            return name
        }

        // Fallback to business type based on icon
        let businessType = BitcoinPlaceAnnotation.getBusinessTypeFromIcon(place.icon)
        return businessType
    }
    
    var subtitle: String? {
        if let userLocation = userLocation {
            let distance = place.distance(from: userLocation)
            return String(format: "%.1f km away", distance)
        }
        return nil
    }
    
    init(place: BTCPlace, userLocation: CLLocation?) {
        self.place = place
        self.userLocation = userLocation
        super.init()

        // Start loading details if we don't have a name yet
        if place.name == nil {
            loadPlaceDetails()
        }
    }

    /// Load detailed information for this place
    func loadPlaceDetails() {
        // Skip if we already have details or are loading
        guard place.name == nil && !isLoadingDetails else { return }

        isLoadingDetails = true

        Task {
            do {
                let details = try await BTCMapService.shared.fetchPlaceDetails(id: place.id)
                await MainActor.run {
                    self.place = details
                    self.isLoadingDetails = false
                }
            } catch {
                await MainActor.run {
                    // Keep the original place data on error
                    self.isLoadingDetails = false
                }
                print("❌ Failed to load details for place \(place.id): \(error)")
            }
        }
    }

    /// Get a human-readable business type from the OSM icon
    static func getBusinessTypeFromIcon(_ icon: String) -> String {
        switch icon.lowercased() {
        case "restaurant", "fast_food":
            return "Restaurant"
        case "cafe":
            return "Café"
        case "bar", "pub":
            return "Bar"
        case "hotel", "guest_house":
            return "Hotel"
        case "shop", "convenience":
            return "Shop"
        case "fuel":
            return "Gas Station"
        case "bank", "atm":
            return "Bank/ATM"
        case "pharmacy":
            return "Pharmacy"
        case "hospital", "clinic":
            return "Healthcare"
        case "school", "university":
            return "Education"
        case "theatre", "cinema":
            return "Entertainment"
        case "gym", "fitness":
            return "Fitness"
        case "beauty", "hairdresser":
            return "Beauty"
        case "car_repair":
            return "Auto Repair"
        case "supermarket":
            return "Supermarket"
        case "bakery":
            return "Bakery"
        case "butcher":
            return "Butcher"
        case "electronics":
            return "Electronics"
        case "clothing":
            return "Clothing"
        case "books":
            return "Bookstore"
        case "jewelry":
            return "Jewelry"
        case "florist":
            return "Florist"
        case "hardware":
            return "Hardware Store"
        case "laundry":
            return "Laundry"
        case "dentist":
            return "Dentist"
        case "veterinary":
            return "Veterinary"
        case "taxi":
            return "Taxi"
        case "parking":
            return "Parking"
        case "post_office":
            return "Post Office"
        case "library":
            return "Library"
        case "museum":
            return "Museum"
        case "place_of_worship":
            return "Place of Worship"
        case "tourism":
            return "Tourist Attraction"
        default:
            return "Bitcoin Business"
        }
    }
}

/// Custom annotation view for Bitcoin places
class BitcoinPlaceAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "BitcoinPlaceAnnotationView"
    private var cancellables = Set<AnyCancellable>()
    private var loadingIndicator: UIActivityIndicatorView?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
        setupLoadingObserver()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
        setupLoadingObserver()
    }

    private func setupLoadingObserver() {
        guard let bitcoinAnnotation = annotation as? BitcoinPlaceAnnotation else { return }

        bitcoinAnnotation.$isLoadingDetails
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            }
            .store(in: &cancellables)
    }

    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            showLoadingIndicator()
        } else {
            hideLoadingIndicator()
            // Refresh the pin view with updated data
            setupView()
        }
    }

    private func showLoadingIndicator() {
        guard loadingIndicator == nil else { return }

        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.frame = CGRect(x: 32, y: 8, width: 16, height: 16)
        indicator.startAnimating()
        indicator.color = UIColor.systemBlue

        addSubview(indicator)
        loadingIndicator = indicator
    }

    private func hideLoadingIndicator() {
        loadingIndicator?.removeFromSuperview()
        loadingIndicator = nil
    }
    
    private func setupView() {
        canShowCallout = true
        calloutOffset = CGPoint(x: -5, y: 5)
        
        // Create the pin view
        let pinView = createPinView()
        addSubview(pinView)
        
        // Set frame
        frame = CGRect(x: 0, y: 0, width: 40, height: 50)
        
        // Add right callout accessory (navigate button)
        let navigateButton = UIButton(type: .detailDisclosure)
        navigateButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        navigateButton.tintColor = .systemBlue
        rightCalloutAccessoryView = navigateButton
    }
    
    private func createPinView() -> UIView {
        guard let annotation = annotation as? BitcoinPlaceAnnotation else {
            return createDefaultPin()
        }
        
        let place = annotation.place
        
        // Main pin container
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 50))
        
        // Pin background (circle)
        let pinBackground = UIView(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
        pinBackground.backgroundColor = getPinColor(for: place)
        pinBackground.layer.cornerRadius = 15
        pinBackground.layer.borderWidth = 2
        pinBackground.layer.borderColor = UIColor.white.cgColor
        pinBackground.layer.shadowColor = UIColor.black.cgColor
        pinBackground.layer.shadowOffset = CGSize(width: 0, height: 2)
        pinBackground.layer.shadowOpacity = 0.3
        pinBackground.layer.shadowRadius = 3
        
        // Icon
        let iconImageView = UIImageView(frame: CGRect(x: 8, y: 8, width: 14, height: 14))
        iconImageView.image = UIImage(systemName: place.systemIcon)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        
        pinBackground.addSubview(iconImageView)
        containerView.addSubview(pinBackground)
        
        // Payment method indicators
        if !place.paymentMethods.isEmpty {
            let indicatorContainer = createPaymentIndicators(for: place.paymentMethods)
            indicatorContainer.frame = CGRect(x: 0, y: 35, width: 40, height: 15)
            containerView.addSubview(indicatorContainer)
        }

        // Verification status indicator
        if place.isRecentlyVerified {
            let verificationBadge = createVerificationBadge()
            verificationBadge.frame = CGRect(x: 25, y: 5, width: 12, height: 12)
            containerView.addSubview(verificationBadge)
        }

        // Promoted status indicator
        if place.isBoosted {
            let promotedBadge = createPromotedBadge()
            promotedBadge.frame = CGRect(x: 25, y: place.isRecentlyVerified ? 18 : 5, width: 12, height: 12)
            containerView.addSubview(promotedBadge)
        }

        return containerView
    }
    
    private func createDefaultPin() -> UIView {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 50))
        
        let pinBackground = UIView(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
        pinBackground.backgroundColor = .systemBlue
        pinBackground.layer.cornerRadius = 15
        pinBackground.layer.borderWidth = 2
        pinBackground.layer.borderColor = UIColor.white.cgColor
        
        let iconImageView = UIImageView(frame: CGRect(x: 8, y: 8, width: 14, height: 14))
        iconImageView.image = UIImage(systemName: "storefront")
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        
        pinBackground.addSubview(iconImageView)
        containerView.addSubview(pinBackground)
        
        return containerView
    }
    
    private func getPinColor(for place: BTCPlace) -> UIColor {
        // Color based on merchant type
        switch place.icon.lowercased() {
        case "cafe", "local_cafe":
            return .systemBrown
        case "restaurant", "lunch_dining", "dinner_dining":
            return .systemOrange
        case "bar", "local_bar":
            return .systemPurple
        case "hotel", "lodging":
            return .systemIndigo
        case "gas_station":
            return .systemRed
        case "shopping_cart", "store":
            return .systemGreen
        case "content_cut":
            return .systemPink
        case "local_atm":
            return .systemYellow
        case "car_repair":
            return .systemGray
        default:
            return .systemBlue
        }
    }
    
    private func createPaymentIndicators(for methods: [PaymentMethod]) -> UIView {
        let container = UIView()
        let indicatorSize: CGFloat = 12
        let spacing: CGFloat = 2
        let totalWidth = CGFloat(methods.count) * indicatorSize + CGFloat(methods.count - 1) * spacing
        let startX = (40 - totalWidth) / 2
        
        for (index, method) in methods.enumerated() {
            let indicator = UIView(frame: CGRect(
                x: startX + CGFloat(index) * (indicatorSize + spacing),
                y: 0,
                width: indicatorSize,
                height: indicatorSize
            ))
            
            indicator.backgroundColor = getPaymentMethodColor(for: method)
            indicator.layer.cornerRadius = indicatorSize / 2
            indicator.layer.borderWidth = 1
            indicator.layer.borderColor = UIColor.white.cgColor
            
            // Add payment method icon
            let iconImageView = UIImageView(frame: CGRect(x: 2, y: 2, width: 8, height: 8))
            iconImageView.image = UIImage(systemName: method.icon)
            iconImageView.tintColor = .white
            iconImageView.contentMode = .scaleAspectFit
            
            indicator.addSubview(iconImageView)
            container.addSubview(indicator)
        }
        
        return container
    }
    
    private func getPaymentMethodColor(for method: PaymentMethod) -> UIColor {
        switch method {
        case .lightning:
            return .systemYellow
        case .onchain:
            return .systemOrange
        case .nfc:
            return .systemBlue
        }
    }

    private func createVerificationBadge() -> UIView {
        let badgeView = UIView()
        badgeView.backgroundColor = .systemGreen
        badgeView.layer.cornerRadius = 6

        // Add checkmark icon
        let checkmarkImageView = UIImageView(frame: CGRect(x: 2, y: 2, width: 8, height: 8))
        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = .white
        checkmarkImageView.contentMode = .scaleAspectFit

        badgeView.addSubview(checkmarkImageView)
        return badgeView
    }

    private func createPromotedBadge() -> UIView {
        let badgeView = UIView()
        badgeView.backgroundColor = .systemOrange
        badgeView.layer.cornerRadius = 6

        // Add star icon
        let starImageView = UIImageView(frame: CGRect(x: 2, y: 2, width: 8, height: 8))
        starImageView.image = UIImage(systemName: "star.fill")
        starImageView.tintColor = .white
        starImageView.contentMode = .scaleAspectFit

        badgeView.addSubview(starImageView)
        return badgeView
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        subviews.forEach { $0.removeFromSuperview() }
        cancellables.removeAll()
        loadingIndicator = nil
        setupView()
        setupLoadingObserver()
    }
}

/// Callout view for Bitcoin place details
class BitcoinPlaceCalloutView: UIView {
    private let place: BTCPlace
    private let userLocation: CLLocation?
    
    init(place: BTCPlace, userLocation: CLLocation?) {
        self.place = place
        self.userLocation = userLocation
        super.init(frame: CGRect(x: 0, y: 0, width: 250, height: 120))
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 4
        
        // Title
        let titleLabel = UILabel(frame: CGRect(x: 12, y: 8, width: 226, height: 20))
        titleLabel.text = place.name ?? BitcoinPlaceAnnotation.getBusinessTypeFromIcon(place.icon)
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textColor = .label
        addSubview(titleLabel)
        
        // Address
        if let address = place.address {
            let addressLabel = UILabel(frame: CGRect(x: 12, y: 28, width: 226, height: 16))
            addressLabel.text = address
            addressLabel.font = .systemFont(ofSize: 14)
            addressLabel.textColor = .secondaryLabel
            addressLabel.numberOfLines = 2
            addSubview(addressLabel)
        }
        
        // Distance and status indicators
        var yOffset = 50
        if let userLocation = userLocation {
            let distance = place.distance(from: userLocation)
            let distanceLabel = UILabel(frame: CGRect(x: 12, y: yOffset, width: 100, height: 16))
            distanceLabel.text = String(format: "%.1f km away", distance)
            distanceLabel.font = .systemFont(ofSize: 12)
            distanceLabel.textColor = .systemBlue
            addSubview(distanceLabel)

            // Add status indicators next to distance
            var statusX = 120

            if place.isRecentlyVerified {
                let verificationIcon = UIImageView(frame: CGRect(x: statusX, y: yOffset + 2, width: 12, height: 12))
                verificationIcon.image = UIImage(systemName: "checkmark.seal.fill")
                verificationIcon.tintColor = .systemGreen
                verificationIcon.contentMode = .scaleAspectFit
                addSubview(verificationIcon)
                statusX += 18
            }

            if place.isBoosted {
                let promotedLabel = UILabel(frame: CGRect(x: statusX, y: yOffset, width: 60, height: 16))
                promotedLabel.text = "PROMOTED"
                promotedLabel.font = .systemFont(ofSize: 8, weight: .bold)
                promotedLabel.textColor = .white
                promotedLabel.backgroundColor = .systemOrange
                promotedLabel.textAlignment = .center
                promotedLabel.layer.cornerRadius = 3
                promotedLabel.layer.masksToBounds = true
                addSubview(promotedLabel)
            }

            yOffset += 20
        }
        
        // Payment methods
        if !place.paymentMethods.isEmpty {
            let methodsContainer = createPaymentMethodsView()
            methodsContainer.frame = CGRect(x: 12, y: yOffset, width: 226, height: 20)
            addSubview(methodsContainer)
            yOffset += 25
        }

        // Update frame height based on content
        frame = CGRect(x: 0, y: 0, width: 250, height: max(100, yOffset + 10))
    }
    
    private func createPaymentMethodsView() -> UIView {
        let container = UIView()
        var currentX: CGFloat = 0
        
        for method in place.paymentMethods {
            let badge = createPaymentMethodBadge(for: method)
            badge.frame.origin.x = currentX
            container.addSubview(badge)
            currentX += badge.frame.width + 4
        }
        
        return container
    }
    
    private func createPaymentMethodBadge(for method: PaymentMethod) -> UIView {
        let badge = UIView()
        badge.backgroundColor = getPaymentMethodColor(for: method).withAlphaComponent(0.15)
        badge.layer.cornerRadius = 10
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: method.icon)
        iconImageView.tintColor = getPaymentMethodColor(for: method)
        iconImageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = method.displayName
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = getPaymentMethodColor(for: method)
        
        let stackView = UIStackView(arrangedSubviews: [iconImageView, label])
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.alignment = .center
        
        badge.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 6),
            stackView.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -6),
            stackView.topAnchor.constraint(equalTo: badge.topAnchor, constant: 3),
            stackView.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -3),
            iconImageView.widthAnchor.constraint(equalToConstant: 12),
            iconImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        // Calculate badge width
        let textWidth = label.intrinsicContentSize.width
        badge.frame = CGRect(x: 0, y: 0, width: textWidth + 24, height: 20)
        
        return badge
    }
    
    private func getPaymentMethodColor(for method: PaymentMethod) -> UIColor {
        switch method {
        case .lightning:
            return .systemYellow
        case .onchain:
            return .systemOrange
        case .nfc:
            return .systemBlue
        }
    }
}
