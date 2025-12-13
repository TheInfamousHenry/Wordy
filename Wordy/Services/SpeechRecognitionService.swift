//
//  SpeechRecognitionService.swift
//  Wordy
//
//  Created by Henry on 11/30/25.
//


import Foundation
import Speech
import AVFoundation
import Combine

class SpeechRecognitionService: ObservableObject {
    @Published var isListening = false
    @Published var permissionState: PermissionState = .notDetermined
    @Published var recognizedText = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Callback for when speech is recognized
    var onSpeechRecognized: ((String) -> Void)?
    var onError: ((String) -> Void)?
    
    init() {
        checkPermissions()
    }
    
    // MARK: - Permission Handling
    func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.permissionState = .authorized
                case .denied:
                    self?.permissionState = .denied
                case .restricted:
                    self?.permissionState = .restricted
                case .notDetermined:
                    self?.permissionState = .notDetermined
                @unknown default:
                    self?.permissionState = .notDetermined
                }
            }
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Speech Recognition
    func startListening() {
        guard permissionState == .authorized else {
            onError?("Speech recognition not authorized")
            return
        }
        
        // Cancel any ongoing recognition
        if recognitionTask != nil {
            stopListening()
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Use playAndRecord to allow both recording and playback
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            onError?("Audio session setup failed: \(error.localizedDescription)")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            onError?("Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Get audio input node
        let inputNode = audioEngine.inputNode
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = transcription
                }
                isFinal = result.isFinal
                
                // Stop after getting a result (more responsive)
                if !transcription.isEmpty {
                    // Give it a moment to finalize, then stop
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                        guard let self = self, self.isListening else { return }
                        let finalText = self.recognizedText
                        self.stopListening()
                        if !finalText.isEmpty {
                            self.onSpeechRecognized?(finalText)
                        }
                    }
                }
            }
            
            if error != nil || isFinal {
                let finalText = self.recognizedText
                self.stopListening()
                
                if isFinal, !finalText.isEmpty {
                    DispatchQueue.main.async {
                        self.onSpeechRecognized?(finalText)
                    }
                }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.onError?("Recognition error: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Configure audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
            }
        } catch {
            onError?("Audio engine failed to start: \(error.localizedDescription)")
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isListening = false
        }
    }
    
    // MARK: - Utility
    func resetRecognizedText() {
        recognizedText = ""
    }
    
    deinit {
        stopListening()
    }
}


