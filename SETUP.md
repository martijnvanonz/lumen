# Lumen Lightning Wallet Setup

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0 or later
- Breez API Key (see below)

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Lumen
```

### 2. Configure Environment Variables

1. Copy the example environment file:
   ```bash
   cp Lumen/.env.example Lumen/.env
   ```

2. Edit `Lumen/.env` and add your Breez API key:
   ```
   BREEZ_API_KEY=your_actual_breez_api_key_here
   ```

### 3. Get Your Breez API Key

To get a Breez API key:

1. Visit the [Breez SDK documentation](https://sdk-doc-liquid.breez.technology/)
2. Follow their API key registration process
3. Copy your API key to the `.env` file

**Important**: Never commit your `.env` file to version control. It contains sensitive API keys.

### 4. Build and Run

1. Open `Lumen.xcodeproj` in Xcode
2. Select your target device (iPhone with iOS 18.4+)
3. Build and run the project

## Features

- ⚡ Lightning Network payments via Breez SDK Liquid
- 🔐 Secure biometric authentication (Face ID/Touch ID)
- ☁️ Automatic iCloud Keychain backup
- 📱 Real-time payment notifications
- 🌐 Offline mode support
- 🛡️ Comprehensive error handling

## Security

- Mnemonic phrases are stored securely in iCloud Keychain
- Biometric authentication required for all wallet access
- No seed phrases are ever displayed to users
- API keys are stored in environment variables (not in code)

## Development

### Environment Configuration

The app supports multiple environments:

- `development` - For local development
- `staging` - For testing
- `production` - For production builds

Set the environment in your `.env` file:
```
ENVIRONMENT=development
```

### Network Configuration

Choose between mainnet and testnet:
```
LIQUID_NETWORK=mainnet  # or testnet
```

### Logging

Configure log levels:
```
LOG_LEVEL=info  # debug, info, warning, error
```

## Troubleshooting

### Common Issues

1. **"Breez API key is missing"**
   - Ensure you've copied `.env.example` to `.env`
   - Add your actual Breez API key to the `.env` file

2. **"Failed to initialize wallet"**
   - Check your internet connection
   - Verify your API key is valid
   - Check the logs for specific error details

3. **"Biometric authentication failed"**
   - Ensure Face ID/Touch ID is enabled on your device
   - Check device settings for biometric permissions

### Getting Help

If you encounter issues:

1. Check the console logs in Xcode
2. Verify your `.env` configuration
3. Ensure you're using a supported iOS version (18.4+)

## License

[Add your license information here]
