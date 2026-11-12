import XCTest
import SwiftUI
@testable import ExyteChat

@MainActor
private final class ConversationFixture: ObservableObject {
    @Published var messages: [Message] = []
}

@MainActor
private struct ConversationTestView: View {
    @ObservedObject var fixture: ConversationFixture
    let dark: Bool
    var body: some View {
        ChatView<DummyView, DummyView, DefaultMessageMenuAction>(messages: fixture.messages, didSendMessage: { _ in })
            .setAvailableInputs([.text, .audio, .media, .file, .staticLocation])
            .audioRecordingMode(.tapToToggle)
            .photoPickerBackend(.system)
            .automaticallyScrollOnSend(false)
            .onMessageReaction(didReactTo: { _, _ in })
            .environment(\.colorScheme, dark ? .dark : .light)
            .environment(\.dynamicTypeSize, dark ? .xxxLarge : .large)
            .environment(\.accessibilityReduceMotion, true)
    }
}

@MainActor
final class ChatRenderingTests: XCTestCase {
    private func findTable(_ view: UIView) -> UITableView? {
        if let table = view as? ChatTableView { return table }
        return view.subviews.lazy.compactMap(findTable).first
    }

    private func waitForRows(_ count: Int, in host: UIViewController) async throws -> UITableView {
        for _ in 0..<100 {
            host.view.layoutIfNeeded()
            if let table = findTable(host.view), (0..<table.numberOfSections).reduce(0, { $0 + table.numberOfRows(inSection: $1) }) == count {
                return table
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Native table did not apply the expected \(count) messages")
        throw NSError(domain: "ChatRenderingTests", code: 1)
    }

    func testCombinedChatRendersAndAppliesRapidUpdates() async throws {
        let me = User(id: "me", name: "You", isCurrentUser: true)
        let friend = User(id: "friend", name: "Alex", isCurrentUser: false)
        let fixture = ConversationFixture()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        defer { window.isHidden = true; window.rootViewController = nil }

        for dark in [false, true] {
            fixture.messages = (0..<16).map { i in
                Message(id: "\(i)", user: i.isMultiple(of: 2) ? me : friend, status: i == 14 ? .queued : .sent, createdAt: Date(timeIntervalSince1970: 1_800_000_000 + Double(i)), text: i == 15 ? "👨‍👩‍👧‍👦 🇨🇦 👍🏽" : "Message \(i). A native conversation with readable content.")
            }
            let source = fixture.messages[12]
            var linkedQuote = source.attributedText
            linkedQuote.foregroundColor = .white
            linkedQuote.link = URL(string: "https://example.org")
            fixture.messages[14].replyMessage = ReplyMessage(id: source.id, user: me, createdAt: source.createdAt, attributedText: linkedQuote)
            fixture.messages[14].reactions = [Reaction(user: me, type: .emoji("👍"), status: .sent), Reaction(user: friend, type: .emoji("👍"), status: .sent)]
            let host = UIHostingController(rootView: ConversationTestView(fixture: fixture, dark: dark))
            window.rootViewController = host
            window.makeKeyAndVisible()
            let table = try await waitForRows(16, in: host)
            XCTAssertFalse(table.visibleCells.isEmpty)
            try await Task.sleep(nanoseconds: 200_000_000)
            let image = UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true) }
            let attachment = XCTAttachment(image: image)
            attachment.name = dark ? "Chat dark large text" : "Chat light"
            attachment.lifetime = .keepAlways
            add(attachment)

            for i in 16..<56 {
                fixture.messages.append(Message(id: "\(i)", user: friend, createdAt: Date(timeIntervalSince1970: 1_800_000_000 + Double(i)), text: "Incoming \(i)"))
            }
            _ = try await waitForRows(56, in: host)
            XCTAssertEqual(fixture.messages.map(\.id), (0..<56).map(String.init))
            window.rootViewController = nil
        }
    }
}
