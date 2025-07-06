import SwiftUI

struct ImportSeedView: View {
    @ObservedObject var onboardingState: OnboardingState
    @StateObject private var walletManager = WalletManager.shared
    
    @State private var seedWords: [String] = Array(repeating: "", count: 24)
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var validationErrors: [Int: String] = [:]
    @State private var showingPasteAlert = false
    @State private var pasteboardContent = ""
    @State private var expectedWordCount = 24
    @State private var showingWordCountPicker = false
    
    private let validWordCounts = [12, 24]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                VStack(spacing: 8) {
                    Text(L("import_wallet_title"))
                        .font(.title)
                        .fontWeight(.bold)

                    Text(String(format: L("enter_recovery_phrase"), expectedWordCount))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Word Count Selector
            HStack {
                Text(L("word_count"))
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingWordCountPicker = true
                }) {
                    HStack {
                        Text("\(expectedWordCount) words")
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Paste Button
                    Button(action: {
                        checkPasteboard()
                    }) {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                            Text(L("paste_seed_phrase"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Seed Words Grid
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(0..<expectedWordCount, id: \.self) { index in
                            SeedWordInputField(
                                index: index,
                                word: $seedWords[index],
                                hasError: validationErrors[index] != nil,
                                onWordChanged: { validateWord(at: index) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Import Button
                    Button(action: {
                        importWallet()
                    }) {
                        HStack {
                            if isImporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            
                            Text(isImporting ? L("importing_wallet") : L("import_wallet_button"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canImport ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canImport || isImporting)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            adjustSeedWordsArray()
        }
        .alert(L("paste_seed_phrase"), isPresented: $showingPasteAlert) {
            Button(L("cancel"), role: .cancel) { }
            Button("Paste") {
                pasteSeedPhrase()
            }
        } message: {
            Text(String(format: L("paste_confirmation"), pasteboardContent.components(separatedBy: " ").count))
        }
        .actionSheet(isPresented: $showingWordCountPicker) {
            ActionSheet(
                title: Text("Select Word Count"),
                message: Text("How many words does your seed phrase have?"),
                buttons: validWordCounts.map { count in
                    .default(Text("\(count) words")) {
                        expectedWordCount = count
                        adjustSeedWordsArray()
                        clearValidationErrors()
                    }
                } + [.cancel()]
            )
        }
    }
    
    private var gridColumns: [GridItem] {
        let columnCount = expectedWordCount == 12 ? 3 : 3 // Use 3 columns for both 12 and 24 words for better spacing
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)
    }
    
    private var canImport: Bool {
        let filledWords = seedWords.prefix(expectedWordCount).filter { !$0.isEmpty }
        return filledWords.count == expectedWordCount && validationErrors.isEmpty && !isImporting
    }
    
    private func adjustSeedWordsArray() {
        if seedWords.count != expectedWordCount {
            seedWords = Array(repeating: "", count: expectedWordCount)
        }
    }
    
    private func validateWord(at index: Int) {
        let word = seedWords[index].trimmingCharacters(in: .whitespacesAndNewlines)
        
        if word.isEmpty {
            validationErrors.removeValue(forKey: index)
        } else if !SeedPhraseValidator.isValidBIP39Word(word) {
            validationErrors[index] = "Invalid word"
        } else {
            validationErrors.removeValue(forKey: index)
        }
        
        // Clear general error message when user starts typing
        if errorMessage != nil {
            errorMessage = nil
        }
    }
    
    private func clearValidationErrors() {
        validationErrors.removeAll()
        errorMessage = nil
    }
    
    private func checkPasteboard() {
        if let clipboardContent = UIPasteboard.general.string {
            let words = SeedPhraseValidator.extractWords(from: clipboardContent)
            if validWordCounts.contains(words.count) {
                pasteboardContent = clipboardContent
                showingPasteAlert = true
            }
        }
    }
    
    private func pasteSeedPhrase() {
        let words = SeedPhraseValidator.extractWords(from: pasteboardContent)
        
        if validWordCounts.contains(words.count) {
            expectedWordCount = words.count
            adjustSeedWordsArray()
            
            for (index, word) in words.enumerated() {
                if index < seedWords.count {
                    seedWords[index] = word
                }
            }
            
            // Validate all pasted words
            for index in 0..<min(words.count, seedWords.count) {
                validateWord(at: index)
            }
        }
    }
    
    private func importWallet() {
        isImporting = true
        errorMessage = nil
        
        let currentWords = Array(seedWords.prefix(expectedWordCount))
        let seedPhrase = currentWords.joined(separator: " ")
        
        // Final validation
        let validation = SeedPhraseValidator.validateSeedPhrase(seedPhrase)
        guard validation.isValid else {
            errorMessage = validation.errorMessage
            isImporting = false
            return
        }
        
        Task {
            do {
                try await walletManager.importWallet(mnemonic: seedPhrase)
                
                await MainActor.run {
                    isImporting = false
                    // Mark import as completed and continue to currency selection
                    onboardingState.isImportFlow = false
                    onboardingState.currentStep = .currencySelection
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to import wallet: \(error.localizedDescription)"
                    isImporting = false
                }
            }
        }
    }
}

// MARK: - Seed Word Input Field

struct SeedWordInputField: View {
    let index: Int
    @Binding var word: String
    let hasError: Bool
    let onWordChanged: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(index + 1)")
                .font(.caption2)
                .foregroundColor(.secondary)

            TextField("", text: $word)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.none)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .font(.system(size: 14, weight: .medium))
                .frame(minHeight: 44) // Larger touch target
                .multilineTextAlignment(.center)
                .onChange(of: word) { _, newValue in
                    // Clean the input
                    word = newValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    onWordChanged()
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(hasError ? Color.red : Color.clear, lineWidth: 2)
                )
        }
        .frame(minWidth: 80) // Ensure minimum width for longer words
    }
}

#Preview {
    ImportSeedView(onboardingState: OnboardingState())
}
