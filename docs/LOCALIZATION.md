# Lumen iOS App Localization Guide

## Overview

The Lumen Lightning wallet app now supports full internationalization (i18n) and localization for 5 languages:

- 🇺🇸 **English** (default/base language)
- 🇳🇱 **Dutch** (Nederlands)
- 🇫🇷 **French** (Français)
- 🇩🇪 **German** (Deutsch)
- 🇪🇸 **Spanish** (Español)

## Features

### ✅ Implemented Features

- **Language Selection**: Users can change language in Settings → Language
- **Immediate Switching**: Language changes apply instantly without app restart
- **Persistent Settings**: Language preference saved in UserDefaults
- **Comprehensive Coverage**: 200+ localized strings covering all UI elements
- **Proper Formatting**: Support for dynamic content (amounts, counts, etc.)

### 🎯 Localized Components

- Navigation titles and toolbar buttons
- Send/Receive payment flows
- Payment history and status messages
- Error messages and alerts
- Settings screen and options
- Onboarding flow
- Wallet information displays
- Bitcoin Places features
- Refund/money recovery flow

## Architecture

### LocalizationManager

The `LocalizationManager` class handles all localization logic:

```swift
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    @Published var currentLanguage: Language = .english
    
    func setLanguage(_ language: Language)
    func localizedString(for key: String, comment: String = "") -> String
}
```

### Language Enum

```swift
enum Language: String, CaseIterable {
    case english = "en"
    case dutch = "nl" 
    case french = "fr"
    case german = "de"
    case spanish = "es"
    
    var displayName: String { /* localized display name */ }
    var nativeName: String { /* native language name */ }
    var flag: String { /* flag emoji */ }
}
```

### Helper Function

Global localization function for easy access:

```swift
func L(_ key: String, comment: String = "") -> String {
    return LocalizationManager.shared.localizedString(for: key, comment: comment)
}
```

## Usage

### Basic String Localization

Replace hardcoded strings with localized versions:

```swift
// Before
Text("Send")

// After  
Text(L("send"))
```

### Dynamic Content

For strings with dynamic content, use String formatting:

```swift
// Before
Text("Enter your \(wordCount)-word recovery phrase")

// After
Text(String(format: L("enter_recovery_phrase"), wordCount))
```

### Pluralization

Handle plural forms properly:

```swift
let pluralSuffix = count == 1 ? L("place_singular") : L("place_plural")
let message = String(format: L("places_near_you"), count, pluralSuffix)
```

## File Structure

```
Lumen/
├── Utils/
│   └── LocalizationManager.swift
├── en.lproj/
│   └── Localizable.strings
├── nl.lproj/
│   └── Localizable.strings  
├── fr.lproj/
│   └── Localizable.strings
├── de.lproj/
│   └── Localizable.strings
└── es.lproj/
    └── Localizable.strings
```

## String Categories

### Navigation & UI
- `app_name`, `settings`, `done`, `cancel`, `ok`, `retry`

### Wallet Operations  
- `send`, `receive`, `balance`, `payment_history`

### Payment States
- `pending`, `completed`, `failed`, `sent`, `received`

### Error Messages
- `insufficient_funds`, `network_error`, `invalid_payment`

### Onboarding
- `welcome_to_lumen`, `start_using_lumen`, `import_wallet`

### Bitcoin Places
- `find_bitcoin_places`, `location_required`, `enable_location`

## Adding New Strings

1. **Add to English base file** (`en.lproj/Localizable.strings`):
```
"new_feature_title" = "New Feature";
"new_feature_description" = "Description of the new feature";
```

2. **Translate to all languages** in respective `.lproj` folders

3. **Use in code**:
```swift
Text(L("new_feature_title"))
Text(L("new_feature_description"))
```

## Testing

Run the localization tests to verify implementation:

```bash
xcodebuild test -scheme Lumen -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage

- Language selection and switching
- String localization across all languages  
- UserDefaults persistence
- Display names and flag emojis
- Error message translations

## Best Practices

### ✅ Do's

- Always use `L()` function for user-facing strings
- Test all languages during development
- Use descriptive string keys (e.g., `payment_failed` not `error1`)
- Handle pluralization properly
- Keep translations contextually appropriate

### ❌ Don'ts

- Don't hardcode user-facing strings
- Don't assume text length will be the same across languages
- Don't use technical terms in user-facing messages
- Don't forget to update all language files when adding new strings

## Language-Specific Notes

### Dutch (Nederlands)
- Longer compound words may affect UI layout
- Formal vs informal address (using informal "je/jij")

### French (Français)  
- Accented characters properly supported
- Gender agreements in translations

### German (Deutsch)
- Compound words and capitalization rules followed
- Formal address used ("Sie" forms)

### Spanish (Español)
- International Spanish (not region-specific)
- Proper accent marks and ñ character support

## Future Enhancements

### Potential Additions
- Right-to-left language support (Arabic, Hebrew)
- Regional variants (US English vs UK English)
- Currency formatting per locale
- Date/time formatting per locale
- Number formatting per locale

### Maintenance
- Regular translation reviews
- User feedback integration
- Professional translation services for accuracy
- Automated translation validation

## Support

For localization issues or translation improvements:
1. Check existing string keys in `Localizable.strings` files
2. Verify `LocalizationManager` integration
3. Test language switching functionality
4. Run localization test suite
5. Submit issues with specific language/string details
