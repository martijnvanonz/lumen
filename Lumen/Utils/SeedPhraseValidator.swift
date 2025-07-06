import Foundation
import web3swift

/// Utility class for validating BIP39 seed phrases
class SeedPhraseValidator {
    
    // MARK: - Validation Results
    
    enum ValidationResult {
        case valid
        case invalidLength(expected: [Int], actual: Int)
        case invalidWord(word: String, position: Int)
        case invalidChecksum
        case empty
        
        var isValid: Bool {
            switch self {
            case .valid:
                return true
            default:
                return false
            }
        }
        
        var errorMessage: String {
            switch self {
            case .valid:
                return ""
            case .invalidLength(let expected, let actual):
                let expectedStr = expected.map(String.init).joined(separator: ", ")
                return "Invalid length: expected \(expectedStr) words, got \(actual) words"
            case .invalidWord(let word, let position):
                return "Invalid word '\(word)' at position \(position)"
            case .invalidChecksum:
                return "Invalid seed phrase: checksum verification failed"
            case .empty:
                return "Please enter your seed phrase"
            }
        }
    }
    
    // MARK: - Validation Methods
    
    /// Validates a complete seed phrase string
    /// - Parameter seedPhrase: The seed phrase to validate (space-separated words)
    /// - Returns: ValidationResult indicating success or specific error
    static func validateSeedPhrase(_ seedPhrase: String) -> ValidationResult {
        let trimmedPhrase = seedPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if empty
        guard !trimmedPhrase.isEmpty else {
            return .empty
        }
        
        // Split into words and clean them
        let words = trimmedPhrase.components(separatedBy: .whitespacesAndNewlines)
            .compactMap { word in
                let cleaned = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return cleaned.isEmpty ? nil : cleaned
            }
        
        return validateWords(words)
    }
    
    /// Validates an array of seed words
    /// - Parameter words: Array of seed words
    /// - Returns: ValidationResult indicating success or specific error
    static func validateWords(_ words: [String]) -> ValidationResult {
        // Check length - BIP39 supports 12, 15, 18, 21, 24 words
        let validLengths = [12, 15, 18, 21, 24]
        guard validLengths.contains(words.count) else {
            return .invalidLength(expected: validLengths, actual: words.count)
        }
        
        // Check each word against BIP39 wordlist
        let bip39Words = BIP39Language.english.words
        for (index, word) in words.enumerated() {
            guard bip39Words.contains(word.lowercased()) else {
                return .invalidWord(word: word, position: index + 1)
            }
        }
        
        // Validate checksum using Web3Swift BIP39
        let seedPhrase = words.joined(separator: " ")
        guard BIP39.mnemonicsToEntropy(seedPhrase, language: .english) != nil else {
            return .invalidChecksum
        }
        
        return .valid
    }
    
    /// Validates a single word against the BIP39 wordlist
    /// - Parameter word: The word to validate
    /// - Returns: true if the word is in the BIP39 wordlist
    static func isValidBIP39Word(_ word: String) -> Bool {
        let cleanedWord = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return BIP39Language.english.words.contains(cleanedWord)
    }
    
    /// Gets suggestions for a partial word input
    /// - Parameter partial: Partial word input
    /// - Returns: Array of suggested words from BIP39 wordlist
    static func getSuggestions(for partial: String, limit: Int = 5) -> [String] {
        let cleanedPartial = partial.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !cleanedPartial.isEmpty else {
            return []
        }
        
        return BIP39Language.english.words
            .filter { $0.hasPrefix(cleanedPartial) }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Normalizes a seed phrase by cleaning whitespace and converting to lowercase
    /// - Parameter seedPhrase: Raw seed phrase input
    /// - Returns: Normalized seed phrase string
    static func normalizeSeedPhrase(_ seedPhrase: String) -> String {
        return seedPhrase
            .components(separatedBy: .whitespacesAndNewlines)
            .compactMap { word in
                let cleaned = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return cleaned.isEmpty ? nil : cleaned
            }
            .joined(separator: " ")
    }
    
    /// Extracts individual words from a seed phrase string
    /// - Parameter seedPhrase: The seed phrase string
    /// - Returns: Array of individual words
    static func extractWords(from seedPhrase: String) -> [String] {
        return seedPhrase
            .components(separatedBy: .whitespacesAndNewlines)
            .compactMap { word in
                let cleaned = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return cleaned.isEmpty ? nil : cleaned
            }
    }
    
    /// Validates that a seed phrase can be used to generate a valid wallet
    /// - Parameter seedPhrase: The seed phrase to validate
    /// - Returns: true if the seed phrase can generate a valid seed
    static func canGenerateValidSeed(_ seedPhrase: String) -> Bool {
        let normalizedPhrase = normalizeSeedPhrase(seedPhrase)
        return BIP39.seedFromMmemonics(normalizedPhrase, password: "", language: .english) != nil
    }
}

// MARK: - Extensions

extension String {
    /// Checks if this string is a valid BIP39 seed phrase
    var isValidSeedPhrase: Bool {
        return SeedPhraseValidator.validateSeedPhrase(self).isValid
    }
    
    /// Gets the validation result for this seed phrase
    var seedPhraseValidation: SeedPhraseValidator.ValidationResult {
        return SeedPhraseValidator.validateSeedPhrase(self)
    }
}

extension Array where Element == String {
    /// Checks if this array of words forms a valid BIP39 seed phrase
    var isValidSeedWords: Bool {
        return SeedPhraseValidator.validateWords(self).isValid
    }
    
    /// Gets the validation result for this array of seed words
    var seedWordsValidation: SeedPhraseValidator.ValidationResult {
        return SeedPhraseValidator.validateWords(self)
    }
}
