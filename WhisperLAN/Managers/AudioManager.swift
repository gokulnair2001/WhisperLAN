import Foundation
import UIKit
import AVFoundation
import Combine

class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var playbackProgress: TimeInterval = 0
    @Published var currentlyPlayingMessageID: UUID? = nil
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?
    
    private let audioSession = AVAudioSession.sharedInstance()
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // Helper method to check if a specific message is playing
    func isPlayingMessage(_ messageID: UUID) -> Bool {
        return currentlyPlayingMessageID == messageID && isPlaying
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func startRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            recordingDuration = 0
            
            // Haptic feedback (only on real devices)
            #if !targetEnvironment(simulator)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
            
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.recordingDuration = self.audioRecorder?.currentTime ?? 0
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() -> Data? {
        audioRecorder?.stop()
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Haptic feedback (only on real devices)
        #if !targetEnvironment(simulator)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        guard let url = audioRecorder?.url else { return nil }
        
        do {
            let audioData = try Data(contentsOf: url)
            // Clean up the temporary file
            try FileManager.default.removeItem(at: url)
            return audioData
        } catch {
            print("Failed to get recording data: \(error)")
            return nil
        }
    }
    
    func playAudio(data: Data, messageID: UUID) {
        // Stop any currently playing audio
        stopPlayback()
        
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
            isPlaying = true
            currentlyPlayingMessageID = messageID
            playbackProgress = 0
            
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.playbackProgress = self.audioPlayer?.currentTime ?? 0
            }
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        currentlyPlayingMessageID = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
        playbackProgress = 0
    }
    
    func getAudioDuration(data: Data) -> TimeInterval {
        do {
            let player = try AVAudioPlayer(data: data)
            return player.duration
        } catch {
            return 0
        }
    }
}

extension AudioManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentlyPlayingMessageID = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
        playbackProgress = 0
    }
} 
