import SwiftUI
import BreezSDKLiquid

/// A reusable component for displaying sats amounts with optional currency conversion
struct SatsAmountView: View {

    // MARK: - Properties

    let amount: UInt64
    let displayMode: DisplayMode
    let size: SizeVariant
    let style: StyleVariant
    let prefix: String?
    let showCurrencyConversion: Bool
    let formatLargeAmounts: Bool
    let alignment: HorizontalAlignment

    @ObservedObject private var currencyManager = CurrencyManager.shared

    // MARK: - Enums

    enum DisplayMode {
        case satsOnly
        case currencyOnly
        case both
        case stacked
    }

    enum SizeVariant {
        case compact
        case regular
        case large
        case huge

        var satsFont: Font {
            switch self {
            case .compact: return .caption
            case .regular: return .subheadline
            case .large: return .title3
            case .huge: return .system(size: 48, weight: .bold, design: .rounded)
            }
        }

        var currencyFont: Font {
            switch self {
            case .compact: return .caption2
            case .regular: return .caption
            case .large: return .subheadline
            case .huge: return .title3
            }
        }

        var spacing: CGFloat {
            switch self {
            case .compact: return 2
            case .regular: return 4
            case .large: return 6
            case .huge: return 8
            }
        }
    }

    enum StyleVariant {
        case primary
        case secondary
        case success
        case warning
        case error
        case white

        var color: Color {
            switch self {
            case .primary: return .primary
            case .secondary: return .secondary
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .white: return .white
            }
        }

        var currencyColor: Color {
            switch self {
            case .primary: return .secondary
            case .secondary: return .secondary
            case .success: return .green.opacity(0.8)
            case .warning: return .orange.opacity(0.8)
            case .error: return .red.opacity(0.8)
            case .white: return .white.opacity(0.8)
            }
        }
    }

    // MARK: - Initializer

    init(
        amount: UInt64,
        displayMode: DisplayMode = .both,
        size: SizeVariant = .regular,
        style: StyleVariant = .primary,
        prefix: String? = nil,
        showCurrencyConversion: Bool = true,
        formatLargeAmounts: Bool = false,
        alignment: HorizontalAlignment = .leading
    ) {
        self.amount = amount
        self.displayMode = displayMode
        self.size = size
        self.style = style
        self.prefix = prefix
        self.showCurrencyConversion = showCurrencyConversion
        self.formatLargeAmounts = formatLargeAmounts
        self.alignment = alignment
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch displayMode {
            case .satsOnly:
                satsOnlyView
            case .currencyOnly:
                currencyOnlyView
            case .both:
                bothInlineView
            case .stacked:
                stackedView
            }
        }
    }

    // MARK: - View Components

    private var satsOnlyView: some View {
        Text(formattedSatsText)
            .font(size.satsFont)
            .foregroundColor(style.color)
            .fontWeight(size == .huge ? .bold : .regular)
    }

    private var currencyOnlyView: some View {
        Group {
            if let currencyText = formattedCurrencyText {
                Text(currencyText)
                    .font(size.currencyFont)
                    .foregroundColor(style.color)
            } else {
                Text("Loading...")
                    .font(size.currencyFont)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var bothInlineView: some View {
        HStack(spacing: 4) {
            Text(formattedSatsText)
                .font(size.satsFont)
                .foregroundColor(style.color)
                .fontWeight(size == .huge ? .bold : .regular)

            if showCurrencyConversion, let currencyText = formattedCurrencyText {
                Text("(\(currencyText))")
                    .font(size.currencyFont)
                    .foregroundColor(style.currencyColor)
            } else if showCurrencyConversion && currencyManager.isLoadingRates {
                Text("(Loading...)")
                    .font(size.currencyFont)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var stackedView: some View {
        VStack(alignment: alignment, spacing: size.spacing) {
            Text(formattedSatsText)
                .font(size.satsFont)
                .foregroundColor(style.color)
                .fontWeight(size == .huge ? .bold : .regular)

            if showCurrencyConversion {
                if let currencyText = formattedCurrencyText {
                    Text("≈ \(currencyText)")
                        .font(size.currencyFont)
                        .foregroundColor(style.currencyColor)
                } else if currencyManager.isLoadingRates {
                    Text("Loading rate...")
                        .font(size.currencyFont)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var formattedSatsText: String {
        let baseAmount = formatLargeAmounts ? formatLargeAmount(amount) : "\(amount)"
        let suffix = formatLargeAmounts && isLargeAmount ? "" : " sats"

        if let prefix = prefix {
            return "\(prefix)\(baseAmount)\(suffix)"
        } else {
            return "\(baseAmount)\(suffix)"
        }
    }

    private var formattedCurrencyText: String? {
        guard showCurrencyConversion,
              let fiatAmount = currencyManager.convertSatsToFiat(amount),
              fiatAmount.isFinite && !fiatAmount.isNaN else {
            return nil
        }

        let formatted = currencyManager.formatFiatAmount(fiatAmount)
        return formatted.isEmpty ? nil : formatted
    }

    private var isLargeAmount: Bool {
        amount >= 1_000
    }

    // MARK: - Helper Methods

    private func formatLargeAmount(_ sats: UInt64) -> String {
        if sats >= 100_000_000 {
            let btc = Double(sats) / 100_000_000
            return String(format: "%.2f BTC", btc)
        } else if sats >= 1_000_000 {
            let millions = Double(sats) / 1_000_000
            return String(format: "%.1fM", millions)
        } else if sats >= 1_000 {
            let thousands = Double(sats) / 1_000
            return String(format: "%.1fK", thousands)
        } else {
            return "\(sats)"
        }
    }
}

// MARK: - Convenience Initializers

extension SatsAmountView {

    /// Balance display variant (large, stacked, with currency)
    static func balance(_ amount: UInt64) -> SatsAmountView {
        SatsAmountView(
            amount: amount,
            displayMode: .stacked,
            size: .huge,
            style: .white,
            showCurrencyConversion: true,
            alignment: .center
        )
    }

    /// Transaction amount variant (with +/- prefix)
    static func transaction(_ amount: UInt64, isReceive: Bool) -> SatsAmountView {
        SatsAmountView(
            amount: amount,
            displayMode: .both,
            size: .regular,
            style: isReceive ? .success : .warning,
            prefix: isReceive ? "+" : "-"
        )
    }

    /// Fee display variant (compact, warning color)
    static func fee(_ amount: UInt64) -> SatsAmountView {
        SatsAmountView(
            amount: amount,
            displayMode: .both,
            size: .compact,
            style: .warning
        )
    }

    /// Compact list variant
    static func compact(_ amount: UInt64) -> SatsAmountView {
        SatsAmountView(
            amount: amount,
            displayMode: .both,
            size: .compact,
            style: .primary
        )
    }
}