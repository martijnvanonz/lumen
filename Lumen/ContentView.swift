import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "lightbulb.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Lumen")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Bright, simple payments.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
