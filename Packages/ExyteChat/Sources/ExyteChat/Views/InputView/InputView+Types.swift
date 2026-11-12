//
//  InputView+Types.swift
//  Chat
//

import SwiftUI
import ExyteMediaPicker

public enum InputViewStyle: Sendable {
    case message
    case signature
}

public enum AudioRecordingMode: Sendable {
    /// Default: hold the mic button to record; slide up to lock into hands-free mode.
    case holdToRecord
    /// Tap the mic button once to start recording, tap the stop button to finish. No lock capsule.
    case tapToToggle
}

public enum InputViewAction: Sendable {
    case photo
    case file
    case add
    case camera
    case send

    case recordAudioHold
    case recordAudioTap
    case recordAudioLock
    case stopRecordAudio
    case deleteRecord
    case playRecord
    case pauseRecord
    case location

    case saveEdit
    case cancelEdit
}

public enum InputViewState: Sendable {
    case empty
    case hasTextOrMedia

    case waitingForRecordingPermission
    case isRecordingHold
    case isRecordingTap
    case hasRecording
    case playingRecording
    case pausedRecording

    case editing

    var canSend: Bool {
        switch self {
        case .hasTextOrMedia, .hasRecording, .isRecordingTap, .playingRecording, .pausedRecording: return true
        default: return false
        }
    }
}

public enum AvailableInputType: Sendable {
    case text
    case media
    /// Enables sharing a single, fixed location.
    case staticLocation
    /// Enables sharing a live, continuously-updating location.
    case liveLocation
    case audio
    case file
}

public struct InputViewAttachments {
    var files: [URL] = []
    var medias: [Media] = []
    var staticLocation: StaticLocation?
    var liveLocation: LiveLocation?
    var recording: Recording?
    var replyMessage: ReplyMessage?
}
