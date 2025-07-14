import Foundation
import BreezSDKLiquid

/// Manages wallet state and lifecycle
/// Extracted from WalletManager to provide focused state management
@MainActor
class WalletStateManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var hasWallet = false
    @Published var isLoggedIn = false
    @Published var walletInfo: GetInfoResponse?
    @Published var isLoadingWalletInfo = false
    @Published var walletInfoError: String?
    
    // MARK: - Dependencies
    
    private let repository: DefaultWalletRepository
    private let walletService: WalletServiceProtocol
    private let errorHandler = ErrorHandler.shared
    
    // MARK: - Initialization
    
    init(repository: DefaultWalletRepository, walletService: WalletServiceProtocol) {
        self.repository = repository
        self.walletService = walletService
        
        // Initialize state from repository
        self.hasWallet = repository.hasWallet
        self.isLoggedIn = repository.isLoggedIn
    }
    
    // MARK: - State Management
    
    /// Update wallet existence state
    func setHasWallet(_ value: Bool) {
        hasWallet = value
        repository.hasWallet = value
        print("📱 Wallet existence state updated: \(value)")
    }
    
    /// Update login state
    func setIsLoggedIn(_ value: Bool) {
        isLoggedIn = value
        repository.isLoggedIn = value
        print("🔐 Login state updated: \(value)")
    }
    
    /// Check if wallet exists in keychain
    func checkWalletExists() -> Bool {
        let exists = repository.mnemonicExists()
        setHasWallet(exists)
        return exists
    }
    
    /// Update wallet info from service
    func updateWalletInfo() async {
        guard walletService.isConnected else {
            print("⚠️ Cannot update wallet info - wallet not connected")
            return
        }
        
        isLoadingWalletInfo = true
        walletInfoError = nil
        
        do {
            walletInfo = try await walletService.getWalletInfo()
            print("ℹ️ Wallet info updated successfully")
        } catch {
            walletInfoError = error.localizedDescription
            errorHandler.logError(.wallet(.syncFailed), context: "Wallet info update")
            print("❌ Failed to update wallet info: \(error)")
        }
        
        isLoadingWalletInfo = false
    }
    
    /// Get wallet public key (equivalent to node ID)
    func getNodeId() -> String? {
        return walletInfo?.walletInfo.pubkey
    }

    /// Get wallet balance from info
    func getBalanceFromInfo() -> UInt64? {
        return walletInfo?.walletInfo.balanceSat
    }
    
    /// Check if wallet is ready for operations
    func isWalletReady() -> Bool {
        return hasWallet && isLoggedIn && walletService.isConnected
    }
    
    /// Reset wallet state (used during logout/reset)
    func resetWalletState() {
        setHasWallet(false)
        setIsLoggedIn(false)
        walletInfo = nil
        walletInfoError = nil
        print("🔄 Wallet state reset")
    }
    
    /// Logout user (clear login state but keep wallet)
    func logout() async {
        setIsLoggedIn(false)
        
        // Clear cached seed
        repository.clearCache()
        
        // Clear currency selection
        CurrencyManager.shared.clearSelectedCurrency()
        
        print("👋 User logged out")
    }
    
    /// Delete wallet completely (remove from keychain)
    func deleteWallet() async throws {
        do {
            // Delete from keychain
            try repository.deleteMnemonic()
            
            // Reset all state
            resetWalletState()
            
            // Clear currency selection
            CurrencyManager.shared.clearSelectedCurrency()
            
            print("🗑️ Wallet deleted completely")
        } catch {
            errorHandler.logError(.wallet(.initializationFailed), context: "Wallet deletion")
            throw error
        }
    }
    
    /// Export wallet mnemonic with biometric authentication
    func exportMnemonic() async throws -> String {
        guard hasWallet else {
            throw WalletError.walletNotFound
        }
        
        do {
            let mnemonic = try await repository.getSecureMnemonic(reason: "Export your wallet seed phrase")
            print("📤 Wallet mnemonic exported securely")
            return mnemonic
        } catch {
            errorHandler.logError(.wallet(.initializationFailed), context: "Mnemonic export")
            throw error
        }
    }
    
    /// Validate wallet state consistency
    func validateWalletState() -> WalletStateValidation {
        // Check if states are consistent
        if hasWallet && !repository.mnemonicExists() {
            return .inconsistent("Wallet marked as existing but no mnemonic found")
        }
        
        if !hasWallet && repository.mnemonicExists() {
            return .inconsistent("Mnemonic exists but wallet not marked as existing")
        }
        
        if isLoggedIn && !hasWallet {
            return .inconsistent("User marked as logged in but no wallet exists")
        }
        
        if isLoggedIn && !repository.isCacheValid() {
            return .warning("User logged in but cache is invalid")
        }
        
        return .valid
    }
    
    /// Repair wallet state inconsistencies
    func repairWalletState() {
        let validation = validateWalletState()
        
        switch validation {
        case .valid:
            print("✅ Wallet state is consistent")
            
        case .warning(let message):
            print("⚠️ Wallet state warning: \(message)")
            // For warnings, we might just log but not change state
            
        case .inconsistent(let message):
            print("🔧 Repairing wallet state inconsistency: \(message)")
            
            // Repair based on keychain truth
            let mnemonicExists = repository.mnemonicExists()
            setHasWallet(mnemonicExists)
            
            // If no mnemonic, user can't be logged in
            if !mnemonicExists {
                setIsLoggedIn(false)
            }
        }
    }
}

// MARK: - Supporting Types

enum WalletStateValidation {
    case valid
    case warning(String)
    case inconsistent(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .warning, .inconsistent:
            return false
        }
    }
    
    var message: String? {
        switch self {
        case .valid:
            return nil
        case .warning(let msg), .inconsistent(let msg):
            return msg
        }
    }
}

// MARK: - Wallet State Helpers

extension WalletStateManager {
    
    /// Get wallet status summary
    func getWalletStatusSummary() -> WalletStatusSummary {
        return WalletStatusSummary(
            hasWallet: hasWallet,
            isLoggedIn: isLoggedIn,
            isConnected: walletService.isConnected,
            nodeId: getNodeId(),
            balance: getBalanceFromInfo(),
            isReady: isWalletReady()
        )
    }
}

struct WalletStatusSummary {
    let hasWallet: Bool
    let isLoggedIn: Bool
    let isConnected: Bool
    let nodeId: String?
    let balance: UInt64?
    let isReady: Bool
    
    var statusDescription: String {
        if isReady {
            return "Ready"
        } else if !hasWallet {
            return "No Wallet"
        } else if !isLoggedIn {
            return "Logged Out"
        } else if !isConnected {
            return "Disconnected"
        } else {
            return "Unknown"
        }
    }
}
