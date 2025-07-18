import SwiftUI

/// A reusable glassmorphism card component with consistent styling
/// Features: white background with 40% opacity, corner radius 35, drop shadow, background blur
struct GlassmorphismCard<Content: View>: View {
    
    // MARK: - Properties
    
    let content: Content
    
    // MARK: - Customization Options
    
    private var padding: EdgeInsets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
    private var cornerRadius: CGFloat = 35
    private var backgroundOpacity: Double = 0.4
    private var shadowColor: Color = Color.white.opacity(0.40)
    private var shadowRadius: CGFloat = 20
    private var shadowOffset: CGSize = CGSize(width: 0, height: 4)
    private var backgroundBlur: CGFloat = 4
    
    // MARK: - Initializer
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(backgroundOpacity))
                    .background(
                        // Background blur effect
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                            .blur(radius: backgroundBlur)
                    )
                    .shadow(
                        color: shadowColor,
                        radius: shadowRadius,
                        x: shadowOffset.width,
                        y: shadowOffset.height
                    )
            )
    }
}

// MARK: - Modifier Extensions

extension GlassmorphismCard {
    
    /// Customize padding
    func padding(_ edges: Edge.Set = .all, _ length: CGFloat) -> GlassmorphismCard {
        var card = self
        switch edges {
        case .all:
            card.padding = EdgeInsets(top: length, leading: length, bottom: length, trailing: length)
        case .horizontal:
            card.padding = EdgeInsets(top: card.padding.top, leading: length, bottom: card.padding.bottom, trailing: length)
        case .vertical:
            card.padding = EdgeInsets(top: length, leading: card.padding.leading, bottom: length, trailing: card.padding.trailing)
        case .top:
            card.padding = EdgeInsets(top: length, leading: card.padding.leading, bottom: card.padding.bottom, trailing: card.padding.trailing)
        case .bottom:
            card.padding = EdgeInsets(top: card.padding.top, leading: card.padding.leading, bottom: length, trailing: card.padding.trailing)
        case .leading:
            card.padding = EdgeInsets(top: card.padding.top, leading: length, bottom: card.padding.bottom, trailing: card.padding.trailing)
        case .trailing:
            card.padding = EdgeInsets(top: card.padding.top, leading: card.padding.leading, bottom: card.padding.bottom, trailing: length)
        default:
            break
        }
        return card
    }
    
    /// Customize padding with EdgeInsets
    func padding(_ insets: EdgeInsets) -> GlassmorphismCard {
        var card = self
        card.padding = insets
        return card
    }
    
    /// Customize corner radius
    func cornerRadius(_ radius: CGFloat) -> GlassmorphismCard {
        var card = self
        card.cornerRadius = radius
        return card
    }
    
    /// Customize background opacity
    func backgroundOpacity(_ opacity: Double) -> GlassmorphismCard {
        var card = self
        card.backgroundOpacity = opacity
        return card
    }
    
    /// Customize shadow
    func shadow(
        color: Color = Color.black.opacity(0.25),
        radius: CGFloat = 20,
        x: CGFloat = 0,
        y: CGFloat = 4
    ) -> GlassmorphismCard {
        var card = self
        card.shadowColor = color
        card.shadowRadius = radius
        card.shadowOffset = CGSize(width: x, height: y)
        return card
    }
    
    /// Customize background blur
    func backgroundBlur(_ blur: CGFloat) -> GlassmorphismCard {
        var card = self
        card.backgroundBlur = blur
        return card
    }
}

// MARK: - Convenience Initializers

extension GlassmorphismCard {

    /// Standard card with default glassmorphism styling
    static func standard<T: View>(@ViewBuilder content: @escaping () -> T) -> GlassmorphismCard<T> {
        GlassmorphismCard<T>(content: content)
    }

    /// Compact card with reduced padding
    static func compact<T: View>(@ViewBuilder content: @escaping () -> T) -> GlassmorphismCard<T> {
        GlassmorphismCard<T>(content: content)
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
    }

    /// Large card with increased padding
    static func large<T: View>(@ViewBuilder content: @escaping () -> T) -> GlassmorphismCard<T> {
        GlassmorphismCard<T>(content: content)
            .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Gradient background to show glassmorphism effect
        LinearGradient(
            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Standard card
            GlassmorphismCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Balance")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("1,250,000 sats")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("≈ $312.50")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Compact card
            GlassmorphismCard {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text("5 places near you")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            
            // Large card
            GlassmorphismCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Activity")
                        .font(.headline)
                    
                    ForEach(0..<3) { _ in
                        HStack {
                            Circle()
                                .fill(.green.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundColor(.green)
                                )
                            
                            VStack(alignment: .leading) {
                                Text("Received")
                                    .font(.subheadline)
                                Text("2 hours ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("+50,000 sats")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        }
        .padding()
    }
}
