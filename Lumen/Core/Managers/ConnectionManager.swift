import Foundation
import BreezSDKLiquid
import web3swift

/// Manages wallet connection lifecycle and state
/// Extracted from WalletManager to provide focused connection management
@MainActor
class ConnectionManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var connectionError: String?
    
    // MARK: - Dependencies
    
    private let walletService: WalletServiceProtocol
    private let repository: DefaultWalletRepository
    private let eventHandler = PaymentEventHandler.shared
    private let errorHandler = ErrorHandler.shared
    private let networkMonitor = NetworkMonitor.shared
    
    // MARK: - Private Properties
    
    private var isInitializing = false
    
    // MARK: - Initialization
    
    init(walletService: WalletServiceProtocol, repository: DefaultWalletRepository) {
        self.walletService = walletService
        self.repository = repository
    }
    
    // MARK: - Connection Management
    
    /// Initialize wallet from existing mnemonic or create new one
    func initializeWallet() async throws {
        guard !isInitializing else {
            print("⚠️ Wallet initialization already in progress")
            return
        }
        
        isInitializing = true
        defer { isInitializing = false }
        
        isLoading = true
        connectionError = nil
        
        do {
            let mnemonic: String
            
            // Check if mnemonic exists using repository
            if repository.mnemonicExists() {
                // Retrieve existing mnemonic
                mnemonic = try await retrieveExistingMnemonic()
            } else {
                // Generate new mnemonic and store it securely
                mnemonic = try await generateAndStoreMnemonic()
            }
            
            // Connect to wallet with event handling
            try await connectToWallet(mnemonic: mnemonic)
            
            isConnected = walletService.isConnected
            isLoading = false
            
            print("✅ Wallet initialized successfully")
            
        } catch {
            isLoading = false
            connectionError = error.localizedDescription
            errorHandler.logError(.wallet(.connectionFailed), context: "Wallet initialization")
            throw error
        }
    }
    
    /// Import wallet from existing mnemonic phrase
    func importWallet(mnemonic: String) async throws {
        isLoading = true
        connectionError = nil
        
        do {
            // Validate the mnemonic first
            let normalizedMnemonic = SeedPhraseValidator.normalizeSeedPhrase(mnemonic)
            let validation = SeedPhraseValidator.validateSeedPhrase(normalizedMnemonic)
            
            guard validation.isValid else {
                throw WalletError.invalidMnemonic(validation.errorMessage)
            }
            
            // Store the imported mnemonic using repository
            try repository.storeMnemonic(normalizedMnemonic)
            
            // Clear any previously selected currency for imported wallet
            CurrencyManager.shared.clearSelectedCurrency()
            
            // Connect to wallet with event handling
            try await connectToWallet(mnemonic: normalizedMnemonic)
            
            isConnected = walletService.isConnected
            isLoading = false
            
            print("✅ Wallet imported successfully")
            
        } catch {
            isLoading = false
            connectionError = error.localizedDescription
            errorHandler.logError(.wallet(.importFailed), context: "Wallet import")
            throw error
        }
    }
    
    /// Initialize wallet from secure cache if available
    func initializeFromCache() async -> Bool {
        guard repository.isCacheValid() else {
            print("⚠️ No valid cache available")
            return false
        }
        
        do {
            let cachedSeed = try repository.retrieveCachedSeed()
            
            isLoading = true
            connectionError = nil
            
            // Connect to wallet with cached mnemonic and event handling
            try await connectToWallet(mnemonic: cachedSeed)
            
            isConnected = walletService.isConnected
            isLoading = false
            
            print("✅ Wallet initialized from secure cache")
            return true
            
        } catch {
            print("❌ Failed to initialize from cache: \(error)")
            return false
        }
    }
    
    /// Disconnect from the wallet service
    func disconnect() async {
        guard walletService.isConnected else { return }
        
        do {
            try await walletService.disconnect()
            isConnected = false
            // Stop currency manager rate updates
            CurrencyManager.shared.stopRateUpdates()
            print("✅ Wallet disconnected successfully")
        } catch {
            connectionError = error.localizedDescription
            print("❌ Failed to disconnect: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Generates a new mnemonic and stores it securely in iCloud Keychain
    private func generateAndStoreMnemonic() async throws -> String {
        // Generate mnemonic using Breez SDK
        let mnemonic = try generateBIP39Mnemonic()
        
        // Store mnemonic using repository
        try repository.storeMnemonic(mnemonic)
        
        // Clear any previously selected currency for new wallet
        CurrencyManager.shared.clearSelectedCurrency()
        
        print("✅ Generated secure BIP39 mnemonic with \(mnemonic.split(separator: " ").count * 11) bits of entropy")
        return mnemonic
    }
    
    /// Retrieves existing mnemonic with secure authentication and caching
    private func retrieveExistingMnemonic() async throws -> String {
        print("🔐 ConnectionManager: Retrieving existing mnemonic with biometric auth")
        // Use repository for secure mnemonic retrieval with biometric authentication and caching
        let mnemonic = try await repository.getSecureMnemonic(reason: "Unlock your Lumen wallet")
        print("✅ ConnectionManager: Successfully retrieved and cached mnemonic")
        return mnemonic
    }
    
    /// Connects to the wallet using services and sets up event handling
    private func connectToWallet(mnemonic: String) async throws {
        print("🔗 connectToWallet called from async context")
        
        eventHandler.updateConnectionStatus(.connecting)
        
        do {
            // Connect using wallet service
            try await walletService.connect(mnemonic: mnemonic)
            
            // Set up event handling (if the wallet service provides SDK access)
            await setupEventHandling()
            
            eventHandler.updateConnectionStatus(.syncing)
            
            eventHandler.updateConnectionStatus(.connected)
        } catch {
            eventHandler.updateConnectionStatus(.disconnected)
            
            // Log error and re-throw
            errorHandler.logError(.sdk(.connectionFailed), context: "SDK connection")
            throw error
        }
    }
    
    /// Sets up event handling for the wallet
    private func setupEventHandling() async {
        // This would set up SDK event listeners
        // For now, we'll keep it simple since the service layer handles most of this
        print("🔧 Setting up event handling")
    }
}

// MARK: - Helper Functions

/// Generate a BIP39 mnemonic phrase using web3swift
private func generateBIP39Mnemonic() throws -> String {
    // Use web3swift for BIP39 generation as per user preference
    guard let mnemonic = try? BIP39.generateMnemonics(bitsOfEntropy: 256) else {
        throw WalletError.mnemonicGenerationFailed
    }
    return mnemonic
}
