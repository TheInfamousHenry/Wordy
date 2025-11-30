//
//  WordyApp.swift
//  Wordy
//
//  Created by Henry on 11/29/25.
//

import SwiftUI
import CoreData

@main
struct VocabLearnerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var coreDataManager = CoreDataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(coreDataManager)
        }
    }
}
