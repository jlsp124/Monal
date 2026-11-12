import XCTest
@testable import ExyteChat

final class EmojiPresentationTests: XCTestCase {
    func testEmojiGraphemesUseOneConsistentRule() {
        for value in ["😀", "❤️", "❤", "👍🏽", "👨‍👩‍👧‍👦", "🇨🇦", "1️⃣", "*️⃣", "🏳️‍🌈", "😀👍🏽🇨🇦", " 😀 "] {
            XCTAssertTrue(value.isShortEmojiMessage, value)
        }
    }
    func testOrdinaryTextAndExplicitTextPresentationStayOrdinary() {
        for value in ["", " ", "1", "123", "#", "*", "hello 😀", "😀😀😀😀", "❤︎", "a️"] {
            XCTAssertFalse(value.isShortEmojiMessage, value)
        }
    }
}
