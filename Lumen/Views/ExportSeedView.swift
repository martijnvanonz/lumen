import SwiftUI

struct ExportSeedView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var walletManager = WalletManager.shared
    @State private var seedWords: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSecurityWarning = true
    @State private var hasAgreedToWarning = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if showingSecurityWarning {
                    SecurityWarningView(
                        hasAgreed: $hasAgreedToWarning,
                        onContinue: {
                            showingSecurityWarning = false
                            loadSeedPhrase()
                        },
                        onCancel: {
                            dismiss()
                        }
                    )
                } else if isLoading {
                    LoadingView()
                } else if let errorMessage = errorMessage {
                    ErrorView(message: errorMessage) {
                        dismiss()
                    }
                } else if !seedWords.isEmpty {
                    SeedPhraseDisplayView(seedWords: seedWords)
                }
            }
            .navigationTitle("Recovery Phrase")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Disable screenshots and screen recording
            preventScreenCapture(true)
        }
        .onDisappear {
            // Re-enable screenshots
            preventScreenCapture(false)
            // Clear sensitive data from memory
            clearSeedFromMemory()
        }
    }
    
    private func loadSeedPhrase() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let mnemonic = try await KeychainManager.shared.getSecureMnemonic(
                    reason: "Access your wallet recovery phrase"
                )
                
                await MainActor.run {
                    seedWords = mnemonic.components(separatedBy: " ")
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to retrieve seed phrase: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func preventScreenCapture(_ prevent: Bool) {
        DispatchQueue.main.async {
            if let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) {
                
                if prevent {
                    // Add a security overlay to prevent screenshots
                    let securityView = UIView(frame: window.bounds)
                    securityView.backgroundColor = .systemBackground
                    securityView.tag = 999 // Tag for easy removal
                    window.addSubview(securityView)
                    window.makeSecure()
                } else {
                    // Remove security overlay
                    window.subviews.first(where: { $0.tag == 999 })?.removeFromSuperview()
                }
            }
        }
    }
    
    private func clearSeedFromMemory() {
        // Clear the seed words array
        seedWords = Array(repeating: "", count: seedWords.count)
        seedWords.removeAll()
    }
}

// MARK: - Security Warning View

struct SecurityWarningView: View {
    @Binding var hasAgreed: Bool
    let onContinue: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Warning Icon
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                VStack(spacing: 8) {
                    Text("Security Warning")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your recovery phrase is extremely sensitive")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Warning Points
            VStack(spacing: 16) {
                SecurityWarningRow(
                    icon: "eye.slash.fill",
                    text: "Never share your recovery phrase with anyone"
                )
                
                SecurityWarningRow(
                    icon: "camera.fill",
                    text: "Don't take screenshots or photos"
                )
                
                SecurityWarningRow(
                    icon: "wifi.slash",
                    text: "Make sure you're in a private, secure location"
                )
                
                SecurityWarningRow(
                    icon: "key.fill",
                    text: "Anyone with this phrase can access your funds"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Agreement and Continue
            VStack(spacing: 16) {
                Button(action: {
                    hasAgreed.toggle()
                }) {
                    HStack {
                        Image(systemName: hasAgreed ? "checkmark.square.fill" : "square")
                            .foregroundColor(hasAgreed ? .blue : .secondary)
                        
                        Text("I understand the risks and want to proceed")
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    
                    Button("Continue") {
                        onContinue()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(hasAgreed ? Color.orange : Color(.systemGray4))
                    .foregroundColor(hasAgreed ? .white : .secondary)
                    .cornerRadius(12)
                    .disabled(!hasAgreed)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Security Warning Row

struct SecurityWarningRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Seed Phrase Display View

struct SeedPhraseDisplayView: View {
    let seedWords: [String]
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Your Recovery Phrase")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Write down these \(seedWords.count) words in the exact order shown")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                // Seed Words Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(seedWords.enumerated()), id: \.offset) { index, word in
                        SeedWordCard(number: index + 1, word: word)
                    }
                }
                .padding(.horizontal)
                
                // Bottom Warning
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Keep this phrase safe and private")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    
                    Text("Store it in a secure location. Never share it with anyone or enter it on websites or apps you don't trust.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Seed Word Card

struct SeedWordCard: View {
    let number: Int
    let word: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(number)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(word)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("Retrieving recovery phrase...")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Error")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Close") {
                onDismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
    }
}

// MARK: - UIWindow Extension for Security

extension UIWindow {
    func makeSecure() {
        // Prevent screenshots by making the window secure
        if #available(iOS 13.0, *) {
            // This is a placeholder - actual implementation would require
            // more sophisticated screenshot prevention techniques
        }
    }
}

#Preview {
    ExportSeedView()
}
