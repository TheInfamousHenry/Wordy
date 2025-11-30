import Foundation
import Combine

class ConversationManager: ObservableObject {
    @Published var currentState: AppState = .idle
    @Published var statusMessage = "Tap to start learning a new word"
    @Published var capturedWord: String = ""
    
    private let speechRecognition: SpeechRecognitionService
    private let textToSpeech: TextToSpeechService
    private var cancellables = Set<AnyCancellable>()
    
    // Callback for when a word is successfully captured and confirmed
    var onWordCaptured: ((String) -> Void)?
    
    init(speechRecognition: SpeechRecognitionService, textToSpeech: TextToSpeechService) {
        self.speechRecognition = speechRecognition
        self.textToSpeech = textToSpeech
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
        
        // Monitor listening state
        speechRecognition.$isListening
            .sink { [weak self] isListening in
                if isListening {
                    self?.statusMessage = "Listening..."
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Conversation Flow
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
        
        // Speak the word back for confirmation
        textToSpeech.speak("Did you say \(capturedWord)?")
        
        // After confirmation is spoken, notify that word is captured
        textToSpeech.onSpeechFinished = { [weak self] in
            guard let self = self else { return }
            self.statusMessage = "Word captured: \(self.capturedWord)"
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
        
        textToSpeech.onSpeechFinished = { [weak self] in
            self?.completeConversation()
        }
    }
    
    private func completeConversation() {
        currentState = .idle
        statusMessage = "Word saved! Tap to learn another"
        capturedWord = ""
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
        currentState = .idle
        statusMessage = "Tap to start learning a new word"
        capturedWord = ""
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