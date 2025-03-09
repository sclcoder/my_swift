//
//  Models.swift
//  my_swift
//
//  Created by tiny on 2025/3/9.
//

import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
}

