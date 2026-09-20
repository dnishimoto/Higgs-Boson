//
//  Higgs_BosonApp.swift
//  Higgs Boson
//
//  Created by David Nishimoto on 9/20/26.
//

import SwiftUI
import CoreData

@main
struct Higgs_BosonApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
