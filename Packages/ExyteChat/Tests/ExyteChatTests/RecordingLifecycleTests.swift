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
}
