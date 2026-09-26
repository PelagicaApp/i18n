import Foundation
import XCTest
@testable import PelagicaI18n

final class PluralRulesTests: XCTestCase {
    /// Fixtures come from Intl.PluralRules (what i18next uses) via `pnpm generate:fixtures`, so both platforms must agree
    func testMatchesIntlPluralRules() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Fixtures/plural-rules", withExtension: "json"))
        let fixtures = try JSONDecoder().decode([String: [String: String]].self, from: Data(contentsOf: url))
        XCTAssertFalse(fixtures.isEmpty)

        for (language, samples) in fixtures {
            for (number, expected) in samples {
                let n = try XCTUnwrap(Int(number))
                XCTAssertEqual(
                    PluralRules.category(for: n, language: language).rawValue, expected,
                    "\(language) \(n)"
                )
            }
        }
    }

    func testEveryLanguageHasFixtures() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Fixtures/plural-rules", withExtension: "json"))
        let fixtures = try JSONDecoder().decode([String: [String: String]].self, from: Data(contentsOf: url))
        let codes = try Localizer.supportedLanguages().map(\.code)
        XCTAssertEqual(Set(fixtures.keys), Set(codes), "Run `pnpm generate:fixtures`")
    }
}
