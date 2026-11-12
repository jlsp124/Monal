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
            .setMessageFont(UIFontMetrics.default.scaledFont(for: .systemFont(ofSize: 15), compatibleWith: UITraitCollection(preferredContentSizeCategory: dark ? .extraExtraExtraLarge : .large)))
            .environment(\.colorScheme, dark ? .dark : .light)
            .environment(\.dynamicTypeSize, dark ? .xxxLarge : .large)
            .transaction { $0.disablesAnimations = true }
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

    func testCombinedChatLaysOutAndAppliesRapidUpdates() async throws {
        let me = User(id: "me", name: "You", isCurrentUser: true)
        let friend = User(id: "friend", name: "Alex", isCurrentUser: false)
        let fixture = ConversationFixture()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        defer { window.isHidden = true; window.rootViewController = nil }

        for dark in [false, true] {
            window.overrideUserInterfaceStyle = dark ? .dark : .light
            var initial: [Message] = []
            for i in 0..<16 {
                let user = i.isMultiple(of: 2) ? me : friend
                let status: Message.Status = i == 14 ? .queued : .sent
                let date = Date(timeIntervalSince1970: 1_800_000_000 + Double(i))
                let text = i == 15 ? "👨‍👩‍👧‍👦 🇨🇦 👍🏽" : "Message \(i). A native conversation with readable content."
                initial.append(Message(id: "\(i)", user: user, status: status, createdAt: date, text: text))
            }
            fixture.messages = initial
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
            // An unhosted package test cannot snapshot the simulator render server.
            // Render the actual SwiftUI message components directly; table layout and
            // updates are checked separately above/below. This is not an app screenshot.
            let params = MessageCustomizationParameters(linkPreviewLimit: 0, font: UIFontMetrics.default.scaledFont(for: .systemFont(ofSize: 15), compatibleWith: UITraitCollection(preferredContentSizeCategory: dark ? .extraExtraExtraLarge : .large)))
            let model = ChatViewModel()
            let content = VStack(spacing: 12) {
                ForEach(Array(fixture.messages.suffix(4))) { message in
                    MessageView(viewModel: model, message: message, positionInUserGroup: .single, positionInMessagesSection: .single, chatType: .conversation, params: params, isDisplayingMessageMenu: false)
                }
            }
            .padding(.vertical, 12)
            .frame(width: 393)
            .background(Color(uiColor: .systemBackground))
            .environment(\.chatSize, CGSize(width: 393, height: 1400))
            .environment(\.colorScheme, dark ? .dark : .light)
            .environment(\.dynamicTypeSize, dark ? .xxxLarge : .large)
            let renderer = ImageRenderer(content: content)
            renderer.scale = 2
            let image = try XCTUnwrap(renderer.uiImage)
            let pixels = try XCTUnwrap(image.cgImage?.dataProvider?.data) as Data
            let step = max(4, pixels.count / 15000 / 4 * 4)
            let colors = Set(stride(from: 0, to: pixels.count - 4, by: step).map { pixels.subdata(in: $0..<($0 + 4)) })
            XCTAssertGreaterThan(colors.count, 16, "A blank image cannot establish visual coverage")
            let attachment = XCTAttachment(image: image)
            attachment.name = dark ? "Message components dark large text" : "Message components light"
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
