//
//  WakeWordDetector.swift
//  Wordy
//
//  Created by Henry on 12/1/25.
//


import Foundation
import Speech
import AVFoundation
import Combine
import UIKit

class WakeWordDetector: ObservableObject {
    @Published var isListening = false
    @Published var isActive = false // Whether wake word detection is enabled
    @Published var lastHeardPhrase = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Wake word configuration
    private let wakeWords = ["hey wordy", "wordy", "hey word"]
    private var detectionBuffer: [String] = []
    private let bufferSize = 10 // Keep last 10 recognized phrases
    
    // Callbacks
    var onWakeWordDetected: (() -> Void)?
    var onError: ((String) -> Void)?
    
    init() {
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    // MARK: - Wake Word Detection Control
    func startWakeWordDetection() {
        guard !isListening else { return }
        
        // Cancel any existing task
        stopWakeWordDetection()
        
        // Configure audio session
        setupAudioSession()
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            onError?("Unable to create recognition request")
            return
        }
        
        // Enable partial results for continuous listening
        recognitionRequest.shouldReportPartialResults = true
        
        // For better wake word detection
        recognitionRequest.taskHint = .search
        
        let inputNode = audioEngine.inputNode
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString.lowercased()
                
                DispatchQueue.main.async {
                    self.lastHeardPhrase = transcription
                }
                
                // Check for wake word
                if self.containsWakeWord(transcription) {
                    DispatchQueue.main.async {
                        self.handleWakeWordDetected()
                    }
                }
            }
            
            // Handle errors but don't stop - we want continuous listening
            if let error = error as NSError? {
                // Only restart if it's not a user cancellation
                if error.domain != "kAFAssistantErrorDomain" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        if self?.isActive == true {
                            self?.restartListening()
                        }
                    }
                }
            }
        }
        
        // Configure audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                self.isActive = true
            }
        } catch {
            onError?("Audio engine failed to start: \(error.localizedDescription)")
        }
    }
    
    func stopWakeWordDetection() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isListening = false
            self.isActive = false
        }
    }
    
    func pauseWakeWordDetection() {
        audioEngine.pause()
        DispatchQueue.main.async {
            self.isListening = false
        }
    }
    
    func resumeWakeWordDetection() {
        guard isActive else { return }
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
            }
        } catch {
            onError?("Failed to resume: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Wake Word Detection Logic
    private func containsWakeWord(_ text: String) -> Bool {
        let normalizedText = text.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if text contains any of the wake words
        for wakeWord in wakeWords {
            // Check for exact match or as part of a phrase
            if normalizedText.contains(wakeWord) {
                return true
            }
            
            // Check for slight variations (for better detection)
            let words = normalizedText.components(separatedBy: .whitespaces)
            if words.contains(where: { $0.contains("wordy") || $0.contains("word") }) {
                return true
            }
        }
        
        return false
    }
    
    private func handleWakeWordDetected() {
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Temporarily pause wake word detection
        pauseWakeWordDetection()
        
        // Notify listener
        onWakeWordDetected?()
        
        // Clear the buffer
        detectionBuffer.removeAll()
        lastHeardPhrase = ""
    }
    
    // MARK: - Restart Logic
    private func restartListening() {
        stopWakeWordDetection()
        
        // Small delay before restarting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.startWakeWordDetection()
        }
    }
    
    // MARK: - Custom Wake Word
    func setCustomWakeWord(_ word: String) {
        // Future enhancement: allow users to customize wake word
        // For now, this is a placeholder
    }
    
    deinit {
        stopWakeWordDetection()
    }
}
