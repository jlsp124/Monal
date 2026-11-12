import UIKit

/// The conversation table is inverted. Keep the same content at the same visual
/// height when SwiftUI resizes it for the keyboard or a multiline composer.
final class ChatTableView: UITableView {
    var isInvertedConversation = false
    private var resizeAnchor: (offset: CGPoint, height: CGFloat)?

    override var bounds: CGRect {
        willSet {
            if bounds.height > 0, bounds.height != newValue.height, resizeAnchor == nil {
                resizeAnchor = (contentOffset, bounds.height)
            }
        }
    }

    override func layoutSubviews() {
        let anchor = resizeAnchor
        resizeAnchor = nil
        super.layoutSubviews()
        guard let anchor else { return }
        let minimum = -adjustedContentInset.top
        let maximum = max(minimum, contentSize.height - bounds.height + adjustedContentInset.bottom)
        let delta = isInvertedConversation ? anchor.height - bounds.height : 0
        let y = min(maximum, max(minimum, anchor.offset.y + delta))
        setContentOffset(CGPoint(x: anchor.offset.x, y: y), animated: false)
    }
}
