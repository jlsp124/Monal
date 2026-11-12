import XCTest
@testable import ExyteChat

@MainActor
final class ScrollResizeTests: XCTestCase {
    private final class Rows: NSObject, UITableViewDataSource {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 80 }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            UITableViewCell(style: .default, reuseIdentifier: nil)
        }
    }

    private func table(_ rows: Rows, inverted: Bool = true) -> ChatTableView {
        let table = ChatTableView(frame: CGRect(x: 0, y: 0, width: 320, height: 600), style: .plain)
        table.isInvertedConversation = inverted
        table.contentInsetAdjustmentBehavior = .never
        table.rowHeight = 44
        table.estimatedRowHeight = 0
        table.dataSource = rows
        table.reloadData()
        table.layoutIfNeeded()
        table.contentOffset.y = 400
        table.layoutIfNeeded()
        return table
    }

    func testKeyboardOpeningPreservesVisualReadingPosition() {
        let rows = Rows()
        let view = table(rows)
        view.bounds.size.height = 350
        view.layoutIfNeeded()
        XCTAssertEqual(view.contentOffset.y, 650, accuracy: 1)
    }

    func testKeyboardClosingRestoresReadingPosition() {
        let rows = Rows()
        let view = table(rows)
        view.bounds.size.height = 350
        view.layoutIfNeeded()
        view.bounds.size.height = 600
        view.layoutIfNeeded()
        XCTAssertEqual(view.contentOffset.y, 400, accuracy: 1)
    }

    func testOrdinaryLayoutDoesNotScroll() {
        let rows = Rows()
        let view = table(rows)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        XCTAssertEqual(view.contentOffset.y, 400, accuracy: 1)
    }

    func testNonInvertedListKeepsOffsetWhenResized() {
        let rows = Rows()
        let view = table(rows, inverted: false)
        view.bounds.size.height = 350
        view.layoutIfNeeded()
        XCTAssertEqual(view.contentOffset.y, 400, accuracy: 1)
    }
}
