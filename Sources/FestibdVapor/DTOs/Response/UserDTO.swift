//
//  UserDTO.swift
//  FestibdVapor
//
//  Created by ShoSho on 02/10/2026.
//

import Vapor
import Fluent

struct UserDTO: Content {
    let id: UUID?
    let username: String
    let role: String
    let email: String
}
