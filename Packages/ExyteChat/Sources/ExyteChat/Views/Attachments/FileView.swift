//
//  Created by lissine on 05.05.2026.
//

import SwiftUI
import QuickLook
import System

public struct FileView: View {
    @Environment(\.chatLocalization) var localization
    @State private var isChecking = false
    @State private var isDownloading = false
    @State private var previewURL: URL?
    let file: File
    let messageParams: MessageCustomizationParameters

    var humanReadableSize: String {
        if file.size != nil {
            return file.size!.formatted(.byteCount(style: .file))
        }
        return localization.unknownSize
    }

    // Base on the mimeType, and fall back to basing on the file extension
    var localizedFileType: String {
        if let mimeType = file.mimeType,
            mimeType != "application/octet-stream",
            let utType = UTType(mimeType: mimeType),
            let localizedDescription = utType.localizedDescription {
            return localizedDescription
        }

        let fileExtension = (file.name as NSString).pathExtension
        if let utType = UTType(filenameExtension: fileExtension),
            let localizedDescription = utType.localizedDescription {
            return localizedDescription
        }

        return localization.unknownFileType
    }

    var imageName: String {
        switch(file.downloadState) {
            case .none:
                return "info"
            case .headers:
                return "arrow.down"
            case .complete:
                return "document"
        }
    }

    func buttonAction() {
        switch(file.downloadState) {
            case .none:
                messageParams.checkFileSizeClosure?(file)
                isChecking = true
            case .headers:
                messageParams.downloadFileClosure?(file)
                isDownloading = true
            case .complete:
                openFile()
        }
    }

    // Creates a temporary hardlink, in order to have the file extension (and name) on the hardlink.
    // This allows QuickLook to preview it correctly
    // (the downloaded files in Monal have a hash as their name and extension)
    func openFile() {
        // Monal will cleanup any hardlinks that didn't get deleted normally
        // e.g. due to a force-close while the preview is open
        guard let filePreviewsDirectory = messageParams.filePreviewHardlinksDirectory else { return }
        try? FileManager.default.createDirectory(
            atPath: filePreviewsDirectory,
            withIntermediateDirectories: true
        )

        let basePath = FilePath(filePreviewsDirectory)
        let sanitizedFilename = file.name.sanitizedFilename()
        guard let safePath = basePath.lexicallyResolving(FilePath(sanitizedFilename)),
            safePath != basePath else {
            // traversal attempt
            return
        }
        let tempURL = URL(fileURLWithPath: safePath.string)

        try? FileManager.default.removeItem(at: tempURL)
        do {
            try FileManager.default.linkItem(at: file.localURL!, to: tempURL)
            previewURL = tempURL
        } catch {
            print("Hardlinking failed: \(error)")
        }
    }

    public var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                Image(systemName: imageName)
                    .foregroundStyle(Color(.secondarySystemBackground))
                if file.downloadState == .none && isChecking || file.downloadState == .headers && isDownloading {
                    CircularProgress(size: 35, color: Color(.secondarySystemBackground))
                }
            }
            .frame(width: 40)
            .padding(.leading, 3)
            .padding(.trailing, 4)

            VStack(alignment: .leading) {
                Text(file.name)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    // Reserve vertical space for two lines
                    .fixedSize(horizontal: false, vertical: true)
                Text(localizedFileType)
                    .font(.caption2)
                Text(humanReadableSize)
                    .font(.caption2)
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture(perform: buttonAction)
        .onAppear {
            // file.isBeingDownloaded is true both when checking and when downloading
            isChecking = file.isBeingDownloaded
            isDownloading = file.isBeingDownloaded
        }
        .quickLookPreview($previewURL)
        .onChange(of: previewURL) { oldValue, newValue in
            if newValue == nil {
                // Delete the hardlink
                try? FileManager.default.removeItem(at: oldValue!)
            }
        }
    }
}
