//
//  User.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//
import Fluent
import Vapor
final class User: Model, Content, @unchecked Sendable {

    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password")
    var password: String
    
    @Field(key: "email")
    var email: String

    @Field(key: "role")
    var role: String
 
//    @Field(key: "created_at")
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Children(for: \.$user)
    var reservations: [Reservation]

    init() {}
    init(id: UUID? = nil, username: String, password: String, email: String, role: String, createdAt: Date) {
        self.id = id
        self.username = username
        self.password = password
        self.email = email
        self.role = role
        self.createdAt = createdAt
    }
}

extension User {
    
    func toDTO() throws -> UserDTO {
        return UserDTO(
            id: id,
            username: username,
            role: role,
            email: email
        )
   
    }
    
    
}
