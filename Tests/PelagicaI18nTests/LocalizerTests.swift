import XCTest
@testable import PelagicaI18n

final class LocalizerTests: XCTestCase {
    func testSupportedLanguages() throws {
        let languages = try Localizer.supportedLanguages()
        XCTAssertEqual(languages.first?.code, "en")
        XCTAssertTrue(languages.contains { $0.code == "pl" && $0.label == "Polski" })
    }

    func testPlainKeyAndNamespace() throws {
        let en = try Localizer(language: "en")
        XCTAssertEqual(en.t("cancel"), "Cancel")
        XCTAssertEqual(en.t("tracks_count", namespace: "music", count: 1), "1 track")
        XCTAssertEqual(en.t("music:tracks_count", count: 2), "2 tracks")
    }

    func testPolishPlurals() throws {
        let pl = try Localizer(language: "pl")
        XCTAssertEqual(pl.t("season_count", count: 1), "1 sezon")
        XCTAssertEqual(pl.t("season_count", count: 3), "3 sezony")
        XCTAssertEqual(pl.t("season_count", count: 5), "5 sezonów")
        XCTAssertEqual(pl.t("season_count", count: 22), "22 sezony")
    }

    func testRomanianPlurals() throws {
        let ro = try Localizer(language: "ro")
        XCTAssertEqual(ro.t("season_count", count: 1), "1 sezon")
        XCTAssertEqual(ro.t("season_count", count: 2), "2 sezoane")
        XCTAssertEqual(ro.t("season_count", count: 20), "20 de sezoane")
    }

    func testFallsBackToEnglish() throws {
        // ja has no music namespace
        let ja = try Localizer(language: "ja")
        XCTAssertEqual(ja.t("music:tracks_count", count: 3), "3 tracks")
    }

    func testFallsBackToCommonNamespace() throws {
        let en = try Localizer(language: "en")
        XCTAssertEqual(en.t("player:cancel"), "Cancel")
    }

    func testMissingKeyReturnsKey() throws {
        let en = try Localizer(language: "en")
        XCTAssertEqual(en.t("definitely_not_a_key"), "definitely_not_a_key")
    }

    func testNestedKeys() throws {
        let de = try Localizer(language: "de")
        XCTAssertEqual(de.t("player:equalizerPresets.flat"), "Neutral")
    }

    func testInterpolation() throws {
        let en = try Localizer(language: "en")
        XCTAssertEqual(en.t("ends_at", ["date": "20:15"]), "Ends at 20:15")
        XCTAssertEqual(en.t("ends_at"), "Ends at {{date}}")
    }

    func testRegionalLanguageResolvesToBase() throws {
        XCTAssertEqual(try Localizer(language: "pt-BR").language, "pt")
        XCTAssertEqual(try Localizer(preferredLanguages: ["xx-YY", "de-AT"]).language, "de")
        XCTAssertEqual(try Localizer(preferredLanguages: ["xx"]).language, "en")
    }

    func testUnsupportedLanguageThrows() {
        XCTAssertThrowsError(try Localizer(language: "xx")) { error in
            XCTAssertEqual(error as? LocalizerError, .unsupportedLanguage("xx"))
        }
    }
}
