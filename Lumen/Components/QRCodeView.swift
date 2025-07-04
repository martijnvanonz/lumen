import SwiftUI
import CoreImage

/// A reusable QR code view component for displaying Lightning invoices and other data
struct QRCodeView: View {
    let data: String
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color

    init(
        data: String,
        size: CGFloat = 200,
        backgroundColor: Color = .white,
        foregroundColor: Color = .black
    ) {
        self.data = data
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        if let qrImage = generateQRCode(from: data) {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .cornerRadius(12)
        } else {
            // Fallback view if QR generation fails
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: size, height: size)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)

                        Text("QR Code\nUnavailable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                )
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()

        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }

        // Scale up the QR code for better quality
        let scaleX = size / outputImage.extent.size.width
        let scaleY = size / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Preview

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            QRCodeView(data: "lnbc1500n1pn2s39kpp5...")

            QRCodeView(
                data: "bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
                size: 150
            )
        }
        .padding()
    }
}
