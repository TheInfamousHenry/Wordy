# Wordy - Voice-Powered Vocabulary Learning App

## 📱 Project Overview

**Wordy** is a native iOS vocabulary learning application that uses voice recognition and text-to-speech to create an interactive, hands-free learning experience. Users can build their vocabulary simply by speaking words aloud, and the app handles the rest—from looking up definitions to creating interactive flashcard quizzes.

---

## 🎯 Problem We're Solving

When reading books, articles, or documents, encountering unfamiliar words disrupts the flow:
- Stopping to look up words breaks reading momentum
- Typing on mobile devices is cumbersome
- Switching between apps interrupts comprehension
- Traditional dictionary apps require too much manual interaction

**Wordy** solves this by providing a completely hands-free, wake-word activated interface:
- Say a wake word (like "Hey Wordy") while reading
- Speak the unfamiliar word
- Instantly hear the definition without touching your device
- Words are automatically saved for later review
- Continue reading without breaking flow

---

## 💡 The Finished Product Vision

### Core User Experience:

**100% Hands-Free Reading Assistant:**

1. **Wake Word Activation:**
   - App continuously listens for wake word in the background
   - User encounters an unfamiliar word while reading
   - User says: "Hey Wordy" (or custom wake word)
   - App acknowledges with a subtle sound/haptic

2. **Word Capture Flow:**
   - App automatically starts listening for the word
   - User speaks the unfamiliar word
   - App confirms: "Did you say [word]?"
   - App looks up the definition automatically
   - App speaks the definition aloud
   - Word is saved to the user's personal library
   - App returns to wake word listening mode

3. **Seamless Reading Integration:**
   - No need to touch the device
   - Minimal interruption to reading flow
   - Quick audio feedback
   - Automatic return to listening mode

4. **Flashcard Quiz System:**
   - Browse saved words in a clean interface
   - Take quizzes with multiple-choice questions
   - Questions show either the word or definition
   - Four answer choices (1 correct, 3 from other saved words)
   - Track learning progress and review statistics

5. **Smart Features:**
   - Always-listening wake word detection
   - Hands-free, conversational interface
   - Automatic dictionary lookup
   - Audio pronunciation of words and definitions
   - Persistent storage of vocabulary
   - Adaptive quiz generation
   - Background listening capability

---

## 🛠️ Tech Stack

### **Platform & Language**
- **iOS** (16.0+)
- **Swift** 5.5+
- **SwiftUI** for modern, declarative UI

### **Core Frameworks**
- **Speech Framework** - Speech-to-text recognition
- **AVFoundation** - Text-to-speech synthesis and audio management
- **Core Data** - Local persistent storage
- **Combine** - Reactive programming and state management

### **External Services**
- **Dictionary API** - Free Dictionary API (dictionaryapi.dev) or Merriam-Webster

### **Architecture**
- **MVVM** (Model-View-ViewModel) pattern
- Service-oriented architecture
- State machine for conversation flow

---

## 📋 Development Phases

### ✅ **Phase 1: Core Architecture & Setup** (COMPLETED)
**Status:** Complete

**Objectives:**
- Set up Xcode project structure
- Configure Core Data schema
- Create data models (WordItem, QuizQuestion, AppState)
- Build CoreDataManager with CRUD operations
- Set up required permissions in Info.plist

**Deliverables:**
- ✅ Project with MVVM structure
- ✅ Core Data model (WordEntity)
- ✅ PersistenceController
- ✅ CoreDataManager service
- ✅ Base data models

---

### ✅ **Phase 2: Speech Recognition & TTS** (COMPLETED)
**Status:** Complete

**Objectives:**
- Implement speech recognition service
- Build text-to-speech service
- Create conversation flow manager
- Handle permissions and audio sessions
- Manage state transitions
- Add wake word detection capability

**Deliverables:**
- ✅ SpeechRecognitionService with microphone access
- ✅ TextToSpeechService with sequential speech support
- ✅ ConversationManager orchestrating the flow
- ✅ Main UI (ContentView) with voice controls
- ✅ Saved words list view
- ✅ Error handling and state management
- ⏳ Wake word detection (to be enhanced)

---

### 🔄 **Phase 3: Wake Word & Always-On Listening** (IN PROGRESS)
**Status:** Current Phase

**Objectives:**
- Implement continuous wake word detection
- Add background listening capability
- Optimize for battery efficiency
- Handle wake word false positives
- Add customizable wake word options

**Tasks:**
- ✅ Enhance SpeechRecognitionService for continuous listening
- ✅ Implement wake word detection algorithm
- ✅ Add audio feedback for wake word activation
- ⏳ Optimize battery usage during listening
- ✅ Handle app backgrounding
- ✅ Add toggle for always-listening mode
- ⏳ Test wake word accuracy

**Expected Deliverables:**
- WakeWordDetector service
- Continuous listening mode
- Battery-optimized speech recognition
- Wake word customization settings

---

### 📚 **Phase 4: Dictionary Integration** (UPCOMING)

**Objectives:**
- Select and integrate dictionary API
- Build dictionary lookup service
- Parse API responses for definitions
- Handle edge cases (word not found, multiple definitions)
- Add offline fallback options

**Tasks:**
- Create DictionaryService
- Implement API client with URLSession
- Parse JSON responses
- Handle multiple definitions (select primary)
- Add error handling for failed lookups
- Integrate with ConversationManager
- Test with various words

**Expected Deliverables:**
- DictionaryService class
- API response models
- Real definition lookup replacing placeholders
- Error handling for network failures

**Objectives:**
- Enhance Core Data operations
- Add word statistics tracking
- Implement search and filtering
- Add data validation

**Tasks:**
- Improve data models with metadata
- Add timestamp tracking
- Implement search functionality
- Create data migration strategy
- Add import/export capabilities (optional)

---

### 🎴 **Phase 6: Flashcard Quiz System** (UPCOMING)

**Objectives:**
- Build quiz generation logic
- Create flashcard UI components
- Implement scoring system
- Add quiz session management

**Tasks:**
- Create QuizManager service
- Build quiz generation algorithm
- Design flashcard UI with animations
- Implement multiple-choice logic
- Add progress tracking
- Create results summary screen

---

### 🎨 **Phase 7: UI Polish & User Experience** (UPCOMING)

**Objectives:**
- Refine visual design
- Add animations and transitions
- Improve accessibility
- Enhance error messages

**Tasks:**
- Design consistent color scheme
- Add loading indicators
- Implement haptic feedback
- Add voice selection options
- Create onboarding flow
- Improve empty states

---

### 🧪 **Phase 8: Testing & Optimization** (UPCOMING)

**Objectives:**
- Comprehensive testing
- Performance optimization
- Bug fixes
- Accessibility compliance

**Tasks:**
- Test with various accents and languages
- Handle background noise scenarios
- Test offline functionality
- Optimize Core Data queries
- Memory leak testing
- Accessibility audit

---

## 🚀 Current Status

**Current Phase:** Phase 3 - Wake Word & Always-On Listening

**Recently Completed:**
- ✅ Full voice conversation flow
- ✅ Speech recognition with auto-stop
- ✅ Text-to-speech with proper callbacks
- ✅ Word confirmation and saving
- ✅ Basic saved words list

**Currently Working On:**
- 🔄 Wake word detection ("Hey Wordy")
- 🔄 Continuous background listening
- 🔄 Battery-optimized speech recognition

**Next Up:**
- Dictionary API integration
- Real-time definition lookup
- Network error handling

---

## 📂 Project Structure

```
Wordy/
├── App/
│   └── WordyApp.swift                 # App entry point
├── Models/
│   ├── WordModels.swift               # Data models (WordItem, QuizQuestion, AppState)
│   └── CoreDataManager.swift          # Core Data operations
├── Services/
│   ├── SpeechRecognitionService.swift # Speech-to-text
│   ├── TextToSpeechService.swift      # Text-to-speech
│   ├── ConversationManager.swift      # Conversation orchestration
│   └── DictionaryService.swift        # [Phase 3] API integration
├── Views/
│   ├── ContentView.swift              # Main interface
│   └── SavedWordsView.swift           # Word list display
├── ViewModels/
│   └── [Future quiz and settings VMs]
└── Wordy.xcdatamodeld                 # Core Data schema
```

---

## 🎯 Key Features

### Implemented ✅
- Voice-activated word capture
- Speech-to-text recognition
- Text-to-speech feedback
- Word confirmation flow
- Local storage with Core Data
- Saved words list with delete functionality

### In Development 🔄
- Wake word detection
- Continuous listening mode
- Background listening capability

### Planned 📋
- Dictionary API lookup
- Real definition retrieval
- Flashcard quiz system
- Multiple-choice questions
- Progress tracking
- Quiz statistics
- Voice customization
- Dark mode support

---

## 🔧 Setup Instructions

### Prerequisites
- macOS with Xcode 15+
- iOS device (16.0+) for testing
- Active internet connection for dictionary lookups

### Installation
1. Clone the repository
2. Open `Wordy.xcodeproj` in Xcode
3. Build and run on a physical iOS device (Cmd + R)
   - Note: Speech recognition requires a real device, not simulator

### Permissions
The app requires:
- **Microphone Access** - For speech recognition
- **Speech Recognition** - For converting voice to text

Users will be prompted on first launch.

---

## 📝 License

This project is developed under MIT liscense.

---

## 👥 Contributing

Currently in active development. Feature requests and bug reports welcome! Contact me if you would like to assist in development.

---

## 📞 Support

For issues or questions, please refer to the project documentation or create an issue in the repository.

---

**Last Updated:** November 30, 2025  
**Version:** 0.3.0 (Phase 3 - Wake Word Detection)  
**Platform:** iOS 16.0+
