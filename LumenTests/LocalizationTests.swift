import XCTest
@testable import Lumen

final class LocalizationTests: XCTestCase {
    
    var localizationManager: LocalizationManager!
    
    override func setUpWithError() throws {
        localizationManager = LocalizationManager.shared
    }
    
    override func tearDownWithError() throws {
        localizationManager = nil
    }
    
    func testLanguageSelection() throws {
        // Test setting different languages
        localizationManager.setLanguage(.english)
        XCTAssertEqual(localizationManager.currentLanguage, .english)
        
        localizationManager.setLanguage(.dutch)
        XCTAssertEqual(localizationManager.currentLanguage, .dutch)
        
        localizationManager.setLanguage(.french)
        XCTAssertEqual(localizationManager.currentLanguage, .french)
        
        localizationManager.setLanguage(.german)
        XCTAssertEqual(localizationManager.currentLanguage, .german)
        
        localizationManager.setLanguage(.spanish)
        XCTAssertEqual(localizationManager.currentLanguage, .spanish)
    }
    
    func testLanguageDisplayNames() throws {
        XCTAssertEqual(LocalizationManager.Language.english.displayName, "English")
        XCTAssertEqual(LocalizationManager.Language.dutch.displayName, "Nederlands")
        XCTAssertEqual(LocalizationManager.Language.french.displayName, "Français")
        XCTAssertEqual(LocalizationManager.Language.german.displayName, "Deutsch")
        XCTAssertEqual(LocalizationManager.Language.spanish.displayName, "Español")
    }
    
    func testLanguageFlags() throws {
        XCTAssertEqual(LocalizationManager.Language.english.flag, "🇺🇸")
        XCTAssertEqual(LocalizationManager.Language.dutch.flag, "🇳🇱")
        XCTAssertEqual(LocalizationManager.Language.french.flag, "🇫🇷")
        XCTAssertEqual(LocalizationManager.Language.german.flag, "🇩🇪")
        XCTAssertEqual(LocalizationManager.Language.spanish.flag, "🇪🇸")
    }
    
    func testBasicLocalization() throws {
        // Test English
        localizationManager.setLanguage(.english)
        XCTAssertEqual(L("Lumen"), "Lumen")
        XCTAssertEqual(L("Send"), "Send")
        XCTAssertEqual(L("Receive"), "Receive")
        XCTAssertEqual(L("Settings"), "Settings")

        // Test Dutch
        localizationManager.setLanguage(.dutch)
        XCTAssertEqual(L("Send"), "Versturen")
        XCTAssertEqual(L("Receive"), "Ontvangen")
        XCTAssertEqual(L("Settings"), "Instellingen")

        // Test French
        localizationManager.setLanguage(.french)
        XCTAssertEqual(L("Send"), "Envoyer")
        XCTAssertEqual(L("Receive"), "Recevoir")
        XCTAssertEqual(L("Settings"), "Paramètres")

        // Test German
        localizationManager.setLanguage(.german)
        XCTAssertEqual(L("Send"), "Senden")
        XCTAssertEqual(L("Receive"), "Empfangen")
        XCTAssertEqual(L("Settings"), "Einstellungen")

        // Test Spanish
        localizationManager.setLanguage(.spanish)
        XCTAssertEqual(L("Send"), "Enviar")
        XCTAssertEqual(L("Receive"), "Recibir")
        XCTAssertEqual(L("Settings"), "Configuración")
    }
    
    func testPaymentStatusLocalization() throws {
        // Test English
        localizationManager.setLanguage(.english)
        XCTAssertEqual(L("Pending"), "Pending")
        XCTAssertEqual(L("Completed"), "Completed")
        XCTAssertEqual(L("Failed"), "Failed")

        // Test Dutch
        localizationManager.setLanguage(.dutch)
        XCTAssertEqual(L("Pending"), "In behandeling")
        XCTAssertEqual(L("Completed"), "Voltooid")
        XCTAssertEqual(L("Failed"), "Mislukt")

        // Test French
        localizationManager.setLanguage(.french)
        XCTAssertEqual(L("Pending"), "En attente")
        XCTAssertEqual(L("Completed"), "Terminé")
        XCTAssertEqual(L("Failed"), "Échoué")
    }
    
    func testErrorMessageLocalization() throws {
        // Test English
        localizationManager.setLanguage(.english)
        XCTAssertEqual(L("Insufficient funds. You don't have enough sats for this payment."), "Insufficient funds. You don't have enough sats for this payment.")
        XCTAssertEqual(L("Network error. Please check your internet connection and try again."), "Network error. Please check your internet connection and try again.")

        // Test Dutch
        localizationManager.setLanguage(.dutch)
        XCTAssertEqual(L("Insufficient funds. You don't have enough sats for this payment."), "Onvoldoende saldo. Je hebt niet genoeg sats voor deze betaling.")
        XCTAssertEqual(L("Network error. Please check your internet connection and try again."), "Netwerkfout. Controleer je internetverbinding en probeer opnieuw.")
    }
    
    func testUserDefaultsPersistence() throws {
        // Test that language selection persists
        localizationManager.setLanguage(.german)
        
        // Check UserDefaults
        let savedLanguage = UserDefaults.standard.string(forKey: "selected_language")
        XCTAssertEqual(savedLanguage, "de")
        
        // Create new instance to test loading
        let newManager = LocalizationManager()
        XCTAssertEqual(newManager.currentLanguage, .german)
    }
}
