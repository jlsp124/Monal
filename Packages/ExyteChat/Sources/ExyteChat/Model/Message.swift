//
//  Message.swift
//  Chat
//
//  Created by Alisa Mylnikova on 20.04.2022.
//

import SwiftUI

open class Message: ObservableObject, Identifiable {

    public enum Status: Equatable, Hashable, Sendable {
        case sending
        case sent
        case received
        case readBy([String]) // user ids
        case error(DraftMessage)

        public func hash(into hasher: inout Hasher) {
            switch self {
            case .sending:
                return hasher.combine("sending")
            case .sent:
                return hasher.combine("sent")
            case .received:
                return hasher.combine("received")
            case .readBy:
                return hasher.combine("read")
            case .error:
                return hasher.combine("error")
            }
        }

        public static func == (lhs: Message.Status, rhs: Message.Status) -> Bool {
            switch (lhs, rhs) {
            case (.sending, .sending):
                return true
            case (.sent, .sent):
                return true
            case (.received, .received):
                return true
            case (.readBy(let r1), .readBy(let r2)):
                return r1 == r2
            case ( .error(_), .error(_)):
                return true
            default:
                return false
            }
        }
    }

    @Published public var id: String
    @Published open var user: User
    @Published open var status: Status?
    @Published open var createdAt: Date
    @Published open var encrypted: Bool = false

    @Published open var attributedText: AttributedString
    @Published open var attachments: [Attachment]
    @Published open var files: [File]
    @Published open var reactions: [Reaction]
    @Published open var staticLocation: StaticLocation?
    @Published open var liveLocation: LiveLocation?
    @Published open var recording: Recording?
    @Published open var replyMessage: ReplyMessage?
    @Published open var customData: [String: any Sendable]

    @Published public var triggerRedraw: UUID?

    open var hasText: Bool {
        !attributedText.characters.isEmpty
    }

    open var text: String {
        String(attributedText.characters)
    }

    public init(
        id: String,
        user: User,
        status: Status? = nil,
        createdAt: Date = Date(),
        text: String = "",
        attachments: [Attachment] = [],
        files: [File] = [],
        staticLocation: StaticLocation? = nil,
        liveLocation: LiveLocation? = nil,
        reactions: [Reaction] = [],
        recording: Recording? = nil,
        replyMessage: ReplyMessage? = nil,
        customData: [String: any Sendable] = [:]
    ) {
        self.id = id
        self.user = user
        self.status = status
        self.createdAt = createdAt
        self.attributedText = text.applyDefaultAttributes()
        self.attachments = attachments
        self.files = files
        self.staticLocation = staticLocation
        self.liveLocation = liveLocation
        self.reactions = reactions
        self.recording = recording
        self.replyMessage = replyMessage
        self.customData = customData
    }

    public init(
        id: String,
        user: User,
        status: Status? = nil,
        createdAt: Date = Date(),
        attributedText: AttributedString,
        attachments: [Attachment] = [],
        files: [File] = [],
        staticLocation: StaticLocation? = nil,
        liveLocation: LiveLocation? = nil,
        reactions: [Reaction] = [],
        recording: Recording? = nil,
        replyMessage: ReplyMessage? = nil,
        customData: [String: any Sendable] = [:]
    ) {
        self.id = id
        self.user = user
        self.status = status
        self.createdAt = createdAt
        self.attributedText = attributedText
        self.attachments = attachments
        self.files = files
        self.staticLocation = staticLocation
        self.liveLocation = liveLocation
        self.reactions = reactions
        self.recording = recording
        self.replyMessage = replyMessage
        self.customData = customData
    }

    public static func makeMessage(
        id: String,
        user: User,
        status: Status? = nil,
        draft: DraftMessage
    ) async -> Message {
        let attachments = await draft.medias.asyncCompactMap { media -> Attachment? in
            guard let thumbnailURL = await media.getThumbnailURL() else {
                return nil
            }

            switch media.type {
            case .image:
                return Attachment(id: UUID().uuidString, url: thumbnailURL, type: .image)
            case .video:
                guard let fullURL = await media.getURL() else {
                    return nil
                }
                return Attachment(id: UUID().uuidString, thumbnail: thumbnailURL, full: fullURL, type: .video)
            }
        }

        return Message(
            id: id,
            user: user,
            status: status,
            createdAt: draft.createdAt,
            text: draft.text,
            attachments: attachments,
            files: draft.files,
            staticLocation: draft.staticLocation,
            liveLocation: draft.liveLocation,
            recording: draft.recording,
            replyMessage: draft.replyMessage
        )
    }
}

extension Message {
    var formattedDate: String {
        DateFormatter.timeFormatter.string(from: createdAt)
    }
}

extension Message: Equatable {
    public static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.user == rhs.user &&
        lhs.status == rhs.status &&
        lhs.createdAt == rhs.createdAt &&
        lhs.attributedText == rhs.attributedText &&
        lhs.staticLocation == rhs.staticLocation &&
        lhs.liveLocation == rhs.liveLocation &&
        lhs.attachments == rhs.attachments &&
        lhs.files == rhs.files &&
        lhs.reactions == rhs.reactions &&
        lhs.recording == rhs.recording &&
        lhs.replyMessage == rhs.replyMessage &&
        lhs.triggerRedraw == rhs.triggerRedraw
    }
}

extension Message: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.user)
        hasher.combine(self.status)
        hasher.combine(self.createdAt)
        hasher.combine(self.attributedText)
        hasher.combine(self.attachments)
        hasher.combine(self.files)
        hasher.combine(self.recording)
        hasher.combine(self.replyMessage)
    }
}

// Keep `Recording` a struct, to avoid a bug where the displayed time in the
// audio recorder doesn't get updated unless the user presses one of the buttons
public struct Recording: Codable, Hashable, Sendable {
    public var duration: Double
    public var waveformSamples: [CGFloat]
    public var url: URL?
    public var mimeType: String?

    public init(duration: Double = 0.0, waveformSamples: [CGFloat] = [], url: URL? = nil, mimeType: String? = nil) {
        self.duration = duration
        self.waveformSamples = waveformSamples
        self.url = url
        self.mimeType = mimeType
    }
}

public class ReplyMessage: ObservableObject, Codable, Identifiable {
    private enum CodingKeys: CodingKey {
        case id
        case user
        case createdAt
        case attributedText
        case attachments
        case files
        case recording
    }

    @Published public var id: String
    @Published public var user: User
    @Published public var createdAt: Date

    @Published public var attributedText: AttributedString
    @Published public var attachments: [Attachment]
    @Published public var files: [File]
    @Published public var recording: Recording?

    public var text: String {
        String(attributedText.characters)
    }

    public init(
        id: String,
        user: User,
        createdAt: Date,
        text: String = "",
        attachments: [Attachment] = [],
        files: [File] = [],
        recording: Recording? = nil
    ) {
        self.id = id
        self.user = user
        self.createdAt = createdAt
        self.attributedText = text.applyDefaultAttributes()
        self.attachments = attachments
        self.files = files
        self.recording = recording
    }

    public init(
        id: String,
        user: User,
        createdAt: Date,
        attributedText: AttributedString,
        attachments: [Attachment] = [],
        files: [File] = [],
        recording: Recording? = nil
    ) {
        self.id = id
        self.user = user
        self.createdAt = createdAt
        self.attributedText = attributedText
        self.attachments = attachments
        self.files = files
        self.recording = recording
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        user = try container.decode(User.self, forKey: .user)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        attributedText = try container.decode(AttributedString.self, forKey: .attributedText)
        attachments = try container.decode([Attachment].self, forKey: .attachments)
        files = try container.decode([File].self, forKey: .files)
        recording = try container.decode(Recording?.self, forKey: .recording)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(user, forKey: .user)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(attributedText, forKey: .attributedText)
        try container.encode(attachments, forKey: .attachments)
        try container.encode(files, forKey: .files)
        try container.encode(recording, forKey: .recording)
    }

    func toMessage() -> Message {
        Message(id: id, user: user, createdAt: createdAt, attributedText: attributedText, attachments: attachments, files: files, recording: recording)
    }
}

extension ReplyMessage: Equatable {
    public static func == (lhs: ReplyMessage, rhs: ReplyMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.user == rhs.user &&
        lhs.createdAt == rhs.createdAt &&
        lhs.attributedText == rhs.attributedText &&
        lhs.attachments == rhs.attachments &&
        lhs.files == rhs.files &&
        lhs.recording == rhs.recording
    }
}

extension ReplyMessage: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.user)
        hasher.combine(self.createdAt)
        hasher.combine(self.attributedText)
        hasher.combine(self.attachments)
        hasher.combine(self.files)
        hasher.combine(self.recording)
    }
}

public extension Message {
    func toReplyMessage() -> ReplyMessage {
        ReplyMessage(id: id, user: user, createdAt: createdAt, attributedText: attributedText, attachments: attachments, files: files, recording: recording)
    }
}
