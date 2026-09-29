//
//  CreateUser.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//
import Fluent
struct CreateUser: AsyncMigration {
    
    func prepare(on database: any Database) async throws {
        try await database
            .schema(User.schema)
            .id()
            .field(
                 "username",
                 .string,
                 .required
            )
            .field(
                 "password",
                 .string,
                 .required
            )
            .field(
                 "email",
                 .string,
                 .required
            )
            .field(
                 "role",
                 .string,
                 .required
            )
            .field(
                 "created_at",
                 .date,
                 .required
            )
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database
            .schema(User.schema)
            .delete()
        
    }
}
