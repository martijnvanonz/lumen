import SwiftUI

/// Interactive wave configuration view for fine-tuning wave parameters
/// Use this to experiment with wave settings and find the perfect values
struct WaveConfigurationView: View {
    
    // MARK: - Wave Parameters

    @State private var amplitude: Double = 150.0
    @State private var frequency: Double = 0.4
    @State private var waveHeight: Double = 200.0
    @State private var wavePosition: Double = 0.3 // 0.0 = top, 1.0 = bottom
    @State private var animated: Bool = true
    @State private var phase: Double = 0.0
    
    // MARK: - UI State
    
    @State private var showCode: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Live Preview
                previewSection
                
                // Controls
                ScrollView {
                    VStack(spacing: 20) {
                        controlsSection
                        codeSection
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Wave Configurator")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(spacing: 0) {
            // Gradient background using FixedGradientContainer
            ZStack {
                FixedGradientContainer {
                    Color.clear
                }
            }
            .frame(height: 300)
            .clipped()
            
            // Custom wave with current parameters
            CustomWaveShape(
                amplitude: CGFloat(amplitude),
                frequency: CGFloat(frequency),
                phase: CGFloat(phase),
                position: CGFloat(wavePosition)
            )
            .fill(Color.white)
            .frame(height: CGFloat(waveHeight))
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 8,
                x: 0,
                y: 2
            )
            .onAppear {
                if animated {
                    startAnimation()
                }
            }
            .onChange(of: animated) { _, newValue in
                if newValue {
                    startAnimation()
                } else {
                    phase = 0.0
                }
            }
            
            // White content area
            Color.white
                .frame(height: 200)
                .overlay(
                    VStack {
                        Text("Transaction History")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Wave transition preview")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
        }
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: 16) {
            GroupBox("Wave Parameters") {
                VStack(spacing: 12) {
                    parameterSlider(
                        title: "Amplitude",
                        value: $amplitude,
                        range: 5...50,
                        description: "Wave height/depth"
                    )
                    
                    parameterSlider(
                        title: "Frequency",
                        value: $frequency,
                        range: 0.5...5.0,
                        description: "Number of waves across width"
                    )
                    
                    parameterSlider(
                        title: "Wave Height",
                        value: $waveHeight,
                        range: 30...120,
                        description: "Total height of wave area"
                    )
                    
                    parameterSlider(
                        title: "Position",
                        value: $wavePosition,
                        range: 0.3...0.9,
                        description: "Wave vertical position (0.3=top, 0.9=bottom)"
                    )
                }
            }
            
            GroupBox("Animation") {
                Toggle("Animate Wave", isOn: $animated)
                    .toggleStyle(SwitchToggleStyle())
            }
            
            GroupBox("Actions") {
                VStack(spacing: 8) {
                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Show Generated Code") {
                        showCode.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    // MARK: - Code Section
    
    private var codeSection: some View {
        Group {
            if showCode {
                GroupBox("Generated Code") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Copy these values:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Amplitude: \(amplitude, specifier: "%.1f")")
                            Text("Frequency: \(frequency, specifier: "%.1f")")
                            Text("Wave Height: \(waveHeight, specifier: "%.0f")")
                            Text("Position: \(wavePosition, specifier: "%.1f")")
                        }
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        Button("Copy Values") {
                            let values = """
                            Amplitude: \(amplitude)
                            Frequency: \(frequency)
                            Wave Height: \(waveHeight)
                            Position: \(wavePosition)
                            """
                            UIPasteboard.general.string = values
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func parameterSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        description: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(value.wrappedValue, specifier: "%.1f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: value, in: range)
                .accentColor(.blue)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    private func resetToDefaults() {
        amplitude = 15.0
        frequency = 2.0
        waveHeight = 60.0
        wavePosition = 0.7
        animated = false
        phase = 0.0
    }
    
    private func startAnimation() {
        withAnimation(
            Animation.linear(duration: 3)
                .repeatForever(autoreverses: false)
        ) {
            phase = 2 * .pi
        }
    }
}

// MARK: - Custom Wave Shape

/// Custom wave shape that allows position adjustment
private struct CustomWaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    var position: CGFloat // 0.0 = top, 1.0 = bottom

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Start from top-left corner
        path.move(to: CGPoint(x: 0, y: 0))

        // Create smooth bezier curve for more natural wave shape
        let baseY = height * position
        let controlPointOffset = width * 0.25 // Control points at 25% and 75% of width

        // First control point (left side of wave)
        let cp1X = width * 0.25
        let cp1Y = baseY + amplitude * 0.2 + sin(phase) * amplitude * 0.1

        // Second control point (right side of wave)
        let cp2X = width * 0.75
        let cp2Y = baseY - amplitude * 0.8 + sin(phase + .pi) * amplitude * 0.2

        // End point
        let endX = width
        let endY = baseY - amplitude * 0.9 + sin(frequency * 2 * .pi + phase) * amplitude * 0.1

        // Create smooth bezier curve
        path.addCurve(
            to: CGPoint(x: endX, y: endY),
            control1: CGPoint(x: cp1X, y: cp1Y),
            control2: CGPoint(x: cp2X, y: cp2Y)
        )

        // Complete the shape
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview {
    WaveConfigurationView()
}
