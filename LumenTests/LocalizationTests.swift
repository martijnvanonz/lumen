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
        XCTAssertEqual(L("app_name"), "Lumen")
        XCTAssertEqual(L("send"), "Send")
        XCTAssertEqual(L("receive"), "Receive")
        XCTAssertEqual(L("settings"), "Settings")
        
        // Test Dutch
        localizationManager.setLanguage(.dutch)
        XCTAssertEqual(L("send"), "Versturen")
        XCTAssertEqual(L("receive"), "Ontvangen")
        XCTAssertEqual(L("settings"), "Instellingen")
        
        // Test French
        localizationManager.setLanguage(.french)
        XCTAssertEqual(L("send"), "Envoyer")
        XCTAssertEqual(L("receive"), "Recevoir")
        XCTAssertEqual(L("settings"), "Paramètres")
        
        // Test German
        localizationManager.setLanguage(.german)
        XCTAssertEqual(L("send"), "Senden")
        XCTAssertEqual(L("receive"), "Empfangen")
        XCTAssertEqual(L("settings"), "Einstellungen")
        
        // Test Spanish
        localizationManager.setLanguage(.spanish)
        XCTAssertEqual(L("send"), "Enviar")
        XCTAssertEqual(L("receive"), "Recibir")
        XCTAssertEqual(L("settings"), "Configuración")
    }
    
    func testPaymentStatusLocalization() throws {
        // Test English
        localizationManager.setLanguage(.english)
        XCTAssertEqual(L("pending"), "Pending")
        XCTAssertEqual(L("completed"), "Completed")
        XCTAssertEqual(L("failed"), "Failed")
        
        // Test Dutch
        localizationManager.setLanguage(.dutch)
        XCTAssertEqual(L("pending"), "In behandeling")
        XCTAssertEqual(L("completed"), "Voltooid")
        XCTAssertEqual(L("failed"), "Mislukt")
        
        // Test French
        localizationManager.setLanguage(.french)
        XCTAssertEqual(L("pending"), "En attente")
        XCTAssertEqual(L("completed"), "Terminé")
        XCTAssertEqual(L("failed"), "Échoué")
    }
    
    func testErrorMessageLocalization() throws {
        // Test English
        localizationManager.setLanguage(.english)
        XCTAssertEqual(L("insufficient_funds"), "Insufficient funds. You don't have enough sats for this payment.")
        XCTAssertEqual(L("network_error"), "Network error. Please check your internet connection and try again.")
        
        // Test Dutch
        localizationManager.setLanguage(.dutch)
        XCTAssertEqual(L("insufficient_funds"), "Onvoldoende saldo. Je hebt niet genoeg sats voor deze betaling.")
        XCTAssertEqual(L("network_error"), "Netwerkfout. Controleer je internetverbinding en probeer opnieuw.")
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
