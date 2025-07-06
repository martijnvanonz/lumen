import Foundation
import SwiftUI

/// Manager for handling app localization and language switching
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language = .english
    
    /// Supported languages in the app
    enum Language: String, CaseIterable, Identifiable {
        case english = "en"
        case dutch = "nl"
        case french = "fr"
        case german = "de"
        case spanish = "es"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .dutch: return "Nederlands"
            case .french: return "Français"
            case .german: return "Deutsch"
            case .spanish: return "Español"
            }
        }
        
        var nativeName: String {
            switch self {
            case .english: return "English"
            case .dutch: return "Nederlands"
            case .french: return "Français"
            case .german: return "Deutsch"
            case .spanish: return "Español"
            }
        }
        
        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .dutch: return "🇳🇱"
            case .french: return "🇫🇷"
            case .german: return "🇩🇪"
            case .spanish: return "🇪🇸"
            }
        }
    }
    
    private init() {
        loadSavedLanguage()
    }
    
    /// Load the saved language preference from UserDefaults
    private func loadSavedLanguage() {
        let savedLanguageCode = UserDefaults.standard.string(forKey: "selected_language") ?? Language.english.rawValue
        currentLanguage = Language(rawValue: savedLanguageCode) ?? .english
        setAppLanguage(currentLanguage)
    }
    
    /// Set the app language and save preference
    func setLanguage(_ language: Language) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "selected_language")
        setAppLanguage(language)
        
        // Post notification for immediate UI updates
        NotificationCenter.default.post(name: .languageChanged, object: language)
    }
    
    /// Apply the language setting to the app
    private func setAppLanguage(_ language: Language) {
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    /// Get localized string for the current language
    func localizedString(for key: String, comment: String = "") -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to main bundle (English)
            return NSLocalizedString(key, comment: comment)
        }
        
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - Localization Helper Function

/// Global function for easy localization access
func L(_ key: String, comment: String = "") -> String {
    return LocalizationManager.shared.localizedString(for: key, comment: comment)
}

// MARK: - SwiftUI Environment

struct LocalizationEnvironmentKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localizationManager: LocalizationManager {
        get { self[LocalizationEnvironmentKey.self] }
        set { self[LocalizationEnvironmentKey.self] = newValue }
    }
}
