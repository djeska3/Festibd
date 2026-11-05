//
//  UserPayload.swift
//  FestibdVapor
//
//  Created by ShoSho on 02/10/2026.
//

import Foundation
import Vapor
import JWT

// JWT/UserPayload.swift

struct UserPayload: JWTPayload, Authenticatable {
    var id: UUID
    var expiration: Date
    
    init(id: UUID) {
        self.id = id
        expiration = Date().addingTimeInterval(3600 * 24) // Expires in 1 day
    }
    
    // verification of the token’s validity
    
    func verify(using signer: JWTSigner) throws {
        if expiration < Date() {
            throw JWTError.invalidJWK // Launches an error if the token has expired
        }
    }
}
