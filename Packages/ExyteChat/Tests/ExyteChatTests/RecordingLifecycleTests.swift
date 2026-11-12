import XCTest
@testable import ExyteChat

private actor TestRecorder: AudioRecording {
    var isAllowedToRecordAudio: Bool { true }
    private var waiter: CheckedContinuation<URL?, Never>?
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var started = false

    func startRecording(durationProgressHandler: @escaping Recorder.ProgressHandler) async -> URL? {
        started = true
        startWaiters.forEach { $0.resume() }
        startWaiters.removeAll()
        return await withCheckedContinuation { waiter = $0 }
    }
    func waitForStart() async {
        if !started { await withCheckedContinuation { startWaiters.append($0) } }
    }
    func complete(_ url: URL?) { waiter?.resume(returning: url); waiter = nil }
    func stopRecording() {}
    func cancelRecording() {}
}

private actor StopGateRecorder: AudioRecording {
    var isAllowedToRecordAudio: Bool { true }
    private var gate: CheckedContinuation<Void, Never>?
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var stopping = false
    func startRecording(durationProgressHandler: @escaping Recorder.ProgressHandler) async -> URL? { nil }
    func stopRecording() async {
        await withCheckedContinuation {
            gate = $0
            stopping = true
            waiters.forEach { $0.resume() }
            waiters.removeAll()
        }
    }
    func waitForStop() async {
        if !stopping { await withCheckedContinuation { waiters.append($0) } }
    }
    func releaseStop() { gate?.resume(); gate = nil }
    func cancelRecording() {}
}

@MainActor
final class RecordingLifecycleTests: XCTestCase {
    private func settle() async {
        for _ in 0..<50 { await Task.yield() }
    }

    func testCancelWhilePermissionIsPendingNeverSendsOrRestarts() async {
        let recorder = TestRecorder()
        let model = InputViewModel(recorder: recorder)
        var sends = 0
        model.didSendMessage = { _ in sends += 1 }
        model.inputViewAction()(.recordAudioTap)
        await recorder.waitForStart()
        model.cancelRecording()
        await recorder.complete(URL(fileURLWithPath: "/tmp/cancelled-recording.aac"))
        await settle()
        model.send()
        await settle()
        XCTAssertEqual(model.state, .empty)
        XCTAssertNil(model.attachments.recording)
        XCTAssertEqual(sends, 0)
    }

    func testRecordingFailureRestoresUsableComposer() async {
        let recorder = TestRecorder()
        let model = InputViewModel(recorder: recorder)
        model.inputViewAction()(.recordAudioTap)
        await recorder.waitForStart()
        await recorder.complete(nil)
        await settle()
        XCTAssertEqual(model.state, .empty)
        XCTAssertNotNil(model.inputError)
    }

    func testClosingChatDiscardsPreviewWithoutClearingText() async {
        let model = InputViewModel(recorder: TestRecorder())
        model.text = "draft"
        model.attachments.recording = Recording()
        model.state = .hasRecording
        model.onStop()
        XCTAssertNil(model.attachments.recording)
        XCTAssertEqual(model.text, "draft")
        XCTAssertEqual(model.state, .hasTextOrMedia)
    }

    func testRepeatedSendDoesNotDuplicateDraft() async {
        let model = InputViewModel(recorder: TestRecorder())
        model.text = "hello"
        var drafts: [DraftMessage] = []
        model.didSendMessage = { drafts.append($0) }
        model.send()
        model.send()
        await settle()
        XCTAssertEqual(drafts.count, 1)
        XCTAssertEqual(drafts.first?.text, "hello")
    }

    func testRecordingStateSurvivesAnExistingTextDraft() async {
        let recorder = TestRecorder()
        let model = InputViewModel(recorder: recorder)
        model.onStart()
        model.text = "Keep my draft"
        model.inputViewAction()(.recordAudioTap)
        await recorder.waitForStart()
        await recorder.complete(URL(fileURLWithPath: "/tmp/test-recording.aac"))
        await settle()
        XCTAssertEqual(model.state, .isRecordingTap)
        XCTAssertEqual(model.text, "Keep my draft")
        model.cancelRecording()
        XCTAssertEqual(model.state, .hasTextOrMedia)
    }

    func testBackgroundingDiscardsRecordingAndPreservesDraft() async {
        let model = InputViewModel(recorder: TestRecorder())
        model.onStart()
        model.text = "Draft"
        model.attachments.recording = Recording()
        model.state = .hasRecording
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        await settle()
        XCTAssertNil(model.attachments.recording)
        XCTAssertEqual(model.text, "Draft")
    }

    func testLifecycleDoesNotExitOrdinaryMessageEditing() async {
        for closeChat in [false, true] {
            let model = InputViewModel(recorder: TestRecorder())
            model.onStart()
            model.text = "Edited text"
            var saved = ""
            var sends = 0
            model.didSendMessage = { _ in sends += 1 }
            model.edit { saved = $0 }
            if closeChat { model.onStop(); model.onStart() }
            else { NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil) }
            await settle()
            XCTAssertEqual(model.state, .editing)
            model.inputViewAction()(.saveEdit)
            XCTAssertEqual(saved, "Edited text")
            XCTAssertEqual(sends, 0)
        }
    }

    func testConfirmedSendSurvivesBackgroundingOrClosingWhileAudioStops() async {
        for closeChat in [false, true] {
            let recorder = StopGateRecorder()
            let model = InputViewModel(recorder: recorder)
            model.onStart()
            let url = URL(fileURLWithPath: "/tmp/confirmed-send.aac")
            model.attachments.recording = Recording(duration: 2, url: url)
            model.state = .hasRecording
            var drafts: [DraftMessage] = []
            model.didSendMessage = { drafts.append($0) }
            model.send()
            await recorder.waitForStop()
            if closeChat { model.onStop() }
            else { NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil) }
            await settle()
            await recorder.releaseStop()
            await settle()
            XCTAssertEqual(drafts.count, 1)
            XCTAssertEqual(drafts.first?.recording?.url, url)
        }
    }

    func testEditingDiscardsRecordingAndKeepsNormalEditControls() async {
        let model = InputViewModel(recorder: TestRecorder())
        model.onStart()
        model.text = "Edited message"
        model.attachments.recording = Recording(url: URL(fileURLWithPath: "/tmp/edit-discard.aac"))
        model.state = .hasRecording
        var saved = ""
        model.edit { saved = $0 }
        XCTAssertNil(model.attachments.recording)
        XCTAssertEqual(model.state, .editing)
        model.inputViewAction()(.recordAudioTap)
        XCTAssertEqual(model.state, .editing)
        model.inputViewAction()(.saveEdit)
        XCTAssertEqual(saved, "Edited message")
        XCTAssertEqual(model.state, .empty)
    }
}
