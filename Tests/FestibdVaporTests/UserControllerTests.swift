//
//  UserTests.swift
//  FestibdVapor
//
//  Created by Apprenant76 on 03/11/2026.
//

@testable import FestibdVapor
import VaporTesting
import Testing
import Fluent

@Suite("UserController tests", .serialized)
struct UserControllerTests {
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

    @Test("POST /users crée un user")
    func createUser() async throws {
        try await withApp { app in
            let createUserDTO = CreateUserDTO(username: "test", password: "123Password!", email: "test@email.com")
            try await app.testing().test(
                .POST,
                "users",
                beforeRequest: {req in
                    try req.content.encode(createUserDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let user = try res.content.decode(UserDTO.self)
                    #expect(user.id != nil)
                    #expect(user.username == "test")
                    #expect(user.email == "test@email.com")
                    #expect(user.role == "festivalGoer")
                }
            )
        }
    }

    @Test("POST /users wrong password")
    func createUserWrongPassword() async throws {
        try await withApp { app in
            let createUserDTO = CreateUserDTO(username: "test", password: "wrongpassword!", email: "test@email.com")
            try await app.testing().test(
                .POST,
                "users",
                beforeRequest: {req in
                    try req.content.encode(createUserDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("POST /users wrong email")
    func createUserWrongEmail() async throws {
        try await withApp { app in
            let createUserDTO = CreateUserDTO(username: "test", password: "123Password!", email: "testemail.com")
            try await app.testing().test(
                .POST,
                "users",
                beforeRequest: {req in
                    try req.content.encode(createUserDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("POST /users/login se connecter")
    func loginUser() async throws {
        try await withApp { app in
            try await createUserTest(app)
            let loginDTO = LoginDTO(email: "email@email.com", password: "123Password!")
            try await app.testing().test(
                .POST,
                "users/login",
                beforeRequest: { req in
                    try req.content.encode(loginDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let response = try res.content.decode(AuthDTO.self)
                    #expect (!response.token.isEmpty)

                }
            )
        }
    }

    @Test("POST /users/login User not in DB")
    func loginUserNotInDb() async throws {
        try await withApp { app in
            let loginDTO = LoginDTO(email: "email@email.com", password: "123Password!")
            try await app.testing().test(
                .POST,
                "users/login",
                beforeRequest: { req in
                    try req.content.encode(loginDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
        }
    }

    @Test("POST /users/login wrong password")
    func loginUserWrongPassword() async throws {
        try await withApp { app in
            try await createUserTest(app)
            let loginDTO = LoginDTO(email: "email@email.com", password: "wrongPassword")
            try await app.testing().test(
                .POST,
                "users/login",
                beforeRequest: { req in
                    try req.content.encode(loginDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }

    @Test("POST /users/staff/login")
    func loginStaff() async throws {
        try await withApp { app in
            try await createStaffTest(app)
            let loginDTO = LoginDTO(email: "admin@festibd.com", password: "AdminAdmin")
            try await app.testing().test(
                .POST,
                "users/staff/login",
                beforeRequest: { req in
                    try req.content.encode(loginDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let response = try res.content.decode(AuthDTO.self)
                    #expect (!response.token.isEmpty)
                }
            )
        }
    }

    @Test("POST /users/staff/login wrong password")
    func loginStaffWrongPassword() async throws {
        try await withApp { app in
            try await createStaffTest(app)
            let loginDTO = LoginDTO(email: "admin@festibd.com", password: "badPassword")
            try await app.testing().test(
                .POST,
                "users/staff/login",
                beforeRequest: { req in
                    try req.content.encode(loginDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }

    @Test("POST /users/staff/login not in DB")
    func loginStaffNotInDB() async throws {
        try await withApp() { app in
            let loginDTO = LoginDTO(email: "admin@festibd.com", password: "AdminAdmin")
            try await app.testing().test(
                .POST,
                "users/staff/login",
                beforeRequest: { req in
                    try req.content.encode(loginDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
        }
    }

    @Test("POST /users/staff/login not staff")
    func loginStaffNotStaff() async throws {
        try await withApp() { app in
            try await createUserTest(app)
            let loginDTO = LoginDTO(email: "email@email.com", password: "Password123!")
            try await app.testing().test(
                .POST,
                "users/staff/login",
                beforeRequest: { req in
                    try req.content.encode(loginDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .forbidden)
                }
            )
        }
    }
}

