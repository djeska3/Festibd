//
//  CreateReservation.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//
import Fluent
struct CreateReservation: AsyncMigration {
    
    func prepare(on database: any Database) async throws {
        try await database
            .schema(Reservation.schema)
            .id()
            .field(
                 "status",
                 .string,
                 .required
            )
            .field(
                 "user_id",
                 .uuid,
                 .required,
                 .references(User.schema, "id")
            )
            .field(
                 "workshop_id",
                 .uuid,
                 .required,
                 .references(Workshop.schema, "id")
            )
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database
            .schema(Reservation.schema)
            .delete()
        
    }
}
