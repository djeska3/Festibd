//
//  CreateCategory.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//
import Fluent
struct CreateCategory: AsyncMigration {
    
    func prepare(on database: any Database) async throws {
        try await database
            .schema(Category.schema)
            .id()
            .field(
                 "name",
                 .string,
                 .required
            )
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database
            .schema(Category.schema)
            .delete()
        
    }
}

