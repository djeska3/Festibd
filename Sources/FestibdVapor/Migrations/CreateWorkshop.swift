//
//  CreateWorkshop.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//
import Fluent
struct CreateWorkshop: AsyncMigration {
    
    func prepare(on database: any Database) async throws {
        try await database
            .schema(Workshop.schema)
            .id()
            .field(
                 "name",
                 .string,
                 .required
            )
            .field(
                 "start_time",
                 .datetime,
                 .required
            )
            .field(
                 "end_time",
                 .datetime,
                 .required
            )
            .field(
                 "max_capacity",
                 .int,
                 .required
            )
            .field(
                 "total_subscribers",
                 .int,
                 .required
            )
            .field(
                 "description",
                 .string,
                 .required
            )
            .field(
                 "category_id",
                 .uuid,
                 .required,
                 .references(Category.schema, "id")
            )
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database
            .schema(Workshop.schema)
            .delete()
        
    }
}
