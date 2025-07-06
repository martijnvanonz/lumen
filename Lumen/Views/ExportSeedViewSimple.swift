import SwiftUI

struct ExportSeedViewSimple: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Seed View Test")
                    .font(.title)
                
                Text("This is a simple test to see if the view renders")
                    .foregroundColor(.secondary)
                
                Button("Close") {
                    dismiss()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Test Export")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ExportSeedViewSimple()
}
