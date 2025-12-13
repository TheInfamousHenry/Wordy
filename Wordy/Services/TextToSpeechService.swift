//
//  TextToSpeechService.swift
//  Wordy
//
//  Created by Henry on 11/30/25.
//


import Foundation
import AVFoundation
import Combine

class TextToSpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    
    private let synthesizer = AVSpeechSynthesizer()
    private var speechQueue: [String] = []
    private var isProcessingQueue = false
    
    // Callbacks
    var onSpeechFinished: (() -> Void)?
    var onSpeechStarted: (() -> Void)?
    
    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
    
    // MARK: - Audio Session Configuration
    private func configureAudioSession() {
        do {
            // Use .playAndRecord with .defaultToSpeaker to allow both recording and playback
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func activatePlaybackMode() {
        do {
            // Ensure audio session is active and configured for playback
            // Use playAndRecord with defaultToSpeaker so audio plays through speaker
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate playback mode: \(error)")
        }
    }
    
    // MARK: - Speech Methods
    func speak(_ text: String, rate: Float = 0.5, voice: AVSpeechSynthesisVoice? = nil) {
        // Activate playback mode before speaking
        activatePlaybackMode()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate // 0.0 (slowest) to 1.0 (fastest), default is ~0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Use a pleasant English voice
        if let voice = voice {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
        
        synthesizer.speak(utterance)
    }
    
    // Speak multiple phrases in sequence
    func speakSequence(_ phrases: [String], rate: Float = 0.5, pauseBetween: TimeInterval = 0.5) {
        speechQueue = phrases
        isProcessingQueue = true
        processNextInQueue(rate: rate, pauseBetween: pauseBetween)
    }
    
    private func processNextInQueue(rate: Float, pauseBetween: TimeInterval) {
        guard isProcessingQueue, !speechQueue.isEmpty else {
            isProcessingQueue = false
            return
        }
        
        let nextPhrase = speechQueue.removeFirst()
        
        // Store the pause duration for after this phrase finishes
        let pause = pauseBetween
        let currentRate = rate
        
        onSpeechFinished = { [weak self] in
            // Wait before speaking next phrase
            DispatchQueue.main.asyncAfter(deadline: .now() + pause) {
                self?.processNextInQueue(rate: currentRate, pauseBetween: pause)
            }
        }
        
        speak(nextPhrase, rate: rate)
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        speechQueue.removeAll()
        isProcessingQueue = false
        
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func pauseSpeaking() {
        synthesizer.pauseSpeaking(at: .word)
    }
    
    func resumeSpeaking() {
        synthesizer.continueSpeaking()
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.onSpeechStarted?()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.onSpeechFinished?()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    // MARK: - Utility Methods
    func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { $0.language.starts(with: "en") }
    }
    
    func getVoiceDescription(_ voice: AVSpeechSynthesisVoice) -> String {
        return "\(voice.name) (\(voice.language))"
    }
}
