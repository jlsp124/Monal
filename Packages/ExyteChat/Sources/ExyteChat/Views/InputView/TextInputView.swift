//
//  Created by Alex.M on 14.06.2022.
//

import SwiftUI
import UniformTypeIdentifiers

struct TextInputView: View {
    
    @Environment(\.chatTheme) private var theme
    
    @EnvironmentObject private var globalFocusState: GlobalFocusState
    
    @Binding var text: String
    var inputFieldId: UUID
    var style: InputViewStyle
    var availableInputs: [AvailableInputType]
    var localization: ChatLocalization
    var onPasteImages: ([NSItemProvider]) -> Void = { _ in }
    
    var body: some View {
        TextField("", text: $text, prompt: Text(style == .message ? localization.inputPlaceholder : localization.signatureText)
            .foregroundColor(style == .message ? theme.colors.inputPlaceholderText : theme.colors.inputSignaturePlaceholderText), axis: .vertical)
            .customFocus($globalFocusState.focus, equals: .uuid(inputFieldId))
            .lineLimit(1...6)
            .onPasteCommand(of: [.image], perform: onPasteImages)
            .foregroundColor(style == .message ? theme.colors.inputText : theme.colors.inputSignatureText)
            .padding(.vertical, 10)
            .padding(.leading, !isAttachmentsAvailable() ? 12 : 0)
            .simultaneousGesture(
                TapGesture().onEnded {
                    globalFocusState.focus = .uuid(inputFieldId)
                }
            )
    }
    
    private func isAttachmentsAvailable() -> Bool {
        let attachmentTypes: [AvailableInputType] = [.media, .file, .staticLocation, .liveLocation]
        return attachmentTypes.contains { availableInputs.contains($0) }
    }
}

