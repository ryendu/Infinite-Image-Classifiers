//
//  Infinite_Image_ClassifierApp.swift
//  Infinite Image Classifier
//
//  Created by Ryan Du on 1/22/21.
//

import SwiftUI
import Firebase

@main
struct Infinite_Image_ClassifierApp: App {
    let persistenceController = PersistenceController.shared

    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
