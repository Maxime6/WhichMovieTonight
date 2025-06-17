//
//  WhichMovieTonightApp.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import FirebaseCore
import FirebaseFirestore
import SwiftUI

class Appdelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        // Configure Dependency Injection
        DependencyManager.registerAllDependencies()

        return true
    }
}

@main
struct WhichMovieTonightApp: App {
    @UIApplicationDelegateAdaptor(Appdelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
