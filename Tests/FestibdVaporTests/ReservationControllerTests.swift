//
//  FestibdVaporTests 2.swift
//  FestibdVapor
//
//  Created by Apprenant76 on 04/11/2026.
//


@testable import FestibdVapor
import VaporTesting
import Testing
import Fluent

@Suite("Reservation Controller tests", .serialized)
struct ReservationControllerTests{

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

    @Test("GET /reservations")
    func getUserReservations() async throws {
        try await withApp() { app in
            let reservations = try await reserveMultipleWorkshops(app)
            let token = try await getUserToken(app, toCreate: false)

            try await app.testing().test(
                .GET,
                "reservations",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let data = try res.content.decode([ReservationDTO].self)
                    #expect((data.count == reservations.count))
                    for i in 0..<data.count {
                        #expect(data[i].id != nil)
                        #expect(data[i].status == reservations[i].status)
                        #expect(data[i].workshopID == reservations[i].$workshop.id)
                    }
                }
            )
        }
    }

    @Test("GET /reservations no token")
    func getUserReservationsNoToken() async throws {
        try await withApp() { app in
            let _ = try await reserveMultipleWorkshops(app)

            try await app.testing().test(
                .GET,
                "reservations",
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }

    @Test("POST /reservations")
    func createReservations() async throws {
        try await withApp { app in
            let token = try await getUserToken(app)
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app , categoryID: categoryID)

            let reservationDTO = CreateReservationDTO(workshopID: workshop.id!)

            try await app
                .testing()
                .test(
                    .POST,
                    "reservations",
                    beforeRequest: { req in
                        req.headers.bearerAuthorization = BearerAuthorization(token: token)
                        try req.content.encode(reservationDTO, as: .json)
                    },
                    afterResponse: { res async throws in
                        #expect(res.status == .ok)
                        let data = try res.content.decode(CreateReservationResponseDTO.self)
                        #expect(data.id != nil)
                        #expect(data.status == "validated")
                        #expect(data.workshopID == workshop.id)
                    }
                )
        }
    }

    @Test("POST /reservations full")
    func createReservationsFull() async throws {
        try await withApp { app in
            let token = try await getUserToken(app)
            let categoryID = try await getCategoryID(app)
            let workshop = try await getFullWorkshopInDB(app , categoryID: categoryID)

            let reservationDTO = CreateReservationDTO(workshopID: workshop.id!)

            try await app
                .testing()
                .test(
                    .POST,
                    "reservations",
                    beforeRequest: { req in
                        req.headers.bearerAuthorization = BearerAuthorization(token: token)
                        try req.content.encode(reservationDTO, as: .json)
                    },
                    afterResponse: { res async throws in
                        #expect(res.status == .ok)
                        let data = try res.content.decode(CreateReservationResponseDTO.self)
                        #expect(data.id != nil)
                        #expect(data.status == "pending")
                        #expect(data.workshopID == workshop.id)
                    }
                )
        }
    }

    @Test("POST /reservations no token")
    func createReservationsNoToken() async throws {
        try await withApp() { app in
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app , categoryID: categoryID)

            let reservationDTO = CreateReservationDTO(workshopID: workshop.id!)

            try await app
                .testing()
                .test(
                    .POST,
                    "reservations",
                    beforeRequest: { req in
                        try req.content.encode(reservationDTO, as: .json)
                    },
                    afterResponse: { res async throws in
                        #expect(res.status == .unauthorized)
                    }
                )
        }
    }



    @Test("POST /reservations bad id")
    func createReservationsBadID() async throws {
        try await withApp() { app in
            let token = try await getUserToken(app)
            let categoryID = try await getCategoryID(app)
            let _ = try await getWorkshopInDB(app , categoryID: categoryID)

            let reservationDTO = CreateReservationDTO(workshopID: UUID())

            try await app
                .testing()
                .test(
                    .POST,
                    "reservations",
                    beforeRequest: { req in
                        req.headers.bearerAuthorization = BearerAuthorization(token: token)
                        try req.content.encode(reservationDTO, as: .json)
                    },
                    afterResponse: { res async throws in
                        #expect(res.status == .notFound)
                    }
                )
        }
    }

    @Test("POST /reservations user already reserved")
    func createReservationUserAlreadyReserved() async throws {
        try await withApp() { app in
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app , categoryID: categoryID)
            let token = try await getTokenOfUserWithReservation(app, workshopID: workshop.id!)

            let reservationDTO = CreateReservationDTO(workshopID: workshop.id!)

            try await app.testing().test(
                .POST,
                "reservations",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(reservationDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("DELETE /reservations")
    func cancelReservation() async throws {
        try await withApp() { app in
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)
            let userID = try await getUserID(app)
            let reservationID = try await reserveWorkshop(app, workshopID: workshop.id!, userID: userID)
            let token = try await getUserToken(app, toCreate: false)

            try await app.testing().test(
                .DELETE,
                "reservations/\(reservationID)",
                beforeRequest: { req  in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let data = try res.content.decode(CreateReservationResponseDTO.self)
                    #expect(data.id == reservationID)
                    #expect(data.status == "cancelled")
                }
            )
        }
    }

    @Test("DELETE /workshops no id")
    func cancelReservationNoID() async throws {
        try await withApp() { app in
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)
            let userID = try await getUserID(app)
            let _ = try await reserveWorkshop(app, workshopID: workshop.id!, userID: userID)
            let token = try await getUserToken(app, toCreate: false)

            try await app.testing().test(
                .DELETE,
                "reservations/not_an_id",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("DELETE /workshops bad id")
    func cancelReservationBadID() async throws {
        try await withApp() { app in
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)
            let userID = try await getUserID(app)
            let _ = try await reserveWorkshop(app, workshopID: workshop.id!, userID: userID)
            let token = try await getUserToken(app, toCreate: false)

            try await app.testing().test(
                .DELETE,
                "reservations/\(UUID())",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
        }
    }

    @Test("DELETE /reservations no token")
    func cancelReservationsNoToken() async throws {
        try await withApp() { app in
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)
            let userID = try await getUserID(app)
            let _ = try await reserveWorkshop(app, workshopID: workshop.id!, userID: userID)

            try await app.testing().test(
                .DELETE,
                "reservations/\(UUID())",
                beforeRequest: { req in
                },
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }
}
