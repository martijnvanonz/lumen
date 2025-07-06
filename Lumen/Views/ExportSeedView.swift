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
                            print("🔍 SecurityWarning: Continue pressed")
                            showingSecurityWarning = false
                            loadSeedPhrase()
                        },
                        onCancel: {
                            print("🔍 SecurityWarning: Cancel pressed")
                            dismiss()
                        }
                    )
                } else if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Retrieving recovery phrase...")
                            .foregroundColor(.secondary)
                    }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("Error")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Close") {
                            dismiss()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding()
                } else if !seedWords.isEmpty {
                    SeedPhraseDisplayView(seedWords: seedWords)
                } else {
                    VStack {
                        Text("Debug: Unexpected state")
                            .foregroundColor(.red)
                        Text("showingSecurityWarning: \(showingSecurityWarning)")
                        Text("isLoading: \(isLoading)")
                        Text("errorMessage: \(errorMessage ?? "nil")")
                        Text("seedWords.count: \(seedWords.count)")
                    }
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
            print("🔍 ExportSeedView appeared")
            print("🔍 Initial state: showingSecurityWarning=\(showingSecurityWarning), isLoading=\(isLoading), errorMessage=\(errorMessage ?? "nil"), seedWords.count=\(seedWords.count)")
        }
        .onDisappear {
            clearSeedFromMemory()
        }
    }
    
    private func loadSeedPhrase() {
        print("🔍 loadSeedPhrase() called")
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🔍 Requesting mnemonic from keychain...")
                let mnemonic = try await KeychainManager.shared.getSecureMnemonic(
                    reason: "Access your wallet recovery phrase"
                )
                print("🔍 Successfully retrieved mnemonic with \(mnemonic.components(separatedBy: " ").count) words")
                
                await MainActor.run {
                    seedWords = mnemonic.components(separatedBy: " ")
                    isLoading = false
                    print("🔍 Updated UI with seed words: \(seedWords.count) words")
                }
            } catch {
                print("🔍 Failed to retrieve mnemonic: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to retrieve seed phrase: \(error.localizedDescription)"
                    isLoading = false
                    print("🔍 Updated UI with error: \(errorMessage ?? "unknown")")
                }
            }
        }
    }
    
    private func clearSeedFromMemory() {
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
        VStack(spacing: 20) {
            Text("🔒 Security Warning")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            Text("Your recovery phrase is extremely sensitive")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(spacing: 12) {
                Text("⚠️ Never share your recovery phrase with anyone")
                Text("📷 Don't take screenshots or photos")
                Text("🔒 Make sure you're in a private location")
                Text("💰 Anyone with this phrase can access your funds")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Button(action: {
                hasAgreed.toggle()
            }) {
                HStack {
                    Image(systemName: hasAgreed ? "checkmark.square.fill" : "square")
                        .foregroundColor(hasAgreed ? .blue : .secondary)
                    
                    Text("I understand the risks")
                        .foregroundColor(.primary)
                }
            }
            .padding()
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    onCancel()
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                
                Button("Continue") {
                    onContinue()
                }
                .padding()
                .background(hasAgreed ? Color.orange : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(!hasAgreed)
            }
        }
        .padding()
        .onAppear {
            print("🔍 SecurityWarningView appeared and rendered")
        }
    }
}

// MARK: - Seed Phrase Display View

struct SeedPhraseDisplayView: View {
    let seedWords: [String]
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Your Recovery Phrase")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Write down these \(seedWords.count) words in the exact order shown")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(seedWords.enumerated()), id: \.offset) { index, word in
                        VStack(spacing: 6) {
                            Text("\(index + 1)")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(word)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8) // Allow text to scale down if needed
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 10)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                    }
                }
                .padding(.horizontal)
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Keep this phrase safe and private")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    
                    Text("Store it in a secure location. Never share it with anyone.")
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

#Preview {
    ExportSeedView()
}
