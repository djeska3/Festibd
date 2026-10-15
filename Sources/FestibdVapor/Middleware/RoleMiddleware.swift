//
//  RoleMiddleware.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 14/10/2026.
//
import Vapor
import Fluent

struct RoleMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let payload = request.auth.get(UserPayload.self)
                else {
            throw Abort(.unauthorized)
        }
        
        guard let user = try await User.find(payload.id, on: request.db)
                else {
            throw Abort(.unauthorized)
        }
        
        guard user.role == .admin else {
            throw Abort(.forbidden, reason: "You aren't allowed")
        }
        return try await next.respond(to: request)
    }
}
