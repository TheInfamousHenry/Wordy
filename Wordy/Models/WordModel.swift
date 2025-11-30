import Foundation
import CoreData

// MARK: - Word Model
struct WordItem: Identifiable, Codable {
    let id: UUID
    let word: String
    let definition: String
    let dateAdded: Date
    var timesReviewed: Int
    var lastReviewed: Date?
    
    init(id: UUID = UUID(), word: String, definition: String, dateAdded: Date = Date(), timesReviewed: Int = 0, lastReviewed: Date? = nil) {
        self.id = id
        self.word = word
        self.definition = definition
        self.dateAdded = dateAdded
        self.timesReviewed = timesReviewed
        self.lastReviewed = lastReviewed
    }
}

// MARK: - Quiz Question Model
struct QuizQuestion: Identifiable {
    let id: UUID
    let questionText: String
    let correctAnswer: String
    let options: [String]
    let questionType: QuestionType
    
    enum QuestionType {
        case wordToDefinition  // Show word, pick definition
        case definitionToWord  // Show definition, pick word
    }
    
    init(id: UUID = UUID(), questionText: String, correctAnswer: String, options: [String], questionType: QuestionType) {
        self.id = id
        self.questionText = questionText
        self.correctAnswer = correctAnswer
        self.options = options
        self.questionType = questionType
    }
}

// MARK: - App State Model
enum AppState: Equatable {
    case idle
    case listeningForPrompt
    case waitingForWord
    case confirmingWord(String)
    case lookingUpWord(String)
    case speakingDefinition(WordItem)
    case error(String)
    
    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.listeningForPrompt, .listeningForPrompt):
            return true
        case (.waitingForWord, .waitingForWord):
            return true
        case (.confirmingWord(let lWord), .confirmingWord(let rWord)):
            return lWord == rWord
        case (.lookingUpWord(let lWord), .lookingUpWord(let rWord)):
            return lWord == rWord
        case (.speakingDefinition(let lItem), .speakingDefinition(let rItem)):
            return lItem.id == rItem.id
        case (.error(let lError), .error(let rError)):
            return lError == rError
        default:
            return false
        }
    }
}

// MARK: - Permission State
enum PermissionState {
    case notDetermined
    case authorized
    case denied
    case restricted
}
