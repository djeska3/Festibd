//
//  UserController.swift
//  FestibdVapor
//
//  Created by ShoSho on 02/10/2026.
//

import Fluent
import Vapor
import JWT

struct UserController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")
        
        users.post(use: create)
        users.post("login", use: login)
    }
    
    @Sendable
    func create(req: Request) async throws -> UserDTO {
        var newUser = try req.content.decode(CreateUserDTO.self)
        let passwordRegex = try Regex(
            "(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}")
        guard newUser.password.contains(passwordRegex) else {
            throw Abort(.badRequest, reason: "Wrong password")
        }
        let emailRegex = try Regex("[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
        guard newUser.email.contains(emailRegex) else {
            throw Abort(.badRequest, reason: "Wrong email")
        }
        newUser.password = try Bcrypt.hash(newUser.password)
        let userToSave = newUser.toModel()
        try await userToSave.save(on: req.db)
        return try userToSave.toDTO()
    }
    
    @Sendable
    func login(req: Request) async throws -> AuthDTO {
        let userRequest = try req.content.decode(LoginDTO.self)
        
        guard let userDB = try await User.query(on: req.db)
            .filter(\.$email == userRequest.email)
            .first()
        else {
            throw Abort(.notFound, reason: "User doesn't exist.")
        }
        guard try Bcrypt.verify(userRequest.password, created: userDB.password)
        else {
            throw Abort(.unauthorized, reason: "Password not correct.")
        }
        guard let jwtKey = Environment.get("JWT_KEY") else {
            throw Abort(.internalServerError, reason: "JWT key not found")
        }
        let payload = UserPayload(id: userDB.id!)
        let signer = JWTSigner.hs256(key: jwtKey)
        let jwToken = try signer.sign(payload)
        
        return AuthDTO(token: jwToken)
    }
}
