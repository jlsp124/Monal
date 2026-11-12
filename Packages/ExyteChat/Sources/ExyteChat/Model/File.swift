//
//  Created by lissine on 05.05.2026.
//

import Foundation

public enum FileDownloadState: Codable {
    case none
    case headers
    case complete
}

public struct File: Identifiable, Hashable, Codable {
    public let id: String
    public let thumbnail: URL?
    public let localURL: URL?
    public let name: String
    public let downloadState: FileDownloadState
    public let isBeingDownloaded: Bool
    public let mimeType: String?
    public let size: Int?

    public init(id: String, thumbnail: URL? = nil, localURL: URL?, name: String, downloadState: FileDownloadState, isBeingDownloaded: Bool = false, mimeType: String? = nil, size: Int? = nil) {
        self.id = id
        self.thumbnail = thumbnail
        self.localURL = localURL
        self.name = name
        self.downloadState = downloadState
        self.isBeingDownloaded = isBeingDownloaded
        self.mimeType = mimeType
        self.size = size
    }
}
