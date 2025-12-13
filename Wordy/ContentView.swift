import SwiftUI

struct ContentView: View {
    @StateObject private var speechService = SpeechRecognitionService()
    @StateObject private var ttsService = TextToSpeechService()
    @StateObject private var conversationManager: ConversationManager
    @EnvironmentObject var coreDataManager: CoreDataManager
    
    @State private var showingPermissionAlert = false
    
    init() {
        let speech = SpeechRecognitionService()
        let tts = TextToSpeechService()
        // Create a wake word detector instance. If your project defines a specific type, replace `DefaultWakeWordDetector()` accordingly.
        let wakeWordDetector = WakeWordDetector()
        _conversationManager = StateObject(wrappedValue: ConversationManager(speechRecognition: speech, textToSpeech: tts, wakeWordDetector: wakeWordDetector))
        _speechService = StateObject(wrappedValue: speech)
        _ttsService = StateObject(wrappedValue: tts)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                Text("Vocab Learner")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.blue)
                
                Spacer()
                
                // Status Display
                VStack(spacing: 15) {
                    stateIndicator
                    
                    Text(conversationManager.statusMessage)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    if !conversationManager.capturedWord.isEmpty {
                        Text(conversationManager.capturedWord)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    if speechService.isListening {
                        Text(speechService.recognizedText)
                            .font(.title2)
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                .frame(minHeight: 200)
                
                Spacer()
                
                // Main Action Button
                mainActionButton
                
                // Cancel Button (shown when active)
                if conversationManager.isActive {
                    Button(action: {
                        conversationManager.cancelConversation()
                    }) {
                        Text("Cancel")
                            .font(.title3)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                
                Spacer()
                
                // Navigation to Saved Words
                NavigationLink(destination: SavedWordsView()) {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("View Saved Words")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 30)
            }
            .padding()
            .navigationBarHidden(true)
        }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings", action: openSettings)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable Speech Recognition and Microphone access in Settings to use this app.")
        }
        .onAppear {
            setupConversationCallbacks()
            // Enable wake word mode on app launch
            if speechService.permissionState == .authorized {
                conversationManager.enableWakeWordMode()
            }
        }
        .onChange(of: speechService.permissionState) { newState in
            if newState == .authorized && !conversationManager.isWakeWordModeActive {
                conversationManager.enableWakeWordMode()
            }
        }
    }
    
    // MARK: - View Components
    
    private var stateIndicator: some View {
        HStack {
            Circle()
                .fill(stateColor)
                .frame(width: 20, height: 20)
            
            Text(stateText)
                .font(.headline)
                .foregroundColor(stateColor)
        }
    }
    
    private var mainActionButton: some View {
        Button(action: handleMainAction) {
            HStack {
                Image(systemName: buttonIcon)
                    .font(.title2)
                Text(buttonText)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(buttonColor)
            .cornerRadius(20)
            .shadow(radius: 5)
        }
        .padding(.horizontal, 30)
        .disabled(!conversationManager.canStart && !conversationManager.isActive)
    }
    
    // MARK: - Computed Properties
    
    private var stateColor: Color {
        switch conversationManager.currentState {
        case .idle:
            return .gray
        case .listeningForPrompt, .waitingForWord:
            return .blue
        case .confirmingWord, .lookingUpWord:
            return .orange
        case .speakingDefinition:
            return .green
        case .error:
            return .red
        }
    }
    
    private var stateText: String {
        switch conversationManager.currentState {
        case .idle:
            return "Ready"
        case .listeningForPrompt:
            return "Prompting"
        case .waitingForWord:
            return "Listening"
        case .confirmingWord:
            return "Confirming"
        case .lookingUpWord:
            return "Looking Up"
        case .speakingDefinition:
            return "Speaking"
        case .error:
            return "Error"
        }
    }
    
    private var buttonText: String {
        if conversationManager.isActive {
            return "Listening..."
        }
        return "Start Learning"
    }
    
    private var buttonIcon: String {
        if speechService.isListening {
            return "waveform"
        }
        return "mic.fill"
    }
    
    private var buttonColor: Color {
        if conversationManager.isActive {
            return .orange
        }
        return .blue
    }
    
    // MARK: - Actions
    
    private func handleMainAction() {
        if speechService.permissionState != .authorized {
            showingPermissionAlert = true
            return
        }
        
        if conversationManager.canStart {
            conversationManager.startConversation()
        }
    }
    
    private func setupConversationCallbacks() {
        // When a word is captured, we'll look it up
        conversationManager.onWordCaptured = { [weak conversationManager, weak coreDataManager] word in
            guard let conversationManager = conversationManager,
                  let coreDataManager = coreDataManager else { return }
            
            // Look up word in dictionary
            Task {
                let dictionaryService = DictionaryService()
                do {
                    let definition = try await dictionaryService.lookupWord(word)
                    
                    // Speak the definition
                    await MainActor.run {
                        conversationManager.speakDefinition(definition, forWord: word)
                        
                        // Save to Core Data
                        let wordItem = WordItem(word: word, definition: definition)
                        try? coreDataManager.saveWord(wordItem)
                    }
                } catch {
                    let errorMessage = error.localizedDescription
                    await MainActor.run {
                        conversationManager.currentState = .error(errorMessage)
                        conversationManager.statusMessage = "Failed to lookup word: \(errorMessage)"
                        // Use the TTS service directly
                        ttsService.speak("Sorry, I couldn't find a definition for \(word).")
                    }
                }
            }
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Saved Words View (Placeholder)
struct SavedWordsView: View {
    @EnvironmentObject var coreDataManager: CoreDataManager
    @State private var words: [WordItem] = []
    
    var body: some View {
        List {
            if words.isEmpty {
                Text("No words saved yet")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(words) { word in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(word.word)
                            .font(.headline)
                        Text(word.definition)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteWords)
            }
        }
        .navigationTitle("Saved Words")
        .onAppear {
            loadWords()
        }
    }
    
    private func loadWords() {
        words = (try? coreDataManager.fetchAllWords()) ?? []
    }
    
    private func deleteWords(at offsets: IndexSet) {
        for index in offsets {
            let word = words[index]
            try? coreDataManager.deleteWord(word)
        }
        loadWords()
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(CoreDataManager(container: PersistenceController.preview.container))
}
