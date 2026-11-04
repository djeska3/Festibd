//
//  BookingController.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 29/09/2026.
//
import Fluent
import Vapor

struct ReservationController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        let reservations = routes.grouped("reservations")
        let protectedRoutes = reservations.grouped(JWTMiddleware())
        protectedRoutes.get(use: index)
        protectedRoutes.post(use: create)
        protectedRoutes.delete(":id", use: delete)
    }

    func index(req: Request) async throws -> [ReservationDTO] {
        guard let payload = req.auth.get(UserPayload.self) else {
            throw Abort(.unauthorized)
        }
        let reservations = try await Reservation
            .query(on: req.db)
            .with(\.$user)
            .with(\.$workshop, { workshop in
                workshop.with(\.$category)
            })
                .filter(\.$user.$id == payload.id)
                .filter(\.$status != "cancelled")
                .all()
        return reservations.map { $0.toDTO() }
    }

    func create(req: Request) async throws -> CreateReservationResponseDTO {
        let payload = try req.auth.require(UserPayload.self)
        guard let _ = try await User.find(payload.id, on: req.db) else {
            throw Abort(.notFound, reason: "User doesn't exist")
        }
        let newReservationDTO = try req.content.decode(CreateReservationDTO.self)
        guard let workshop = try await Workshop.find(newReservationDTO.workshopID, on: req.db) else {
            throw Abort(.notFound, reason: ("Workshop id doesn't exist"))
        }
        guard try await Reservation.query(on: req.db)
            .filter(\.$user.$id == payload.id)
            .filter(\.$workshop.$id == newReservationDTO.workshopID)
            .filter(\.$status != "cancelled")
            .count() == 0 else {
            throw Abort(.badRequest, reason: "The user already have a reservation")
        }
        let reservation = newReservationDTO.toModel()
        reservation.$user.id = payload.id
        let maxCapacity = workshop.maxCapacity
        let totalSubscribers = workshop.totalSubscribers
        if totalSubscribers < maxCapacity {
            reservation.status = "validated"
            workshop.totalSubscribers += 1
        } else {
            reservation.status = "pending"
        }
        try await reservation.create(on: req.db)
        try await workshop.update(on: req.db)
        return reservation.toCreateReservationResponseDTO()
    }

    func delete(req: Request) async throws -> CreateReservationResponseDTO {
        guard let id = req.parameters.get("id", as: UUID.self)
                else {
            throw Abort(.badRequest, reason: "ID expected")
        }
        guard let reservation = try await Reservation.query(on: req.db)
            .with(\.$workshop, { workshop in
                workshop.with(\.$category)
            })
                .filter(\.$id == id)
                .first()
                else {
            throw Abort(.notFound, reason: "Reservation not found")
        }
        guard let workshop = try await Workshop.find(reservation.$workshop.id, on: req.db) else {
            throw Abort(.notFound, reason: "Workshop not found")
        }
        reservation.status = "cancelled"
        workshop.totalSubscribers -= 1
        try await reservation.update(on: req.db)
        try await workshop.update(on: req.db)
        return reservation.toCreateReservationResponseDTO()
    }

}
