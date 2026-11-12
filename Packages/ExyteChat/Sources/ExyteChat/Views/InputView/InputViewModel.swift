//
//  Created by Alex.M on 20.06.2022.
//

import Foundation
import Combine
import ExyteMediaPicker
import SwiftUI
@preconcurrency import AVFoundation

@MainActor
final class InputViewModel: ObservableObject {

    @Published var text = ""
    @Published var attachments = InputViewAttachments()
    @Published var state: InputViewState = .empty

    @Published var showFilePicker = false
    @Published var showMediaPicker = false
    @Published var showLocationPicker = false

    @Published var mediaPickerMode = MediaPickerMode.photos

    @Published var showActivityIndicator = false
    @Published var recordingError: String?

    var recordingPlayer: RecordingPlayer?
    var didSendMessage: ((DraftMessage) -> Void)?

    private let recorder: any AudioRecording
    private var recordingGeneration = UUID()
    private var recordingTask: Task<Void, Never>?
    private var recordingCleanupTask: Task<Void, Never>?
    private var isSending = false

    init(recorder: any AudioRecording = Recorder()) {
        self.recorder = recorder
    }

    private var saveEditingClosure: ((String) -> Void)?

    private var recordPlayerSubscription: AnyCancellable?
    private var subscriptions = Set<AnyCancellable>()
    
    func setRecorderSettings(recorderSettings: RecorderSettings = RecorderSettings()) {
        Task {
            if let recorder = self.recorder as? Recorder {
                await recorder.setRecorderSettings(recorderSettings)
            }
        }
    }

    func onStart() {
        subscriptions.removeAll()
        subscribeValidation()
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .merge(with: NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification))
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                if notification.name == AVAudioSession.interruptionNotification,
                   notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt != AVAudioSession.InterruptionType.began.rawValue {
                    return
                }
                self?.cancelRecording()
            }
            .store(in: &subscriptions)
    }

    func onStop() {
        cancelRecording()
        subscriptions.removeAll()
    }

    func reset() {
        text = ""
        attachments = InputViewAttachments()
        state = .empty
        showMediaPicker = false
        showFilePicker = false
        showLocationPicker = false
        saveEditingClosure = nil
        subscribeValidation()
    }

    func send() {
        guard !isSending, state != .waitingForRecordingPermission else { return }
        isSending = true
        let generation = recordingGeneration
        Task {
            defer { isSending = false }
            await recorder.stopRecording()
            await recordingPlayer?.reset()
            guard recordingGeneration == generation else { return }
            if let recording = attachments.recording, recording.url == nil { return }
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.medias.isEmpty || !attachments.files.isEmpty || attachments.recording?.url != nil || attachments.staticLocation != nil || attachments.liveLocation != nil else { return }
            sendMessage()
        }
    }

    func edit(_ closure: @escaping (String) -> Void) {
        saveEditingClosure = closure
        state = .editing
    }

    func inputViewAction() -> (InputViewAction) -> Void {
        { [weak self] in
            self?.inputViewActionInternal($0)
        }
    }

    private func inputViewActionInternal(_ action: InputViewAction) {
        switch action {
        case .file:
            showFilePicker = true
        case .photo:
            mediaPickerMode = .photos
            showMediaPicker = true
        case .add:
            mediaPickerMode = .camera
        case .camera:
            mediaPickerMode = .camera
            showMediaPicker = true
        case .location:
            showLocationPicker = true
        case .send:
            send()
        case .recordAudioTap:
            recordAudio(holding: false)
        case .recordAudioHold:
            recordAudio(holding: true)
        case .recordAudioLock:
            state = .isRecordingTap
        case .stopRecordAudio:
            let generation = recordingGeneration
            Task {
                await recorder.stopRecording()
                guard recordingGeneration == generation else { return }
                if let recording = attachments.recording, recording.url != nil {
                    state = .hasRecording
                } else {
                    cancelRecording()
                }
                await recordingPlayer?.reset()
            }
        case .deleteRecord:
            cancelRecording()
        case .playRecord:
            state = .playingRecording
            if let recording = attachments.recording {
                Task {
                    subscribeRecordPlayer()
                    await recordingPlayer?.play(recording)
                }
            }
        case .pauseRecord:
            state = .pausedRecording
            Task {
                await recordingPlayer?.pause()
            }
        case .saveEdit:
            saveEditingClosure?(text)
            reset()
        case .cancelEdit:
            reset()
        }
    }

    func cancelRecording() {
        recordingGeneration = UUID()
        recordingTask?.cancel()
        recordingTask = nil
        let discardedURL = attachments.recording?.url
        unsubscribeRecordPlayer()
        attachments.recording = nil
        state = text.isEmpty && attachments.medias.isEmpty && attachments.files.isEmpty && attachments.staticLocation == nil && attachments.liveLocation == nil ? .empty : .hasTextOrMedia
        recordingCleanupTask = Task {
            await recorder.cancelRecording()
            await recordingPlayer?.reset()
            if let discardedURL { try? FileManager.default.removeItem(at: discardedURL) }
        }
    }

    private func recordAudio(holding: Bool) {
        guard attachments.recording == nil else { return }
        let generation = UUID()
        recordingGeneration = generation
        state = .waitingForRecordingPermission
        attachments.recording = Recording()
        let cleanup = recordingCleanupTask
        recordingTask = Task { @MainActor [recorder] in
            await cleanup?.value
            guard recordingGeneration == generation else { return }
            let allowed = await recorder.isAllowedToRecordAudio
            guard recordingGeneration == generation else { return }
            if allowed { state = holding ? .isRecordingHold : .isRecordingTap }
            let url = await recorder.startRecording { duration, samples in
                DispatchQueue.main.async { [weak self] in
                    guard self?.recordingGeneration == generation else { return }
                    self?.attachments.recording?.duration = duration
                    self?.attachments.recording?.waveformSamples = samples
                }
            }
            guard recordingGeneration == generation, !Task.isCancelled else {
                if let url { try? FileManager.default.removeItem(at: url) }
                return
            }
            guard let url else {
                cancelRecording()
                recordingError = "Could not start recording. Check microphone access in Settings and try again."
                return
            }
            if state == .waitingForRecordingPermission { state = .isRecordingTap }
            attachments.recording?.url = url
        }
    }
}

private extension InputViewModel {

    func validateDraft() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard state != .editing else { return } // special case
            let hasAttachments = !self.attachments.medias.isEmpty || !self.attachments.files.isEmpty || self.attachments.staticLocation != nil || self.attachments.liveLocation != nil
            if !self.text.isEmpty || hasAttachments {
                self.state = .hasTextOrMedia
            } else if self.text.isEmpty,
                      !hasAttachments,
                      self.attachments.recording == nil {
                self.state = .empty
            }
        }
    }

    func subscribeValidation() {
        $attachments.sink { [weak self] _ in
            self?.validateDraft()
        }
        .store(in: &subscriptions)

        $text.sink { [weak self] _ in
            self?.validateDraft()
        }
        .store(in: &subscriptions)
    }

    func subscribeRecordPlayer() {
        Task { @MainActor in
            if let recordingPlayer {
                recordPlayerSubscription = recordingPlayer.didPlayTillEnd
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in
                        self?.state = .hasRecording
                    }
            }
        }
    }

    func unsubscribeRecordPlayer() {
        recordPlayerSubscription = nil
    }
}

private extension InputViewModel {

    func sendMessage() {
        showActivityIndicator = true
        // live location shares need a stable id upfront so subsequent location updates can find this message again
        let messageId = (attachments.liveLocation != nil) ? UUID().uuidString : nil
        let draft = DraftMessage(
            id: messageId,
            text: text,
            medias: attachments.medias,
            files: attachments.files.map { File(id: UUID().uuidString, localURL: $0, name: $0.lastPathComponent, downloadState: .complete) },
            staticLocation: attachments.staticLocation,
            liveLocation: attachments.liveLocation,
            recording: attachments.recording,
            replyMessage: attachments.replyMessage,
            createdAt: Date()
        )
        didSendMessage?(draft)
        showActivityIndicator = false
        reset()
    }
}
