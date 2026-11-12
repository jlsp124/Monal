//
//  Created by Alex.M on 20.06.2022.
//

import SwiftUI
import SVGView

struct AttachmentsPage: View {

    @EnvironmentObject var mediaPagesViewModel: FullscreenMediaPagesViewModel
    @Environment(\.chatTheme) private var theme

    let attachment: Attachment

    var body: some View {
        if let mimeType = attachment.mimeType, mimeType.starts(with: "image/svg") {
            SVGView(contentsOf: attachment.full)
        } else if attachment.type == .image {
            ZoomableContainer {
                AsyncImage(url: attachment.full) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ActivityIndicator()
                }
            }
        } else if attachment.type == .video {
            VideoView(viewModel: VideoViewModel(attachment: attachment))
        } else {
            Rectangle()
                .foregroundColor(Color.gray)
                .frame(minWidth: 100, minHeight: 100)
                .frame(maxHeight: 200)
                .overlay {
                    Text("Unknown", bundle: .module)
                }
        }
    }
}
