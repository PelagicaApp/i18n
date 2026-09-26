import XCTest
@testable import PelagicaI18n

final class TaggedTextTests: XCTestCase {
    func testParsesTags() {
        XCTAssertEqual(
            TaggedText.parse("Results at <anchor>stats.pelagica.app</anchor>."),
            [.text("Results at "), .tag(name: "anchor", content: "stats.pelagica.app"), .text(".")]
        )
    }

    func testKeepsUnmatchedAngleBrackets() {
        XCTAssertEqual(TaggedText.parse("a < b <c"), [.text("a < b <c")])
        XCTAssertEqual(TaggedText.parse("<x>open"), [.text("<x>open")])
    }

    func testStrip() {
        XCTAssertEqual(TaggedText.strip("See <repoLink>GitHub</repoLink>"), "See GitHub")
    }
}
