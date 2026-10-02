//
//  LoginDTO.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//
import Fluent
import Vapor

struct LoginDTO: Content {
    
    var email: String
    var password: String
  
}


