import XCTest
@testable import ExyteChat

final class ReactionSummaryTests: XCTestCase {
    func testCountsPeopleRatherThanDuplicateEventsAndMarksOwnReaction() {
        let me = User(id: "me", name: "Me", isCurrentUser: true)
        let other = User(id: "other", name: "Other", isCurrentUser: false)
        let groups = ReactionSummary.group([
            Reaction(user: me, type: .emoji("👍")),
            Reaction(user: me, type: .emoji("👍")),
            Reaction(user: other, type: .emoji("👍")),
            Reaction(user: other, type: .emoji("❤️"))
        ])
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups.first?.emoji, "👍")
        XCTAssertEqual(groups.first?.count, 2)
        XCTAssertTrue(groups.first?.includesCurrentUser == true)
        XCTAssertFalse(groups.last?.includesCurrentUser == true)
    }
}
