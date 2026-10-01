//
//  CreateUserDTO.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//
import Fluent
import Vapor

struct CreateUserDTO: Content {
    
    var username: String
    var password: String
    var email: String
  
}

extension CreateUserDTO {
    
    func toModel() -> User {
        let user = User()
        user.username = username
        user.password = password
        user.email = email
        user.role = "festivalGoer"
      return user
    }
}
