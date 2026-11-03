//
//  Helpers.swift
//  FestibdVapor
//
//  Created by Apprenant76 on 03/11/2026.
//
@testable import FestibdVapor
import VaporTesting
//import Testing
import Fluent

func createStaffTest(
    _ app: Application,
    username: String = "Testing",
    email: String = "admin@festibd.com",
    password: String = "AdminAdmin",
) async throws {
    let user = User(username: username, password: try Bcrypt.hash(password), email: email, role: .admin, createdAt: Date())
    try await user.save(on: app.db)
}

func createUserTest(
    _ app: Application,
    username: String = "Testing",
    email: String = "email@email.com",
    password: String = "123Password!",
) async throws {
    let user = User(
        username: username,
        password: try Bcrypt.hash(password),
        email: email,
        role: .festivalGoer,
        createdAt: Date()
    )
    try await user.save(on: app.db)
}

func getUserID(
    _ app: Application,
    username: String = "Testing",
    email: String = "email@email.com",
    password: String = "123Password!",
) async throws -> UUID {
    let user = User(
        username: username,
        password: try Bcrypt.hash(password),
        email: email,
        role: .festivalGoer,
        createdAt: Date()
    )
    try await user.save(on: app.db)

    return user.id!
}

func addUsersInDB(_ app: Application) async throws -> [User] {
    var users: [User] = []
    for i in 0...3 {
        let user = User(
            username: "user \(i)",
            password: try Bcrypt.hash("!Password\(i)"),
            email:"email\(i)@email.com",
            role: .festivalGoer,
            createdAt: Date()
        )
        try await user.save(on: app.db)
        users.append(user)
    }

    return users
}

func getStaffToken(
    _ app: Application,
    email: String = "admin@festibd.com",
    password: String = "AdminAdmin",
) async throws -> String {
    try await createStaffTest(app, email: email, password: password)
    let login = LoginDTO(email: email, password: password)
    var token = ""

    try await app.testing().test(
        .POST,
        "users/login",
        beforeRequest: { req in
            try req.content.encode(login, as: .json)
        },
        afterResponse: { res async throws in
            token = try res.content.decode(AuthDTO.self).token
        }
    )
    return token
}

func getUserToken(_ app: Application, toCreate: Bool = true) async throws -> String {
    if toCreate {
        try await createUserTest(app)
    }

    let loginDTO = LoginDTO(email: "email@email.com", password: "123Password!")
    var token = ""
    try await app.testing().test(
        .POST,
        "users/login",
        beforeRequest: { req in
            try req.content.encode(loginDTO, as: .json)
        },
        afterResponse: { res async throws in
            token = try res.content.decode(AuthDTO.self).token
        }
    )
    return token
}

func createCategoriesInDB(_ app: Application) async throws {
    let categories: [CategoryModel] = [
        CategoryModel(name: "writing"),
        CategoryModel(name: "drawing"),
        CategoryModel(name: "calligraphy"),
        CategoryModel(name: "reading"),
        CategoryModel(name: "cosplay"),
        CategoryModel(name: "diy"),
    ]
    for category in categories {
        try await category.save(on: app.db)
    }
}

func getCategoryID(_ app: Application) async throws -> UUID {
    let category = CategoryModel(name: "writing")
    try await category.save(on: app.db)
    return category.id!
}


func addWorkshopsInDb(_ app: Application, categoryID: UUID) async throws -> [Workshop] {

    var workshops: [Workshop] = []
    for i in 0...3 {
        let workshop = Workshop(
            name: "workshop \(i)",
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800),
            maxCapacity: 15,
            totalSubscribers: 0,
            description: "description"
        )
        workshop.$category.id = categoryID
        try await workshop.create(on: app.db)
        workshops.append(workshop)
    }
    return workshops
}

func addWorkshopsInDbMultiDays(_ app: Application, categoryID: UUID) async throws -> Workshop {

    var workshops: [Workshop] = []
    for i in 0...3 {
        let workshop = Workshop(
            name: "workshop \(i)",
            startTime: Date().addingTimeInterval(86400 * Double(i)),
            endTime: Date().addingTimeInterval(86400 * Double(i) + 1800),
            maxCapacity: 15,
            totalSubscribers: 0,
            description: "description"
        )
        workshop.$category.id = categoryID
        try await workshop.create(on: app.db)
        workshops.append(workshop)
    }
    return workshops.first!
}

func getWorkshopInDB(_ app: Application, categoryID: UUID) async throws -> Workshop {
    let workshop = Workshop(
        name: "workshop",
        startTime: Date(),
        endTime: Date().addingTimeInterval(1800),
        maxCapacity: 15,
        totalSubscribers: 0,
        description: "description"
    )
    workshop.$category.id = categoryID
    try await workshop.create(on: app.db)
    return workshop
}
func getFullWorkshopInDB(_ app: Application, categoryID: UUID) async throws -> Workshop {
    let workshop = Workshop(
        name: "workshop",
        startTime: Date(),
        endTime: Date().addingTimeInterval(1800),
        maxCapacity: 15,
        totalSubscribers: 15,
        description: "description"
    )
    workshop.$category.id = categoryID
    try await workshop.create(on: app.db)
    return workshop
}

func createMultipleReservations(_ app: Application, categoryID: UUID) async throws -> [Reservation] {
    let workshops = try await addWorkshopsInDb(app, categoryID: categoryID)
    let userID = try await getUserID(app)

    var reservations: [Reservation] = []
    for i in 0...3 {
        let reservation = Reservation(status: "validated")
        reservation.$workshop.id = workshops[i].id!
        reservation.$user.id = userID
        try await reservation.create(on: app.db)
        reservations.append(reservation)
    }
    return reservations
}

func reserveWorkshop(_ app: Application, workshopID: UUID, userID: UUID) async throws -> UUID {
    let reservation = Reservation(status: "validated")
    reservation.$workshop.id = workshopID
    reservation.$user.id = userID
    try await reservation.create(on: app.db)
    return reservation.id!
}

func getTokenOfUserWithReservation(_ app: Application, workshopID: UUID) async throws -> String {
    let userID = try await getUserID(app)

    let loginDTO = LoginDTO(email: "email@email.com", password: "123Password!")
    var token = ""
    try await app.testing().test(
        .POST,
        "users/login",
        beforeRequest: { req in
            try req.content.encode(loginDTO, as: .json)
        },
        afterResponse: { res async throws in
            token = try res.content.decode(AuthDTO.self).token
        }
    )

    let reservation = Reservation(status: "validated")
    reservation.$workshop.id = workshopID
    reservation.$user.id = userID
    try await reservation.create(on: app.db)

    return token
}

func reserveMultipleWorkshops(_ app: Application) async throws -> [Reservation] {
    var reservations: [Reservation] = []
    var workshops: [Workshop] = []
    let categoryID = try await getCategoryID(app)
    let userID = try await getUserID(app)

    for _ in 0...3 {
        workshops.append(try await getWorkshopInDB(app, categoryID: categoryID))
    }

    for workshop in workshops {
        let newReservation = Reservation(status: "validated")
        newReservation.$workshop.id = workshop.id!
        newReservation.$user.id = userID
        try await newReservation.create(on: app.db)
        reservations.append(newReservation)
    }


    return reservations
}
