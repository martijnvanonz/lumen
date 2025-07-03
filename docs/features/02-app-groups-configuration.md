# App Groups Configuration

## Status: ❌ Missing (Critical Priority)

## Overview
**Purpose**: Share data between main app and notification service extension for seamless payment processing.

**Documentation**: [iOS Service Extension Setup](https://sdk-doc-liquid.breez.technology/notifications/ios_service.html)

**User Impact**: Required foundation for background payment processing. Without App Groups, the notification service cannot access the wallet data needed to process payments.

## Implementation Details

### App Group Identifier
**Recommended**: `group.com.yourapp.lumen`

### Files to Modify
- Xcode project capabilities for both targets
- Apple Developer portal configuration
- `Lumen/Utils/ConfigurationManager.swift`
- `Lumen/Security/KeychainManager.swift`

### Dependencies
- Apple Developer account with App Groups capability
- Team ID for keychain group configuration

## Apple Developer Portal Setup

### Step 1: Create App Group
1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list/applicationGroup)
2. Click **Identifiers** → **App Groups** dropdown → **+**
3. Select **App Groups**
4. **Description**: `Lumen Lightning Wallet Shared Data`
5. **Identifier**: `group.com.yourapp.lumen`
6. Click **Continue** → **Register**

### Step 2: Update Main App Identifier
1. Go to **Identifiers** → **App IDs**
2. Select your main app identifier (e.g., `com.yourapp.lumen`)
3. Click **Edit**
4. Enable **App Groups** capability
5. Click **Edit** next to App Groups
6. Select `group.com.yourapp.lumen`
7. Click **Continue** → **Save**

### Step 3: Create Notification Service Identifier
1. Click **+** to add new identifier
2. Select **App IDs**
3. **Description**: `Lumen Notification Service`
4. **Bundle ID**: `com.yourapp.lumen.NotificationService`
5. Enable **App Groups** capability
6. Click **Continue**
7. Edit App Groups and select `group.com.yourapp.lumen`
8. Click **Continue** → **Register**

### Step 4: Create New Provisioning Profiles
Create new provisioning profiles for both identifiers that include the App Groups capability:

1. **Main App Profile**:
   - Type: iOS App Development (or Distribution)
   - App ID: `com.yourapp.lumen`
   - Include App Groups capability

2. **Notification Service Profile**:
   - Type: iOS App Development (or Distribution)  
   - App ID: `com.yourapp.lumen.NotificationService`
   - Include App Groups capability

## Xcode Project Configuration

### Step 1: Update Main App Target
1. Select project in navigator
2. Select **Lumen** target
3. Go to **Signing & Capabilities**
4. Update **Provisioning Profile** to newly created one
5. Click **+ Capability**
6. Add **App Groups**
7. Enable `group.com.yourapp.lumen`

### Step 2: Configure Notification Service Target
1. Select **NotificationService** target
2. Go to **Signing & Capabilities**
3. Update **Provisioning Profile** to newly created one
4. Click **+ Capability**
5. Add **App Groups**
6. Enable `group.com.yourapp.lumen`

### Step 3: Add Keychain Sharing (Both Targets)
1. Click **+ Capability**
2. Add **Keychain Sharing**
3. Add keychain group: `$(AppIdentifierPrefix)com.yourapp.SharedKeychain`

**Note**: Replace `$(AppIdentifierPrefix)` with your actual Team ID.

## Code Implementation

### Update ConfigurationManager.swift
```swift
class ConfigurationManager {
    private static let appGroup = "group.com.yourapp.lumen"
    
    func getBreezSDKConfig() throws -> Config {
        // ... existing code ...
        
        // Use shared container for working directory
        guard let sharedContainer = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroup
        ) else {
            throw ConfigurationError.invalidConfiguration("App Group container not accessible")
        }
        
        let workingDir = sharedContainer.appendingPathComponent("breezSdkLiquid").path
        
        // Create directory if it doesn't exist
        try FileManager.default.createDirectory(
            atPath: workingDir, 
            withIntermediateDirectories: true, 
            attributes: nil
        )
        
        config.workingDir = workingDir
        
        // ... rest of implementation
    }
    
    static func getSharedContainerURL() -> URL? {
        return FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        )
    }
}
```

### Update KeychainManager.swift
```swift
class KeychainManager {
    // Replace with your actual Team ID
    private static let keychainGroup = "A1B2C3D4E5.com.yourapp.SharedKeychain"
    
    func storeMnemonic(_ mnemonic: String) throws {
        guard let data = mnemonic.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.service,
            kSecAttrAccount as String: Constants.mnemonicKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecAttrSynchronizable as String: true,
            kSecAttrAccessGroup as String: Self.keychainGroup // Add this line
        ]
        
        // ... rest of implementation
    }
    
    func retrieveMnemonic() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.service,
            kSecAttrAccount as String: Constants.mnemonicKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: true,
            kSecAttrAccessGroup as String: Self.keychainGroup // Add this line
        ]
        
        // ... rest of implementation
    }
}
```

## Testing and Validation

### Validation Checklist
- [ ] App Group appears in both target capabilities
- [ ] Shared container is accessible from main app
- [ ] Shared container is accessible from notification service
- [ ] Keychain sharing works between targets
- [ ] Provisioning profiles include App Groups capability

### Testing Commands
```swift
// Test shared container access
func testSharedContainer() {
    guard let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.yourapp.lumen"
    ) else {
        print("❌ App Group container not accessible")
        return
    }
    
    print("✅ App Group container: \(containerURL.path)")
    
    // Test write access
    let testFile = containerURL.appendingPathComponent("test.txt")
    do {
        try "test".write(to: testFile, atomically: true, encoding: .utf8)
        print("✅ Write access confirmed")
        try FileManager.default.removeItem(at: testFile)
    } catch {
        print("❌ Write access failed: \(error)")
    }
}
```

### Common Issues and Solutions

#### Issue: "App Group container not accessible"
**Cause**: App Groups capability not properly configured
**Solution**: 
1. Verify App Groups is enabled in both targets
2. Check that identifier matches exactly: `group.com.yourapp.lumen`
3. Ensure provisioning profiles include App Groups capability

#### Issue: Keychain access denied between targets
**Cause**: Keychain group not properly configured
**Solution**:
1. Verify Keychain Sharing capability is added to both targets
2. Ensure keychain group includes Team ID prefix
3. Check that keychain group name is identical in both targets

#### Issue: Provisioning profile errors
**Cause**: Profiles don't include new capabilities
**Solution**:
1. Create new provisioning profiles in Apple Developer portal
2. Include App Groups capability in profiles
3. Download and install new profiles in Xcode

## Security Considerations

### Data Stored in Shared Container
**Safe to store**:
- SDK working directory data
- Non-sensitive configuration
- Payment history cache
- Temporary files

**Never store**:
- Mnemonic phrases (use keychain only)
- Private keys
- API keys
- User passwords

### Keychain Group Access
- Only apps with same Team ID can access shared keychain
- Keychain data is encrypted by iOS
- Access requires proper entitlements

## Estimated Development Time
**1 day** for experienced iOS developer

### Breakdown:
- 2 hours: Apple Developer portal setup
- 2 hours: Xcode project configuration
- 2 hours: Code implementation
- 2 hours: Testing and validation

## Success Criteria
- [ ] App Groups capability enabled in both targets
- [ ] Shared container accessible from both main app and notification service
- [ ] Keychain sharing works between targets
- [ ] No provisioning profile errors
- [ ] SDK can use shared working directory
- [ ] Mnemonic accessible from notification service

## References
- [Apple Developer - App Groups](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
- [Breez SDK iOS Service Setup](https://sdk-doc-liquid.breez.technology/notifications/ios_service.html)
- [iOS App Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/)
