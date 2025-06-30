import SwiftUI
import BreezSDKLiquid

struct FeeComparisonView: View {
    let lightningFeeSats: UInt64
    let paymentAmountSats: UInt64
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fee Comparison")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Lightning Network fee
                FeeComparisonRow(
                    title: "Lightning Network",
                    fee: lightningFeeSats,
                    amount: paymentAmountSats,
                    color: .yellow,
                    icon: "bolt.fill",
                    isRecommended: true
                )
                
                // Traditional payment comparisons
                FeeComparisonRow(
                    title: "Credit Card (3%)",
                    fee: UInt64(Double(paymentAmountSats) * 0.03),
                    amount: paymentAmountSats,
                    color: .blue,
                    icon: "creditcard.fill"
                )
                
                FeeComparisonRow(
                    title: "Bank Wire ($25)",
                    fee: UInt64(25 * 100_000_000 / 45000), // ~$25 in sats at $45k BTC
                    amount: paymentAmountSats,
                    color: .gray,
                    icon: "building.columns.fill"
                )
                
                FeeComparisonRow(
                    title: "PayPal (2.9% + $0.30)",
                    fee: UInt64(Double(paymentAmountSats) * 0.029 + (0.30 * 100_000_000 / 45000)),
                    amount: paymentAmountSats,
                    color: .purple,
                    icon: "p.circle.fill"
                )
            }
            
            // Savings summary
            let creditCardFee = UInt64(Double(paymentAmountSats) * 0.03)
            if lightningFeeSats < creditCardFee {
                let savings = creditCardFee - lightningFeeSats
                let savingsPercentage = Double(savings) / Double(creditCardFee) * 100
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Save \(savings) sats (\(String(format: "%.1f", savingsPercentage))%) vs credit cards")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

struct FeeComparisonRow: View {
    let title: String
    let fee: UInt64
    let amount: UInt64
    let color: Color
    let icon: String
    let isRecommended: Bool
    
    init(title: String, fee: UInt64, amount: UInt64, color: Color, icon: String, isRecommended: Bool = false) {
        self.title = title
        self.fee = fee
        self.amount = amount
        self.color = color
        self.icon = icon
        self.isRecommended = isRecommended
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            // Payment method info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if isRecommended {
                        Text("RECOMMENDED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }
                
                Text("\(fee) sats (\(feePercentage)%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Fee amount
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(fee)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text("sats")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isRecommended ? color.opacity(0.1) : Color.clear)
        )
    }
    
    private var feePercentage: String {
        let percentage = Double(fee) / Double(amount) * 100
        return String(format: "%.2f", percentage)
    }
}

// MARK: - Fee Education View

struct FeeEducationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why Lightning Fees Are Lower")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                EducationPoint(
                    icon: "network",
                    title: "Direct Peer-to-Peer",
                    description: "No intermediary banks or payment processors taking cuts"
                )
                
                EducationPoint(
                    icon: "bolt.fill",
                    title: "Instant Settlement",
                    description: "No waiting periods or clearing houses to pay"
                )
                
                EducationPoint(
                    icon: "globe",
                    title: "Global Network",
                    description: "Same low fees whether paying locally or internationally"
                )
                
                EducationPoint(
                    icon: "lock.shield.fill",
                    title: "Cryptographic Security",
                    description: "No fraud protection fees - math guarantees security"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct EducationPoint: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Fee Breakdown View

struct FeeBreakdownView: View {
    let preparedPayment: PrepareSendResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fee Breakdown")
                .font(.headline)
            
            VStack(spacing: 8) {
                FeeBreakdownRow(
                    label: "Base Fee",
                    amount: preparedPayment.feesSat / 2, // Simplified breakdown
                    description: "Fixed cost per transaction"
                )
                
                FeeBreakdownRow(
                    label: "Routing Fee",
                    amount: preparedPayment.feesSat / 2,
                    description: "Cost to route through Lightning Network"
                )
                
                Divider()
                
                FeeBreakdownRow(
                    label: "Total Lightning Fee",
                    amount: preparedPayment.feesSat,
                    description: "All fees included",
                    isTotal: true
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

struct FeeBreakdownRow: View {
    let label: String
    let amount: UInt64
    let description: String
    let isTotal: Bool
    
    init(label: String, amount: UInt64, description: String, isTotal: Bool = false) {
        self.label = label
        self.amount = amount
        self.description = description
        self.isTotal = isTotal
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(isTotal ? .subheadline : .caption)
                    .fontWeight(isTotal ? .semibold : .medium)
                
                Spacer()
                
                Text("\(amount) sats")
                    .font(isTotal ? .subheadline : .caption)
                    .fontWeight(isTotal ? .semibold : .medium)
                    .foregroundColor(isTotal ? .primary : .secondary)
            }
            
            if !description.isEmpty {
                HStack {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FeeComparisonView(
            lightningFeeSats: 50,
            paymentAmountSats: 100000
        )
        
        FeeEducationView()
        
        // Mock PrepareSendResponse for preview
        // FeeBreakdownView(preparedPayment: mockPrepareSendResponse)
    }
    .padding()
}
