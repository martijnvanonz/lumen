//
//  NotificationService.swift
//  NotificationService
//
//  Created by Martijn | Bravoure on 06/07/2025.
//

import UserNotifications
import BreezSDKLiquid
import Foundation

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    private var sdk: BindingLiquidSdk?

    // MARK: - Notification Processing

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // Log notification received
        print("🔔 NotificationService: Received notification")
        print("🔔 Payload: \(request.content.userInfo)")

        // Process the webhook notification
        Task {
            await processWebhookNotification(request: request, content: bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        print("⏰ NotificationService: Extension time will expire")

        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            // Provide fallback content
            bestAttemptContent.title = "Lightning Payment"
            bestAttemptContent.body = "Payment processing in background..."
            contentHandler(bestAttemptContent)
        }
    }

    // MARK: - Webhook Processing

    private func processWebhookNotification(request: UNNotificationRequest, content: UNMutableNotificationContent) async {
        do {
            // Initialize SDK if needed
            try await initializeSDKIfNeeded()

            // Parse webhook payload
            let webhookData = try parseWebhookPayload(request.content.userInfo)

            // Process the payment event
            let processedContent = try await processPaymentEvent(webhookData, content: content)

            // Deliver the processed notification
            contentHandler?(processedContent)

        } catch {
            print("❌ NotificationService: Failed to process webhook: \(error)")

            // Fallback to basic notification
            content.title = "Lightning Payment"
            content.body = "New payment received"
            contentHandler?(content)
        }
    }

    // MARK: - SDK Initialization

    private func initializeSDKIfNeeded() async throws {
        guard sdk == nil else { return }

        print("🔧 NotificationService: Initializing Breez SDK")

        // Get shared configuration
        let sharedContainer = SharedContainerManager.shared
        let configData = try sharedContainer.retrieveBreezConfig()
        let mnemonic = try sharedContainer.retrieveMnemonicForExtension()

        // Create SDK config for notification extension
        let config = Config(
            liquidExplorer: BlockchainExplorer.esplora(url: "https://liquid.network", useWaterfalls: false),
            bitcoinExplorer: BlockchainExplorer.esplora(url: "https://mempool.space", useWaterfalls: false),
            workingDir: configData.workingDir,
            network: configData.network,
            paymentTimeoutSec: configData.paymentTimeoutSec,
            syncServiceUrl: configData.syncServiceUrl,
            breezApiKey: configData.breezApiKey,
            cacheDir: configData.cacheDir,
            zeroConfMaxAmountSat: nil,
            useDefaultExternalInputParsers: true,
            externalInputParsers: nil,
            onchainFeeRateLeewaySatPerVbyte: nil,
            assetMetadata: nil,
            sideswapApiKey: nil
        )

        // Connect to SDK
        let connectRequest = ConnectRequest(config: config, mnemonic: mnemonic)
        sdk = try connect(req: connectRequest)

        print("✅ NotificationService: SDK initialized successfully")
    }

    // MARK: - Webhook Parsing

    private func parseWebhookPayload(_ userInfo: [AnyHashable: Any]) throws -> WebhookPayload {
        // Extract webhook data from push notification payload
        guard let payloadData = userInfo["webhook_data"] as? [String: Any] else {
            throw NotificationError.invalidPayload
        }

        // Parse the webhook payload
        let jsonData = try JSONSerialization.data(withJSONObject: payloadData)
        let webhookPayload = try JSONDecoder().decode(WebhookPayload.self, from: jsonData)

        return webhookPayload
    }

    // MARK: - Payment Event Processing

    private func processPaymentEvent(_ webhookPayload: WebhookPayload, content: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        guard let sdk = sdk else {
            throw NotificationError.sdkNotInitialized
        }

        print("🔄 NotificationService: Processing payment event: \(webhookPayload.eventType)")

        switch webhookPayload.eventType {
        case .paymentReceived:
            return try await handlePaymentReceived(webhookPayload, content: content, sdk: sdk)
        case .paymentSent:
            return try await handlePaymentSent(webhookPayload, content: content, sdk: sdk)
        case .swapUpdated:
            return try await handleSwapUpdated(webhookPayload, content: content, sdk: sdk)
        default:
            // Generic payment notification
            content.title = "Lightning Payment"
            content.body = "Payment event received"
            return content
        }
    }

    private func handlePaymentReceived(_ payload: WebhookPayload, content: UNMutableNotificationContent, sdk: BindingLiquidSdk) async throws -> UNMutableNotificationContent {
        // Get updated wallet info
        let walletInfo = try sdk.getInfo()
        let balanceSats = walletInfo.walletInfo.balanceSat

        // Format the notification
        content.title = "⚡ Payment Received"

        if let amountSats = payload.amountSat {
            content.body = "Received \(amountSats) sats"
            content.subtitle = "Balance: \(balanceSats) sats"
        } else {
            content.body = "Lightning payment received"
            content.subtitle = "Balance: \(balanceSats) sats"
        }

        // Add sound and badge
        content.sound = .default
        content.badge = NSNumber(value: 1)

        // Add action buttons
        content.categoryIdentifier = "PAYMENT_RECEIVED"

        // Update shared container with sync time
        try SharedContainerManager.shared.updateLastSyncTime()

        print("✅ NotificationService: Payment received notification prepared")
        return content
    }

    private func handlePaymentSent(_ payload: WebhookPayload, content: UNMutableNotificationContent, sdk: BindingLiquidSdk) async throws -> UNMutableNotificationContent {
        // Get updated wallet info
        let walletInfo = try sdk.getInfo()
        let balanceSats = walletInfo.walletInfo.balanceSat

        // Format the notification
        content.title = "⚡ Payment Sent"

        if let amountSats = payload.amountSat {
            content.body = "Sent \(amountSats) sats"
            content.subtitle = "Balance: \(balanceSats) sats"
        } else {
            content.body = "Lightning payment sent"
            content.subtitle = "Balance: \(balanceSats) sats"
        }

        // Add sound
        content.sound = .default

        // Update shared container with sync time
        try SharedContainerManager.shared.updateLastSyncTime()

        print("✅ NotificationService: Payment sent notification prepared")
        return content
    }

    private func handleSwapUpdated(_ payload: WebhookPayload, content: UNMutableNotificationContent, sdk: BindingLiquidSdk) async throws -> UNMutableNotificationContent {
        content.title = "🔄 Swap Updated"
        content.body = "Bitcoin swap status changed"
        content.sound = .default

        // Update shared container with sync time
        try SharedContainerManager.shared.updateLastSyncTime()

        print("✅ NotificationService: Swap updated notification prepared")
        return content
    }
}

// MARK: - Data Models

struct WebhookPayload: Codable {
    let eventType: WebhookEventType
    let paymentId: String?
    let amountSat: UInt64?
    let timestamp: Date
    let swapId: String?
}

enum WebhookEventType: String, Codable {
    case paymentReceived = "payment_received"
    case paymentSent = "payment_sent"
    case swapUpdated = "swap_updated"
    case invoiceExpired = "invoice_expired"
}

enum NotificationError: Error {
    case invalidPayload
    case sdkNotInitialized
    case processingFailed

    var localizedDescription: String {
        switch self {
        case .invalidPayload:
            return "Invalid webhook payload"
        case .sdkNotInitialized:
            return "SDK not initialized"
        case .processingFailed:
            return "Failed to process notification"
        }
    }
}
