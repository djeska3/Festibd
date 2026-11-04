//
//  CategoryControllerTests.swift
//  FestibdVapor
//
//  Created by Apprenant76 on 03/11/2026.
//
@testable import FestibdVapor
import VaporTesting
import Testing
import Fluent

@Suite("CategoryController test", .serialized)
struct CategoryControllerTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        setenv("JWT_KEY", "test-secret-key", 1)
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await app.autoRevert()
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    @Test("GET /categories")
    func getCategories() async throws {
        try await withApp { app in
            try await createCategoriesInDB(app)
            let categoryNames: [String] = ["writing", "drawing", "calligraphy", "reading", "cosplay", "diy"]

            let token = try await getUserToken(app)
            try await app.testing().test(
                .GET,
                "categories",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let data = try res.content.decode([CategoryDTO].self)
                    for category in data {
                        #expect(categoryNames.contains(category.name))
                        #expect(category.id != nil)
                    }
                }
            )
        }
    }
}
