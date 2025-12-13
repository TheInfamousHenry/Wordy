//
//  DictionaryService.swift
//  Wordy
//
//  Created by Henry on 12/1/25.
//

import Foundation
import Combine

class DictionaryService: ObservableObject {
    @Published var isLoading = false
    @Published var lastError: String?
    
    // Using Free Dictionary API (https://dictionaryapi.dev/)
    private let baseURL = "https://api.dictionaryapi.dev/api/v2/entries/en/"
    
    func lookupWord(_ word: String) async throws -> String {
        guard !word.isEmpty else {
            throw DictionaryError.invalidWord
        }
        
        let cleanedWord = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: "\(baseURL)\(cleanedWord)") else {
            throw DictionaryError.invalidURL
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.lastError = nil
        }
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw DictionaryError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    throw DictionaryError.wordNotFound
                }
                throw DictionaryError.serverError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            let entries = try decoder.decode([DictionaryEntry].self, from: data)
            
            guard let firstEntry = entries.first,
                  let firstMeaning = firstEntry.meanings.first,
                  let firstDefinition = firstMeaning.definitions.first else {
                throw DictionaryError.noDefinition
            }
            
            return firstDefinition.definition
        } catch let error as DictionaryError {
            DispatchQueue.main.async {
                self.lastError = error.localizedDescription
            }
            throw error
        } catch {
            let errorMessage = "Failed to lookup word: \(error.localizedDescription)"
            DispatchQueue.main.async {
                self.lastError = errorMessage
            }
            throw DictionaryError.networkError(errorMessage)
        }
    }
}

// MARK: - Dictionary Models
struct DictionaryEntry: Codable {
    let word: String
    let meanings: [Meaning]
}

struct Meaning: Codable {
    let partOfSpeech: String
    let definitions: [Definition]
}

struct Definition: Codable {
    let definition: String
    let example: String?
}

// MARK: - Dictionary Errors
enum DictionaryError: LocalizedError {
    case invalidWord
    case invalidURL
    case invalidResponse
    case wordNotFound
    case noDefinition
    case serverError(Int)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidWord:
            return "Invalid word provided"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .wordNotFound:
            return "Word not found in dictionary"
        case .noDefinition:
            return "No definition available for this word"
        case .serverError(let code):
            return "Server error: \(code)"
        case .networkError(let message):
            return message
        }
    }
}

