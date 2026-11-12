import SwiftUI
import UniformTypeIdentifiers

extension InputView {
    var leftButton: some View {
        Menu {
            if isMediaAvailable() {
                Button { onAction(.photo) } label: { Label(localization.attachMediaText, systemImage: "photo.on.rectangle") }
                Button { onAction(.camera) } label: { Label(localization.attachCameraText, systemImage: "camera") }
                PasteButton(supportedContentTypes: [.image], payloadAction: viewModel.pasteImages)
            }
            if isFileAvailable() {
                Button { onAction(.file) } label: { Label(localization.attachFileText, systemImage: "doc") }
            }
            if isLocationAvailable() {
                Button { onAction(.location) } label: { Label(localization.attachLocationText, systemImage: "location") }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(theme.colors.mainTint)
                .frame(width: 44, height: 48)
        }
        .accessibilityLabel(Text("Add attachment"))
    }
}
