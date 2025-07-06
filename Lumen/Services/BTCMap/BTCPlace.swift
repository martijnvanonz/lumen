import Foundation
import CoreLocation

/// Represents a Bitcoin-accepting place from BTC Map
struct BTCPlace: Codable, Identifiable {
    let id: Int
    let lat: Double
    let lon: Double
    let icon: String
    
    // Optional details (fetched separately from API)
    var name: String?
    var address: String?
    var phone: String?
    var website: String?
    var openingHours: String?
    var comments: Int?
    var verifiedAt: String?
    var boostedUntil: String?
    
    // Payment methods
    var acceptsLightning: Bool = false
    var acceptsOnchain: Bool = false
    var acceptsNFC: Bool = false
    
    // Metadata
    var createdAt: String?
    var updatedAt: String?
    var deletedAt: String?
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id, lat, lon, icon, name, address, phone, website, comments
        case openingHours = "opening_hours"
        case verifiedAt = "verified_at"
        case boostedUntil = "boosted_until"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        
        // Payment method keys from OSM tags
        case paymentLightning = "payment:lightning"
        case paymentOnchain = "payment:onchain"
        case paymentLightningContactless = "payment:lightning_contactless"
    }
    
    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields
        id = try container.decode(Int.self, forKey: .id)
        lat = try container.decode(Double.self, forKey: .lat)
        lon = try container.decode(Double.self, forKey: .lon)
        icon = try container.decode(String.self, forKey: .icon)

        // Optional fields
        name = try container.decodeIfPresent(String.self, forKey: .name)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        openingHours = try container.decodeIfPresent(String.self, forKey: .openingHours)
        comments = try container.decodeIfPresent(Int.self, forKey: .comments)
        verifiedAt = try container.decodeIfPresent(String.self, forKey: .verifiedAt)
        boostedUntil = try container.decodeIfPresent(String.self, forKey: .boostedUntil)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(String.self, forKey: .deletedAt)

        // Payment methods - decode as strings and convert to booleans
        if let lightningValue = try container.decodeIfPresent(String.self, forKey: .paymentLightning) {
            acceptsLightning = lightningValue.lowercased() == "yes"
        } else {
            acceptsLightning = false
        }

        if let onchainValue = try container.decodeIfPresent(String.self, forKey: .paymentOnchain) {
            acceptsOnchain = onchainValue.lowercased() == "yes"
        } else {
            acceptsOnchain = false
        }

        if let nfcValue = try container.decodeIfPresent(String.self, forKey: .paymentLightningContactless) {
            acceptsNFC = nfcValue.lowercased() == "yes"
        } else {
            acceptsNFC = false
        }
    }

    // MARK: - Custom Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Required fields
        try container.encode(id, forKey: .id)
        try container.encode(lat, forKey: .lat)
        try container.encode(lon, forKey: .lon)
        try container.encode(icon, forKey: .icon)

        // Optional fields
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(openingHours, forKey: .openingHours)
        try container.encodeIfPresent(comments, forKey: .comments)
        try container.encodeIfPresent(verifiedAt, forKey: .verifiedAt)
        try container.encodeIfPresent(boostedUntil, forKey: .boostedUntil)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(deletedAt, forKey: .deletedAt)

        // Payment methods - encode as strings
        try container.encode(acceptsLightning ? "yes" : "no", forKey: .paymentLightning)
        try container.encode(acceptsOnchain ? "yes" : "no", forKey: .paymentOnchain)
        try container.encode(acceptsNFC ? "yes" : "no", forKey: .paymentLightningContactless)
    }
    
    // MARK: - Computed Properties
    
    /// Core Location representation of the place's coordinates
    var location: CLLocation {
        CLLocation(latitude: lat, longitude: lon)
    }
    
    /// Calculate distance from user location in kilometers
    func distance(from userLocation: CLLocation) -> Double {
        location.distance(from: userLocation) / 1000.0 // Convert meters to kilometers
    }
    
    /// Check if the place was recently verified (within last 6 months)
    var isRecentlyVerified: Bool {
        guard let verifiedAt = verifiedAt else { return false }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let verifiedDate = formatter.date(from: verifiedAt) else { return false }
        
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return verifiedDate > sixMonthsAgo
    }
    
    /// Check if the place is currently boosted
    var isBoosted: Bool {
        guard let boostedUntil = boostedUntil else { return false }
        
        let formatter = ISO8601DateFormatter()
        guard let boostedDate = formatter.date(from: boostedUntil) else { return false }
        
        return boostedDate > Date()
    }
    
    /// Get the appropriate SF Symbol icon for the place type
    var systemIcon: String {
        switch icon.lowercased() {
        case "cafe", "local_cafe":
            return "cup.and.saucer"
        case "restaurant", "lunch_dining", "dinner_dining":
            return "fork.knife"
        case "bar", "local_bar":
            return "wineglass"
        case "hotel", "lodging":
            return "bed.double"
        case "gas_station":
            return "fuelpump"
        case "shopping_cart", "store":
            return "cart"
        case "content_cut":
            return "scissors"
        case "local_atm":
            return "banknote"
        case "car_repair":
            return "wrench.and.screwdriver"
        default:
            return "storefront"
        }
    }
    
    /// Get payment method badges as array of strings
    var paymentMethods: [PaymentMethod] {
        var methods: [PaymentMethod] = []
        
        if acceptsLightning {
            methods.append(.lightning)
        }
        
        if acceptsOnchain {
            methods.append(.onchain)
        }
        
        if acceptsNFC {
            methods.append(.nfc)
        }
        
        return methods
    }
}

// MARK: - Payment Method Enum

enum PaymentMethod: String, CaseIterable {
    case lightning = "lightning"
    case onchain = "onchain"
    case nfc = "nfc"
    
    var displayName: String {
        switch self {
        case .lightning:
            return "Lightning"
        case .onchain:
            return "Onchain"
        case .nfc:
            return "NFC"
        }
    }
    
    var icon: String {
        switch self {
        case .lightning:
            return "bolt.fill"
        case .onchain:
            return "link"
        case .nfc:
            return "wave.3.right"
        }
    }
    
    var color: String {
        switch self {
        case .lightning:
            return "yellow"
        case .onchain:
            return "orange"
        case .nfc:
            return "blue"
        }
    }
}

// MARK: - Extensions

extension BTCPlace: Equatable {
    static func == (lhs: BTCPlace, rhs: BTCPlace) -> Bool {
        lhs.id == rhs.id
    }
}

extension BTCPlace: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
