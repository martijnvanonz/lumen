import SwiftUI
import BreezSDKLiquid

/// Extension to provide currency icons and visual styling
extension FiatCurrency {
    
    /// Returns an appropriate SF Symbol for the currency
    var icon: String {
        switch id.lowercased() {
        case "usd":
            return "dollarsign.circle.fill"
        case "eur":
            return "eurosign.circle.fill"
        case "gbp":
            return "sterlingsign.circle.fill"
        case "jpy":
            return "yensign.circle.fill"
        case "cad":
            return "dollarsign.circle.fill"
        case "aud":
            return "dollarsign.circle.fill"
        case "chf":
            return "francsign.circle.fill"
        case "cny":
            return "yensign.circle.fill"
        case "inr":
            return "indianrupeesign.circle.fill"
        case "krw":
            return "wonsign.circle.fill"
        case "rub":
            return "rublesign.circle.fill"
        case "brl":
            return "brazilianrealsign.circle.fill"
        case "mxn":
            return "pesosign.circle.fill"
        case "try":
            return "turkishlirasign.circle.fill"
        case "ils":
            return "shekelsign.circle.fill"
        case "thb":
            return "bahtsign.circle.fill"
        case "php":
            return "pesosign.circle.fill"
        default:
            return "circle.fill"
        }
    }
    
    /// Returns the color for the currency icon
    var iconColor: Color {
        switch id.lowercased() {
        case "usd":
            return .green
        case "eur":
            return .blue
        case "gbp":
            return .purple
        case "jpy":
            return .red
        case "cad":
            return .red
        case "aud":
            return .orange
        case "chf":
            return .red
        case "cny":
            return .red
        case "inr":
            return .orange
        case "krw":
            return .blue
        case "rub":
            return .blue
        case "brl":
            return .green
        case "mxn":
            return .green
        case "try":
            return .red
        case "ils":
            return .blue
        case "thb":
            return .orange
        case "php":
            return .blue
        default:
            return .gray
        }
    }
    
    /// Returns a formatted display name for the currency
    var displayName: String {
        return info.name
    }
    
    /// Returns the currency code in uppercase
    var displayCode: String {
        return id.uppercased()
    }
}

/// Custom view for displaying currency in grid format
struct CurrencyGridItem: View {
    let currency: FiatCurrency
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Currency Icon
                Image(systemName: currency.icon)
                    .font(.system(size: 32))
                    .foregroundColor(currency.iconColor)
                    .frame(width: 44, height: 44)
                
                // Currency Code
                Text(currency.displayCode)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Currency Name
                Text(currency.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.yellow.opacity(0.15) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.yellow : Color.gray.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .overlay(
                // Selection checkmark
                VStack {
                    HStack {
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                                .background(Color.white.clipShape(Circle()))
                        }
                    }
                    Spacer()
                }
                .padding(8),
                alignment: .topTrailing
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
