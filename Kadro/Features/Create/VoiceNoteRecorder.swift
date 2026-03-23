import Foundation
import Combine
import AVFoundation

final class VoiceNoteRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var currentDuration: TimeInterval = 0
    @Published private(set) var completedRecordingURL: URL?
    @Published private(set) var lastErrorMessage: String?
    
    let maximumDuration: TimeInterval = 90
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var currentRecordingURL: URL?
    
    @MainActor
    func startRecording() async {
        lastErrorMessage = nil
        
        let granted = await requestPermission()
        guard granted else {
            lastErrorMessage = NSLocalizedString("common.microphone_permission", comment: "")
            return
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            let url = makeRecordingURL()
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.prepareToRecord()
            recorder.record()
            
            audioRecorder = recorder
            currentRecordingURL = url
            completedRecordingURL = nil
            currentDuration = 0
            isRecording = true
            startTimer()
        } catch {
            lastErrorMessage = NSLocalizedString("common.recording_failed", comment: "")
        }
    }
    
    @MainActor
    func stopRecording() {
        guard let recorder = audioRecorder else { return }
        recorder.stop()
        finishRecording(with: recorder.currentTime, shouldKeepFile: true)
    }
    
    @MainActor
    func discardRecording() {
        audioRecorder?.stop()
        finishRecording(with: 0, shouldKeepFile: false)
    }
    
    private func requestPermission() async -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }
    
    private func makeRecordingURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("voice-note-\(UUID().uuidString)")
            .appendingPathExtension("m4a")
    }
    
    @MainActor
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.audioRecorder else { return }
            self.currentDuration = recorder.currentTime
            if recorder.currentTime >= self.maximumDuration {
                self.stopRecording()
            }
        }
    }
    
    @MainActor
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @MainActor
    private func finishRecording(with duration: TimeInterval, shouldKeepFile: Bool) {
        stopTimer()
        isRecording = false
        currentDuration = duration
        audioRecorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        if shouldKeepFile, let currentRecordingURL {
            completedRecordingURL = currentRecordingURL
        } else {
            if let currentRecordingURL {
                try? FileManager.default.removeItem(at: currentRecordingURL)
            }
            if let completedRecordingURL {
                try? FileManager.default.removeItem(at: completedRecordingURL)
            }
            completedRecordingURL = nil
        }
        
        currentRecordingURL = nil
    }
}
