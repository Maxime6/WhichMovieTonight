//
//  WhichMovieTonightApp.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import SwiftUI
import FirebaseCore

class Appdelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct WhichMovieTonightApp: App {
    @UIApplicationDelegateAdaptor(Appdelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
