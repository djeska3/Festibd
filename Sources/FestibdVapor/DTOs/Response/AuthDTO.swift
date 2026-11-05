//
//  AuthDTO.swift
//  FestibdVapor
//
//  Created by ShoSho on 02/10/2026.
//

import Vapor
import Fluent
import JWT

struct AuthDTO: Content {
    let token: String
}
