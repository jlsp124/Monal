import SwiftUI

extension UIHostingConfiguration {
    func applyIf(_ condition: Bool, _ transform: (Self) -> Self) -> Self {
        condition ? transform(self) : self
    }
}
