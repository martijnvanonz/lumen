# Webhook Integration

## Status: ❌ Missing (Critical Priority)

## Overview
**Purpose**: Receive payment notifications when app is offline, enabling true background payment processing.

**Documentation**: [Using Webhooks](https://sdk-doc-liquid.breez.technology/notifications/using_webhooks.html)

**User Impact**: Essential for BOLT12 offers and reliable offline payment processing. Without webhooks, the wallet cannot receive payments when completely offline or handle BOLT12 invoice requests.

## Implementation Details

### Files to Create/Modify
- **Modify**: `Lumen/Wallet/WalletManager.swift` (webhook registration)
- **Modify**: `NotificationService/NotificationService.swift` (webhook handling)
- **Create**: `Lumen/Network/WebhookManager.swift` (new file)

### Dependencies
1. Notification Service Extension
2. Server endpoint for webhook URL (or webhook relay service)
3. SSL certificate for webhook endpoint

## Webhook Registration

### Step 1: Register Webhook During SDK Connection
Modify `WalletManager.swift`:

```swift
import BreezSDKLiquid

class WalletManager: ObservableObject {
    private let webhookUrl = "https://your-server.com/webhook/lumen"
    
    private func connectToBreezSDK(mnemonic: String) async throws {
        // ... existing connection code ...
        
        // Register webhook after successful connection
        try await registerWebhook()
    }
    
    private func registerWebhook() async throws {
        guard let sdk = sdk else { return }
        
        do {
            try await sdk.registerWebhook(webhookUrl: webhookUrl)
            logInfo("Webhook registered successfully: \(webhookUrl)")
        } catch {
            logError("Failed to register webhook: \(error)")
            throw error
        }
    }
    
    func unregisterWebhook() async throws {
        guard let sdk = sdk else { return }
        
        do {
            try await sdk.unregisterWebhook(webhookUrl: webhookUrl)
            logInfo("Webhook unregistered successfully")
        } catch {
            logError("Failed to unregister webhook: \(error)")
            throw error
        }
    }
}
```

### Step 2: Create WebhookManager
Create `Lumen/Network/WebhookManager.swift`:

```swift
import Foundation
import BreezSDKLiquid

class WebhookManager {
    static let shared = WebhookManager()
    private init() {}
    
    private let webhookUrl = "https://your-server.com/webhook/lumen"
    
    func registerWebhook(with sdk: BindingLiquidSdk) async throws {
        try await sdk.registerWebhook(webhookUrl: webhookUrl)
        logInfo("Webhook registered: \(webhookUrl)")
    }
    
    func unregisterWebhook(with sdk: BindingLiquidSdk) async throws {
        try await sdk.unregisterWebhook(webhookUrl: webhookUrl)
        logInfo("Webhook unregistered")
    }
    
    func handleWebhookEvent(_ eventData: Data) {
        // Process webhook event in notification service
        do {
            // Parse webhook payload
            let event = try parseWebhookEvent(eventData)
            
            // Handle different event types
            switch event.type {
            case .bolt12InvoiceRequest:
                handleBolt12InvoiceRequest(event)
            case .paymentReceived:
                handlePaymentReceived(event)
            default:
                logInfo("Unhandled webhook event type: \(event.type)")
            }
        } catch {
            logError("Failed to process webhook event: \(error)")
        }
    }
    
    private func parseWebhookEvent(_ data: Data) throws -> WebhookEvent {
        // Implement webhook event parsing based on Breez SDK format
        // This will depend on the specific webhook payload structure
        throw NSError(domain: "WebhookManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    private func handleBolt12InvoiceRequest(_ event: WebhookEvent) {
        // Handle BOLT12 invoice requests when app is offline
        logInfo("Handling BOLT12 invoice request")
    }
    
    private func handlePaymentReceived(_ event: WebhookEvent) {
        // Handle payment received notifications
        logInfo("Handling payment received notification")
    }
}

struct WebhookEvent {
    let type: WebhookEventType
    let data: [String: Any]
}

enum WebhookEventType {
    case bolt12InvoiceRequest
    case paymentReceived
    case paymentFailed
    case unknown
}
```

## Webhook Server Implementation Options

### Option 1: Custom Server
You'll need to implement a webhook endpoint that:
1. Receives POST requests from Breez SDK
2. Forwards notifications to Apple Push Notification Service (APNs)
3. Handles BOLT12 invoice requests

### Option 2: Webhook Relay Service
Use a third-party service like:
- **Pusher** - Real-time messaging service
- **Firebase Cloud Functions** - Serverless webhook handling
- **AWS Lambda** - Serverless webhook processing

### Option 3: Simple Webhook Forwarder
Minimal implementation that forwards webhooks to APNs:

```javascript
// Example Node.js webhook forwarder
const express = require('express');
const apn = require('apn');

const app = express();
app.use(express.json());

const apnProvider = new apn.Provider({
    token: {
        key: 'path/to/AuthKey.p8',
        keyId: 'your-key-id',
        teamId: 'your-team-id'
    },
    production: false // Set to true for production
});

app.post('/webhook/lumen', (req, res) => {
    const webhookData = req.body;
    
    // Create push notification
    const notification = new apn.Notification();
    notification.alert = 'Lightning payment received';
    notification.payload = webhookData;
    notification.topic = 'com.yourapp.lumen';
    
    // Send to all registered devices
    // You'll need to store device tokens
    apnProvider.send(notification, deviceTokens);
    
    res.status(200).send('OK');
});
```

## Notification Service Webhook Handling

Update `NotificationService.swift`:

```swift
import UserNotifications
import BreezSDKLiquid

class NotificationService: SDKNotificationService {
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        // Get webhook data from notification payload
        let userInfo = request.content.userInfo
        
        if let webhookData = userInfo["webhook_data"] as? [String: Any] {
            handleWebhookData(webhookData, contentHandler: contentHandler)
        } else {
            // Standard notification handling
            super.didReceive(request, withContentHandler: contentHandler)
        }
    }
    
    private func handleWebhookData(_ data: [String: Any], contentHandler: @escaping (UNNotificationContent) -> Void) {
        // Process webhook data and update notification content
        let content = UNMutableNotificationContent()
        
        if let eventType = data["event_type"] as? String {
            switch eventType {
            case "payment_received":
                content.title = "Payment Received"
                content.body = "Lightning payment received"
                
            case "bolt12_invoice_request":
                content.title = "Payment Request"
                content.body = "Someone wants to pay your BOLT12 offer"
                
            default:
                content.title = "Lightning Wallet"
                content.body = "New activity"
            }
        }
        
        content.sound = .default
        contentHandler(content)
    }
}
```

## Configuration Management

Add webhook configuration to `ConfigurationManager.swift`:

```swift
class ConfigurationManager {
    private(set) var webhookUrl: String = ""
    
    private func loadEnvironmentVariables() {
        // ... existing code ...
        
        webhookUrl = getEnvironmentValue(for: "WEBHOOK_URL") ?? ""
        
        // Validate webhook URL
        validateWebhookConfiguration()
    }
    
    private func validateWebhookConfiguration() {
        if webhookUrl.isEmpty {
            print("⚠️ WEBHOOK_URL not configured - background payments may not work")
        } else if !webhookUrl.hasPrefix("https://") {
            print("⚠️ WEBHOOK_URL should use HTTPS for security")
        } else {
            print("✅ Webhook URL configured: \(webhookUrl)")
        }
    }
}
```

Add to `.env` file:
```
WEBHOOK_URL=https://your-server.com/webhook/lumen
```

## Testing Strategy

### Unit Tests
```swift
func testWebhookRegistration() async {
    let mockSDK = MockLiquidSDK()
    let webhookManager = WebhookManager.shared
    
    do {
        try await webhookManager.registerWebhook(with: mockSDK)
        XCTAssertTrue(mockSDK.webhookRegistered)
    } catch {
        XCTFail("Webhook registration failed: \(error)")
    }
}

func testWebhookEventHandling() {
    let webhookData = """
    {
        "event_type": "payment_received",
        "amount_sat": 1000,
        "payment_hash": "abc123"
    }
    """.data(using: .utf8)!
    
    let webhookManager = WebhookManager.shared
    webhookManager.handleWebhookEvent(webhookData)
    
    // Verify event was processed correctly
}
```

### Integration Tests
1. **Webhook Registration Test**:
   - Connect to SDK
   - Verify webhook is registered
   - Check webhook URL is correct

2. **Offline Payment Test**:
   - Close app completely
   - Send payment to wallet
   - Verify webhook triggers notification
   - Verify payment is processed when app reopens

3. **BOLT12 Webhook Test**:
   - Generate BOLT12 offer
   - Request payment while app is offline
   - Verify webhook handles invoice request

### Manual Testing Checklist
- [ ] Webhook registers successfully during SDK connection
- [ ] Webhook unregisters when disconnecting
- [ ] Push notifications arrive when app is closed
- [ ] BOLT12 invoice requests work offline
- [ ] Payment notifications contain correct information

## Security Considerations

### Webhook Endpoint Security
- **Use HTTPS only** - Never use HTTP for webhook URLs
- **Validate webhook signatures** - Verify requests come from Breez SDK
- **Rate limiting** - Prevent webhook spam
- **Authentication** - Secure your webhook endpoint

### Data Privacy
- **Minimal data exposure** - Only include necessary payment information
- **No sensitive data** - Never include private keys or mnemonics
- **Encryption** - Consider additional encryption for sensitive webhook data

## Common Issues and Solutions

### Issue: Webhook registration fails
**Cause**: Invalid webhook URL or network issues
**Solution**: 
- Verify webhook URL is accessible and uses HTTPS
- Check network connectivity
- Validate SSL certificate

### Issue: Notifications not received
**Cause**: Webhook server not forwarding to APNs
**Solution**:
- Verify webhook server is receiving requests
- Check APNs configuration and certificates
- Test with simple webhook payload

### Issue: BOLT12 requests not handled
**Cause**: Webhook not processing BOLT12 events
**Solution**:
- Implement BOLT12 event handling in webhook server
- Verify notification service processes BOLT12 events
- Test BOLT12 offer generation and payment flow

## Estimated Development Time
**2-3 days** for experienced iOS developer

### Breakdown:
- Day 1: Webhook registration implementation
- Day 2: Webhook server setup (simple forwarder)
- Day 3: Notification service integration and testing

## Success Criteria
- [ ] Webhook registers successfully during SDK connection
- [ ] App receives notifications when completely closed
- [ ] BOLT12 offers work with app offline
- [ ] Payment notifications are accurate and timely
- [ ] Webhook unregisters properly when needed
- [ ] No security vulnerabilities in webhook implementation

## References
- [Breez SDK Webhook Documentation](https://sdk-doc-liquid.breez.technology/notifications/using_webhooks.html)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [iOS Notification Service Extension](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension)
