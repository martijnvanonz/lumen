# Lumen Lightning Wallet - Implementation Roadmap

## Executive Summary

Lumen has a **solid foundation** with excellent security (Face ID/Touch ID), biometric authentication, iCloud Keychain backup, and basic Lightning payment functionality. However, **critical iOS-specific notification features are missing** that prevent production deployment.

**Current Status**: ~60% complete for production readiness
**Critical Gap**: iOS Notification Service Extension for background payment processing
**Timeline to Production**: 4-6 weeks focusing on Critical and Important priorities

The wallet correctly implements core SDK integration, security, and basic payment flows, but lacks essential features like background notifications, BOLT12 offers, refund management, and advanced payment parsing that are required for a competitive Lightning wallet.

## Critical Missing Features (❌ - Must Fix for Production)

### 1. iOS Notification Service Extension
**Status**: ❌ Missing  
**Documentation**: [iOS Notification Setup](https://sdk-doc-liquid.breez.technology/notifications/ios_setup.html)  
**Purpose**: Enable background payment processing when app is closed. Without this, users cannot receive Lightning payments unless the app is actively running.  
**Implementation Location**: 
- Create new `NotificationService` target
- `NotificationService/NotificationService.swift` (new file)
- Modify `Lumen/Wallet/WalletManager.swift` for shared container support
**Dependencies**: App Groups, Keychain Sharing, Webhook registration  
**Estimated Time**: 3-4 days

### 2. App Groups Configuration
**Status**: ❌ Missing  
**Documentation**: [iOS Service Extension Setup](https://sdk-doc-liquid.breez.technology/notifications/ios_service.html)  
**Purpose**: Share data between main app and notification service extension for seamless payment processing.  
**Implementation Location**: 
- Xcode project capabilities configuration
- Apple Developer portal setup
- Update `Lumen/Utils/ConfigurationManager.swift`
**Dependencies**: Apple Developer account configuration  
**Estimated Time**: 1 day

### 3. Webhook Integration
**Status**: ❌ Missing  
**Documentation**: [Using Webhooks](https://sdk-doc-liquid.breez.technology/notifications/using_webhooks.html)  
**Purpose**: Receive payment notifications when app is offline, enabling true background payment processing.  
**Implementation Location**: 
- `Lumen/Wallet/WalletManager.swift` - webhook registration
- `NotificationService/NotificationService.swift` - webhook handling
**Dependencies**: Notification Service Extension, server endpoint for webhook  
**Estimated Time**: 2-3 days

### 4. Refundable Swap Management
**Status**: ❌ Missing  
**Documentation**: [Refunding Payments](https://sdk-doc-liquid.breez.technology/guide/refund_payment.html)  
**Purpose**: Allow users to recover funds from failed Bitcoin payments. Critical for user trust and fund safety.  
**Implementation Location**: 
- `Lumen/Views/RefundView.swift` (enhance existing)
- `Lumen/Wallet/WalletManager.swift` - add refund methods
- New `Lumen/Wallet/RefundManager.swift`
**Dependencies**: None  
**Estimated Time**: 2-3 days

## Important Missing Features (❌ - Should Fix Soon)

### 5. Payment Limits Validation
**Status**: ❌ Missing  
**Documentation**: [Receiving Payments](https://sdk-doc-liquid.breez.technology/guide/receive_payment.html)  
**Purpose**: Validate payment amounts against Lightning and onchain limits to prevent failed transactions.  
**Implementation Location**: 
- `Lumen/Wallet/WalletManager.swift` - add limit checking methods
- `Lumen/Views/SendPaymentView.swift` - add validation UI
- `Lumen/Views/ReceivePaymentView.swift` - add limit display
**Dependencies**: None  
**Estimated Time**: 1-2 days

### 6. Fee Acceptance Flow
**Status**: ❌ Missing  
**Documentation**: [Amountless Bitcoin Payments](https://sdk-doc-liquid.breez.technology/guide/receive_payment.html#amountless-bitcoin-payments)  
**Purpose**: Handle fee acceptance for amountless Bitcoin payments when onchain fees increase.  
**Implementation Location**: 
- `Lumen/Wallet/PaymentEventHandler.swift` - handle fee acceptance events
- New `Lumen/Views/FeeAcceptanceView.swift`
- `Lumen/Wallet/WalletManager.swift` - add fee acceptance methods
**Dependencies**: None  
**Estimated Time**: 2-3 days

### 7. BOLT12 Offer Support
**Status**: ❌ Missing  
**Documentation**: [Receiving Payments - BOLT12](https://sdk-doc-liquid.breez.technology/guide/receive_payment.html#bolt12-offer)  
**Purpose**: Generate reusable payment codes for multiple payments, improving user experience.  
**Implementation Location**: 
- `Lumen/Views/ReceivePaymentView.swift` - add BOLT12 option
- `Lumen/Wallet/WalletManager.swift` - add BOLT12 methods
- New `Lumen/Views/OfferManagementView.swift`
**Dependencies**: Webhook integration for offline BOLT12 requests  
**Estimated Time**: 3-4 days

### 8. Enhanced Payment Input Parsing
**Status**: ❌ Missing  
**Documentation**: [Parsing Inputs](https://sdk-doc-liquid.breez.technology/guide/parse.html)  
**Purpose**: Support BIP353 addresses, LNURL, and comprehensive payment format validation.  
**Implementation Location**: 
- `Lumen/Wallet/WalletManager.swift` - enhance `parseInput()` method
- `Lumen/Views/SendPaymentView.swift` - improve input validation UI
**Dependencies**: None  
**Estimated Time**: 2-3 days

## Partially Implemented Features (⚠️ - Need Completion)

### 9. Comprehensive Fee Display
**Status**: ⚠️ Partial  
**Documentation**: [End-User Fees](https://sdk-doc-liquid.breez.technology/guide/end-user_fees.html)  
**Purpose**: Show detailed fee breakdown for different payment types (submarine swap vs direct Liquid).  
**Implementation Location**: 
- `Lumen/Views/FeeComparisonView.swift` (enhance existing)
- `Lumen/Views/SendPaymentView.swift` - improve fee display
- `Lumen/Views/ReceivePaymentView.swift` - add fee information
**Dependencies**: None  
**Estimated Time**: 1-2 days

### 10. Advanced Error Recovery
**Status**: ⚠️ Partial  
**Documentation**: [Production Checklist](https://sdk-doc-liquid.breez.technology/guide/production.html)  
**Purpose**: Handle all payment failure scenarios with appropriate user guidance.  
**Implementation Location**: 
- `Lumen/Utils/ErrorHandler.swift` (enhance existing)
- `Lumen/Wallet/PaymentEventHandler.swift` - add more event handling
**Dependencies**: Refund management  
**Estimated Time**: 2 days

## Development Phases

### Phase 1: Critical Production Features (3-4 weeks)
**Goal**: Achieve production readiness with background payment processing

1. **Week 1**: iOS Notification Infrastructure
   - App Groups configuration (1 day)
   - Notification Service Extension (3-4 days)

2. **Week 2**: Background Payment Processing  
   - Webhook integration (2-3 days)
   - Testing and debugging (2 days)

3. **Week 3**: Payment Safety Features
   - Refundable swap management (2-3 days)
   - Payment limits validation (1-2 days)

4. **Week 4**: Testing and Polish
   - Integration testing (2 days)
   - Bug fixes and optimization (3 days)

### Phase 2: Enhanced Payment Features (2-3 weeks)
**Goal**: Competitive Lightning wallet functionality

1. **Week 5**: Advanced Payment Handling
   - Fee acceptance flow (2-3 days)
   - Enhanced payment parsing (2-3 days)

2. **Week 6**: BOLT12 and Modern Features
   - BOLT12 offer support (3-4 days)
   - Comprehensive fee display (1-2 days)

3. **Week 7**: Error Handling and Polish
   - Advanced error recovery (2 days)
   - Testing and optimization (3 days)

### Phase 3: Advanced Features (4-6 weeks)
**Goal**: Premium Lightning wallet experience

1. **Multi-Asset Support** (1-2 weeks)
   - Liquid asset handling beyond Bitcoin
   - Asset selection UI

2. **LNURL Functionality** (2-3 weeks)
   - LNURL-pay, LNURL-withdraw, LNURL-auth
   - Lightning address resolution

3. **Premium Features** (1-2 weeks)
   - Fiat currency display
   - Advanced payment analytics
   - Manual backup/restore

## iOS-Specific Setup Requirements

### Required Xcode Project Changes
1. **Add Notification Service Extension Target**
   - File > New > Target > Notification Service Extension
   - Name: `NotificationService`

2. **Configure App Groups**
   - Identifier: `group.com.yourapp.lumen`
   - Add to both main app and notification service targets

3. **Set up Keychain Sharing**
   - Keychain Group: `<TEAM_ID>.com.yourapp.SharedKeychain`
   - Configure in both targets

4. **Update Package Dependencies**
   - Add BreezSDKLiquid to NotificationService target
   - Add KeychainAccess for secure storage

### Apple Developer Portal Configuration
1. **Create App Group**
   - Identifier: `group.com.yourapp.lumen`

2. **Update App IDs**
   - Enable App Groups capability
   - Associate with created app group

3. **Create New Provisioning Profiles**
   - For both main app and notification service
   - Include App Groups capability

## Success Metrics

### Phase 1 Completion Criteria
- [ ] Users can receive Lightning payments with app closed
- [ ] Background notifications work reliably
- [ ] Failed Bitcoin payments can be refunded
- [ ] Payment limits are validated and displayed

### Phase 2 Completion Criteria  
- [ ] BOLT12 offers can be generated and paid
- [ ] All payment input formats are supported
- [ ] Fee acceptance flow works for amountless payments
- [ ] Comprehensive fee information is displayed

### Phase 3 Completion Criteria
- [ ] Multi-asset payments supported
- [ ] LNURL functionality implemented
- [ ] Fiat currency display available
- [ ] Advanced features enhance user experience

**Total Estimated Timeline**: 9-13 weeks for complete implementation
**Production Ready Timeline**: 4-6 weeks (Phases 1-2)
