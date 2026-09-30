//
//  CategoryDTO.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 29/09/2026.
//
import Fluent
import Vapor

struct CategoryDTO: Content {
    
    var id: UUID
    var name: String
}

extension CategoryDTO {
    func toModel() throws -> Category {
        return Category(
            id: id,
            name: name
        )
    }
}


