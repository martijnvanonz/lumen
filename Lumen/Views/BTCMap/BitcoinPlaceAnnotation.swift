import Foundation
import MapKit
import SwiftUI
import CoreLocation

/// Custom annotation for Bitcoin places on the map
class BitcoinPlaceAnnotation: NSObject, MKAnnotation {
    let place: BTCPlace
    let userLocation: CLLocation?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
    }
    
    var title: String? {
        place.name ?? "Bitcoin Place"
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
    }
}

/// Custom annotation view for Bitcoin places
class BitcoinPlaceAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "BitcoinPlaceAnnotationView"
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        subviews.forEach { $0.removeFromSuperview() }
        setupView()
    }
}

/// Callout view for Bitcoin place details
class BitcoinPlaceCalloutView: UIView {
    private let place: BTCPlace
    private let userLocation: CLLocation?
    
    init(place: BTCPlace, userLocation: CLLocation?) {
        self.place = place
        self.userLocation = userLocation
        super.init(frame: CGRect(x: 0, y: 0, width: 250, height: 100))
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
        titleLabel.text = place.name ?? "Bitcoin Place"
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
        
        // Distance
        if let userLocation = userLocation {
            let distance = place.distance(from: userLocation)
            let distanceLabel = UILabel(frame: CGRect(x: 12, y: 50, width: 100, height: 16))
            distanceLabel.text = String(format: "%.1f km away", distance)
            distanceLabel.font = .systemFont(ofSize: 12)
            distanceLabel.textColor = .systemBlue
            addSubview(distanceLabel)
        }
        
        // Payment methods
        if !place.paymentMethods.isEmpty {
            let methodsContainer = createPaymentMethodsView()
            methodsContainer.frame = CGRect(x: 12, y: 70, width: 226, height: 20)
            addSubview(methodsContainer)
        }
    }
    
    private func createPaymentMethodsView() -> UIView {
        let container = UIView()
        let badgeHeight: CGFloat = 20
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
