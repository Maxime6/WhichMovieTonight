//
//  Config.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Foundation

enum Config {
    // MARK: - API Keys

    /// Clé API OpenAI - À configurer dans le fichier APIKeys.plist
    static var openAIAPIKey: String? {
        return getAPIKey(for: "OPENAI_API_KEY")
    }

    /// Clé API OMDB - Déjà intégrée dans le service
    static let omdbAPIKey = "a8e95e30"

    // MARK: - Private Methods

    private static func getAPIKey(for key: String) -> String? {
        // 1. Essayer d'abord les variables d'environnement (pour le développement avec Xcode)
        if let envValue = ProcessInfo.processInfo.environment[key] {
            return envValue
        }

        // 2. Essayer le fichier APIKeys.plist (pour l'app en production)
        if let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let value = plist[key] as? String
        {
            return value
        }

        // 3. Essayer Info.plist (alternative)
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            return value
        }

        return nil
    }

    /// Vérifier que toutes les clés API nécessaires sont disponibles
    static func validateConfiguration() -> (isValid: Bool, missingKeys: [String]) {
        var missingKeys: [String] = []

        if openAIAPIKey == nil {
            missingKeys.append("OPENAI_API_KEY")
        }

        return (missingKeys.isEmpty, missingKeys)
    }
}
