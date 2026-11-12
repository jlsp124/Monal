import SwiftUI

struct ReactionSummary: Identifiable {
    var id: String { emoji }
    let emoji: String
    let count: Int
    let includesCurrentUser: Bool

    static func group(_ reactions: [Reaction]) -> [ReactionSummary] {
        Dictionary(grouping: reactions, by: { $0.type.toString }).map { emoji, items in
            ReactionSummary(emoji: emoji, count: Set(items.map { $0.user.id }).count, includesCurrentUser: items.contains { $0.user.isCurrentUser })
        }.sorted { $0.count == $1.count ? $0.emoji < $1.emoji : $0.count > $1.count }
    }
}

extension MessageView {
    func reactionsView(_ message: Message) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ReactionSummary.group(message.reactions)) { group in
                    Button {
                        viewModel.reactToEmoji(message, group.emoji)
                    } label: {
                        HStack(spacing: 4) {
                            Text(group.emoji)
                            Text(group.count.formatted()).font(.caption.monospacedDigit())
                        }
                        .foregroundStyle(theme.colors.mainText)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 44)
                        .background(group.includesCurrentUser ? theme.colors.mainTint.opacity(0.16) : theme.colors.messageFriendBG, in: Capsule())
                        .overlay { Capsule().strokeBorder(group.includesCurrentUser ? theme.colors.mainTint : .clear, lineWidth: 1) }
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canReactTo(message))
                    .accessibilityLabel(Text("\(group.emoji), \(group.count) reactions"))
                    .accessibilityValue(Text(group.includesCurrentUser ? "You reacted" : ""))
                    .accessibilityHint(Text(group.includesCurrentUser ? "Remove your reaction" : "Add your reaction"))
                }
            }
        }
    }
}
