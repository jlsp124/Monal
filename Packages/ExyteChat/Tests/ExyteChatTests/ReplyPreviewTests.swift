import XCTest
import SwiftUI
@testable import ExyteChat

final class ReplyPreviewTests: XCTestCase {
    func testOutgoingLinkColorDoesNotLeakIntoQuote() {
        var text = AttributedString("Read this link")
        text.foregroundColor = .white
        text.link = URL(string: "https://example.org")
        text.inlinePresentationIntent = .stronglyEmphasized
        let reply = ReplyMessage(id: "source", user: User(id: "me", name: "Me", isCurrentUser: true), createdAt: .now, attributedText: text)
        XCTAssertNil(reply.attributedText.foregroundColor)
        XCTAssertEqual(reply.attributedText.link, text.link)
        XCTAssertEqual(reply.attributedText.inlinePresentationIntent, .stronglyEmphasized)
        XCTAssertEqual(reply.text, "Read this link")
    }

    func testDecodedReplyKeepsReadableColorAndReference() throws {
        var text = AttributedString("Quote")
        text.foregroundColor = .white
        let original = ReplyMessage(id: "source", user: User(id: "me", name: "Me", isCurrentUser: true), createdAt: .now, attributedText: text)
        let decoded = try JSONDecoder().decode(ReplyMessage.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(decoded.id, "source")
        XCTAssertEqual(decoded.text, "Quote")
        XCTAssertNil(decoded.attributedText.foregroundColor)
    }
}
