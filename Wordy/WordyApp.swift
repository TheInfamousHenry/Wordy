//
//  WordyApp.swift
//  Wordy
//
//  Created by Henry on 11/29/25.
//

import SwiftUI
import CoreData

@main
struct WordyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
