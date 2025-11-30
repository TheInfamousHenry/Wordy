//
//  CoreDataManager.swift
//  Wordy
//
//  Created by Henry on 11/29/25.
//

import CoreData
import Foundation
import Combine

// MARK: - Core Data Stack
class CoreDataStack {
    static let shared = CoreDataStack()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "VocabLearner")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // For SwiftUI previews
    static var preview: CoreDataStack = {
        let controller = CoreDataStack(inMemory: true)
        let context = controller.container.viewContext
        
        // Add sample data
        for i in 0..<5 {
            let word = WordEntity(context: context)
            word.id = UUID()
            word.word = "Sample\(i)"
            word.definition = "Definition for sample word \(i)"
            word.dateAdded = Date()
            word.timesReviewed = Int16(i)
        }
        
        try? context.save()
        return controller
    }()
}

// MARK: - Core Data Entity Extension
extension WordEntity {
    func toWordItem() -> WordItem {
        return WordItem(
            id: self.id ?? UUID(),
            word: self.word ?? "",
            definition: self.definition ?? "",
            dateAdded: self.dateAdded ?? Date(),
            timesReviewed: Int(self.timesReviewed),
            lastReviewed: self.lastReviewed
        )
    }
    
    static func fromWordItem(_ item: WordItem, context: NSManagedObjectContext) -> WordEntity {
        let entity = WordEntity(context: context)
        entity.id = item.id
        entity.word = item.word
        entity.definition = item.definition
        entity.dateAdded = item.dateAdded
        entity.timesReviewed = Int16(item.timesReviewed)
        entity.lastReviewed = item.lastReviewed
        return entity
    }
}

// MARK: - Core Data Manager
@MainActor class CoreDataManager: ObservableObject {
    private let container: NSPersistentContainer
    private var context: NSManagedObjectContext {
        container.viewContext
    }
    
    init(container: NSPersistentContainer = CoreDataStack.shared.container) {
        self.container = container
    }
    
    // CRUD Operations
    func saveWord(_ wordItem: WordItem) throws {
        _ = WordEntity.fromWordItem(wordItem, context: context)
        try context.save()
    }
    
    func fetchAllWords() throws -> [WordItem] {
        let request = WordEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WordEntity.dateAdded, ascending: false)]
        
        let entities = try context.fetch(request)
        return entities.map { $0.toWordItem() }
    }
    
    func fetchWord(byWord word: String) throws -> WordItem? {
        let request = WordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "word ==[c] %@", word)
        request.fetchLimit = 1
        
        let entities = try context.fetch(request)
        return entities.first?.toWordItem()
    }
    
    func updateWordReviewCount(_ wordItem: WordItem) throws {
        let request = WordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", wordItem.id as CVarArg)
        
        if let entity = try context.fetch(request).first {
            entity.timesReviewed += 1
            entity.lastReviewed = Date()
            try context.save()
        }
    }
    
    func deleteWord(_ wordItem: WordItem) throws {
        let request = WordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", wordItem.id as CVarArg)
        
        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try context.save()
        }
    }
    
    func deleteAllWords() throws {
        let request = WordEntity.fetchRequest()
        let entities = try context.fetch(request)
        
        entities.forEach { context.delete($0) }
        try context.save()
    }
}
