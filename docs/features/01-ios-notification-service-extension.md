# iOS Notification Service Extension

## Status: ❌ Missing (Critical Priority)

## Overview
**Purpose**: Enable background payment processing when app is closed. Without this, users cannot receive Lightning payments unless the app is actively running.

**Documentation**: [iOS Notification Setup](https://sdk-doc-liquid.breez.technology/notifications/ios_setup.html)

**User Impact**: This is the most critical missing feature. Lightning wallets must be able to receive payments 24/7, even when the app is not running. Without this, Lumen cannot compete with other Lightning wallets.

## Implementation Details

### Files to Create/Modify
- **Create**: `NotificationService/NotificationService.swift` (new target)
- **Modify**: `Lumen/Wallet/WalletManager.swift` (shared container support)
- **Modify**: `Lumen/Utils/ConfigurationManager.swift` (shared working directory)

### Dependencies
1. App Groups configuration
2. Keychain Sharing setup
3. Webhook registration

### Xcode Project Changes Required

#### 1. Add Notification Service Extension Target
```
File > New > Target > Notification Service Extension
Name: NotificationService
Bundle Identifier: com.yourapp.lumen.NotificationService
```

#### 2. Add Package Dependencies to NotificationService Target
- BreezSDKLiquid
- KeychainAccess (for mnemonic access)

### Implementation Steps

#### Step 1: Create NotificationService.swift
```swift
import UserNotifications
import KeychainAccess
import BreezSDKLiquid

fileprivate let appGroup = "group.com.yourapp.lumen"
fileprivate let keychainGroup = "<TEAM_ID>.com.yourapp.SharedKeychain"
fileprivate let accountMnemonic: String = "BREEZ_SDK_LIQUID_SEED_MNEMONIC"
fileprivate let accountApiKey: String = "BREEZ_API_KEY"

class NotificationService: SDKNotificationService {
    override func getConnectRequest() -> ConnectRequest? {
        // Get API key from bundle
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: accountApiKey) as? String else {
            return nil
        }
        
        // Configure SDK with shared directory
        var config = defaultConfig(network: LiquidNetwork.mainnet, breezApiKey: apiKey)
        config.workingDir = FileManager
            .default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)!
            .appendingPathComponent("breezSdkLiquid", isDirectory: true)
            .path

        // Get mnemonic from shared keychain
        let service = Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".NotificationService", with: "")
        let keychain = Keychain(service: service, accessGroup: keychainGroup)
        guard let mnemonic = try? keychain.getString(accountMnemonic) else {
            return nil
        }
        
        return ConnectRequest(config: config, mnemonic: mnemonic)
    }
}
```

#### Step 2: Update Main App for Shared Container
Modify `ConfigurationManager.swift`:
```swift
func getBreezSDKConfig() throws -> Config {
    // ... existing code ...
    
    // Use shared container for working directory
    let sharedContainer = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.yourapp.lumen"
    )!
    let workingDir = sharedContainer.appendingPathComponent("breezSdkLiquid").path
    
    config.workingDir = workingDir
    
    // ... rest of implementation
}
```

#### Step 3: Update Keychain Storage
Modify `KeychainManager.swift` to use shared keychain:
```swift
private let keychainGroup = "<TEAM_ID>.com.yourapp.SharedKeychain"

func storeMnemonic(_ mnemonic: String) throws {
    // ... existing code but add accessGroup ...
    let query: [String: Any] = [
        // ... existing keys ...
        kSecAttrAccessGroup as String: keychainGroup
    ]
    // ... rest of implementation
}
```

### Testing Strategy

#### Unit Tests
- Test NotificationService initialization
- Test shared container access
- Test keychain access from notification service

#### Integration Tests
- Send payment to wallet while app is closed
- Verify notification appears
- Verify payment is processed correctly
- Test with various payment types (Lightning, Bitcoin)

#### Manual Testing Checklist
- [ ] App receives Lightning payments when closed
- [ ] Notifications appear with correct payment details
- [ ] Payment history updates when app reopens
- [ ] Balance updates correctly after background payment
- [ ] Works with both Face ID and Touch ID authentication

### Common Issues and Solutions

#### Issue: Keychain Access Denied
**Solution**: Ensure keychain group is properly configured in both targets and includes team ID prefix.

#### Issue: Shared Container Not Found
**Solution**: Verify App Groups capability is enabled and identifier matches exactly.

#### Issue: SDK Connection Fails
**Solution**: Check API key is properly configured in notification service Info.plist.

### Performance Considerations
- Notification service has limited execution time (30 seconds)
- SDK connection should be optimized for quick startup
- Consider caching connection state when possible

### Security Considerations
- Mnemonic access requires proper keychain group configuration
- API key should be stored securely in notification service bundle
- Shared container should only contain non-sensitive data

## Estimated Development Time
**3-4 days** for experienced iOS developer

### Breakdown:
- Day 1: Xcode project setup and configuration
- Day 2: NotificationService implementation
- Day 3: Main app modifications for shared container
- Day 4: Testing and debugging

## Success Criteria
- [ ] Users receive Lightning payments with app completely closed
- [ ] Push notifications appear for incoming payments
- [ ] Payment history and balance update correctly when app reopens
- [ ] Works reliably across different iOS versions (17.0+)
- [ ] No crashes or memory issues in notification service

## References
- [Breez SDK iOS Notification Setup](https://sdk-doc-liquid.breez.technology/notifications/ios_setup.html)
- [iOS Service Extension Setup](https://sdk-doc-liquid.breez.technology/notifications/ios_service.html)
- [Configuring Main Application](https://sdk-doc-liquid.breez.technology/notifications/ios_connect.html)
- [Misty Breez Reference Implementation](https://github.com/breez/misty-breez/blob/main/ios/NotificationService/NotificationService.swift)
