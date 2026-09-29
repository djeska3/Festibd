//
//  CategoryController.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 29/09/2026.
//
import Fluent
import Vapor

struct CategoryController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let categories = routes.grouped("categories")
        categories.get(use: index)
        
    }
    
    func index(req: Request) async throws -> [CategoryDTO] {
        let categories = try await Category
            .query(on: req.db)
            .all()
        
        return try categories.map{try $0.toDTO()}
    }
}
