import UIKit
func windowSize() -> CGSize {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows)
        .first { $0.isKeyWindow }?
        .frame.size
        ?? CGSize.zero
}
