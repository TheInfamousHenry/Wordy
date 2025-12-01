import Foundation
import Combine

class ConversationManager: ObservableObject {
    @Published var currentState: AppState = .idle
    @Published var statusMessage = "Say 'Hey Wordy' to learn a new word"
    @Published var capturedWord: String = ""
    @Published var isWakeWordModeActive = false
    
    private let speechRecognition: SpeechRecognitionService
    private let textToSpeech: TextToSpeechService
    private let wakeWordDetector: WakeWordDetector
    private var cancellables = Set<AnyCancellable>()
    
    // Callback for when a word is successfully captured and confirmed
    var onWordCaptured: ((String) -> Void)?
    
    init(speechRecognition: SpeechRecognitionService, textToSpeech: TextToSpeechService, wakeWordDetector: WakeWordDetector) {
        self.speechRecognition = speechRecognition
        self.textToSpeech = textToSpeech
        self.wakeWordDetector = wakeWordDetector
        setupCallbacks()
    }
    
    // MARK: - Setup
    private func setupCallbacks() {
        // Handle speech recognition results
        speechRecognition.onSpeechRecognized = { [weak self] text in
            self?.handleRecognizedSpeech(text)
        }
        
        speechRecognition.onError = { [weak self] error in
            self?.handleError(error)
        }
        
        // Handle wake word detection
        wakeWordDetector.onWakeWordDetected = { [weak self] in
            self?.handleWakeWordDetected()
        }
        
        wakeWordDetector.onError = { [weak self] error in
            self?.handleError(error)
        }
        
        // Monitor listening state
        speechRecognition.$isListening
            .sink { [weak self] isListening in
                if isListening {
                    self?.statusMessage = "Listening..."
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Wake Word Mode
    func enableWakeWordMode() {
        guard speechRecognition.permissionState == .authorized else {
            currentState = .error("Please enable speech recognition in Settings")
            statusMessage = "Speech recognition not authorized"
            return
        }
        
        isWakeWordModeActive = true
        currentState = .idle
        statusMessage = "Say 'Hey Wordy' to learn a new word"
        wakeWordDetector.startWakeWordDetection()
    }
    
    func disableWakeWordMode() {
        isWakeWordModeActive = false
        wakeWordDetector.stopWakeWordDetection()
        statusMessage = "Wake word mode disabled"
        reset()
    }
    
    private func handleWakeWordDetected() {
        // Wake word detected - start conversation
        currentState = .waitingForWord
        statusMessage = "Wake word detected! Say a word..."
        
        // Give a brief audio cue
        textToSpeech.speak("Yes?", rate: 0.6)
        
        // After audio cue, start listening for the word
        textToSpeech.onSpeechFinished = { [weak self] in
            self?.startListeningForWord()
        }
    }
    
    // MARK: - Manual Conversation Flow (for button press)
    func startConversation() {
        guard speechRecognition.permissionState == .authorized else {
            currentState = .error("Please enable speech recognition in Settings")
            statusMessage = "Speech recognition not authorized"
            return
        }
        
        // Speak the prompt
        currentState = .listeningForPrompt
        statusMessage = "Say a word you'd like to learn..."
        
        textToSpeech.speak("What word would you like to learn?")
        
        // After TTS finishes, start listening
        textToSpeech.onSpeechFinished = { [weak self] in
            self?.startListeningForWord()
        }
    }
    
    private func startListeningForWord() {
        currentState = .waitingForWord
        statusMessage = "Listening for your word..."
        speechRecognition.resetRecognizedText()
        speechRecognition.startListening()
    }
    
    private func handleRecognizedSpeech(_ text: String) {
        guard !text.isEmpty else { return }
        
        switch currentState {
        case .waitingForWord:
            // Extract the first word (user might say multiple words)
            let word = extractFirstWord(from: text)
            confirmWord(word)
            
        default:
            break
        }
    }
    
    private func confirmWord(_ word: String) {
        capturedWord = word.lowercased()
        currentState = .confirmingWord(capturedWord)
        statusMessage = "Confirming: \(capturedWord)"
        
        // Stop listening immediately
        speechRecognition.stopListening()
        
        // Speak the word back for confirmation
        textToSpeech.speak("Did you say \(capturedWord)?")
        
        // After confirmation is spoken, look up the word
        textToSpeech.onSpeechFinished = { [weak self] in
            guard let self = self else { return }
            self.currentState = .lookingUpWord(self.capturedWord)
            self.statusMessage = "Looking up: \(self.capturedWord)"
            
            // Notify that word is ready to be looked up
            self.onWordCaptured?(self.capturedWord)
        }
    }
    
    // MARK: - Speaking Definition
    func speakDefinition(_ definition: String, forWord word: String) {
        let wordItem = WordItem(word: word, definition: definition)
        currentState = .speakingDefinition(wordItem)
        statusMessage = "Speaking definition..."
        
        // Speak the definition
        let fullMessage = "The definition of \(word) is: \(definition)"
        textToSpeech.speak(fullMessage, rate: 0.45) // Slightly slower for definition
        
        // Clear the callback first to avoid loops
        textToSpeech.onSpeechFinished = nil
        
        // After speaking, complete the conversation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.completeConversation()
        }
    }
    
    private func completeConversation() {
        capturedWord = ""
        
        // Clear all callbacks to prevent auto-restart
        textToSpeech.onSpeechFinished = nil
        speechRecognition.onSpeechRecognized = nil
        
        // Re-setup callbacks for next use
        setupCallbacks()
        
        // Return to appropriate mode
        if isWakeWordModeActive {
            currentState = .idle
            statusMessage = "Say 'Hey Wordy' to learn another word"
            // Resume wake word detection
            wakeWordDetector.resumeWakeWordDetection()
        } else {
            currentState = .idle
            statusMessage = "Word saved! Tap to learn another"
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: String) {
        currentState = .error(error)
        statusMessage = "Error: \(error)"
        
        // Speak error message
        textToSpeech.speak("Sorry, there was an error. \(error)")
        
        // Return to idle after error
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.reset()
        }
    }
    
    // MARK: - Utility
    private func extractFirstWord(from text: String) -> String {
        let words = text.components(separatedBy: .whitespaces)
        return words.first?.trimmingCharacters(in: .punctuationCharacters) ?? text
    }
    
    func reset() {
        speechRecognition.stopListening()
        textToSpeech.stopSpeaking()
        capturedWord = ""
        
        // Clear all callbacks
        textToSpeech.onSpeechFinished = nil
        textToSpeech.onSpeechStarted = nil
        
        // Re-setup speech recognition callback
        setupCallbacks()
        
        if isWakeWordModeActive {
            currentState = .idle
            statusMessage = "Say 'Hey Wordy' to learn a new word"
            wakeWordDetector.resumeWakeWordDetection()
        } else {
            currentState = .idle
            statusMessage = "Tap to start learning a new word"
        }
    }
    
    func cancelConversation() {
        speechRecognition.stopListening()
        textToSpeech.stopSpeaking()
        reset()
    }
    
    // MARK: - State Queries
    var isActive: Bool {
        switch currentState {
        case .idle, .error:
            return false
        default:
            return true
        }
    }
    
    var canStart: Bool {
        return currentState == .idle && speechRecognition.permissionState == .authorized
    }
}
