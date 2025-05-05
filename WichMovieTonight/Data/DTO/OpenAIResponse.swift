//
//  OpenAIResponse.swift
//  WichMovieTonight
//
//  Created by Maxime Tanter on 02/05/2025.
//

import Foundation

struct OpenAIResponse: Decodable {
    
    struct Choice: Decodable {
        
        struct Message: Decodable {
            let role: String
            let content: String
        }
        
        let message: Message
    }
    
    let choices: [Choice]
}
