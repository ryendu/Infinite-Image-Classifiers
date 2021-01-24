//
//  Infinite_Image_ClassifierApp.swift
//  Infinite Image Classifier
//
//  Created by Ryan Du on 1/22/21.
//

import SwiftUI
import Firebase
import CoreData

@main
struct Infinite_Image_ClassifierApp: App {
    let persistenceManager = PersistenceManager()

    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceManager.persistentContainer.viewContext)
        }
    }
}


class PersistenceManager {
  let persistentContainer: NSPersistentContainer = {
      let container = NSPersistentContainer(name: "Infinite_Image_Classifier")
      container.loadPersistentStores(completionHandler: { (storeDescription, error) in
          if let error = error as NSError? {
              fatalError("Unresolved error \(error), \(error.userInfo)")
          }
      })
      return container
  }()

  init() {
    let center = NotificationCenter.default
    let notification = UIApplication.willResignActiveNotification

    center.addObserver(forName: notification, object: nil, queue: nil) { [weak self] _ in
      guard let self = self else { return }

      if self.persistentContainer.viewContext.hasChanges {
        try? self.persistentContainer.viewContext.save()
      }
    }
  }
}


    
