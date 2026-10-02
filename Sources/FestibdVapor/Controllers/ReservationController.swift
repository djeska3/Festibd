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
        protectedRoutes.post(use: create)
        protectedRoutes.get(":id", use: show)
        protectedRoutes.delete(":id", use: delete)
    }
    
    func create(req: Request) async throws -> CreateReservationResponseDTO {
        let newReservationDTO = try req.content.decode(CreateReservationDTO.self)
        guard let workshop = try await Workshop.find(newReservationDTO.workshopID, on: req.db) else {
            throw Abort(.badRequest, reason: ("Workshop id doesn't exist"))
        }
        let reservation = newReservationDTO.toModel()
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
    
    func show(req: Request) async throws -> ReservationDTO {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest, reason: "This ID isn't correct.")
        }
        guard let reservation = try await Reservation.find(id, on: req.db)
        else {
            throw Abort(.notFound, reason: "This reservation doesn't exist.")
        }
        return try reservation.toDTO()
    }
    
    func update(req: Request) async throws -> ReservationDTO {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest)
        }
        guard let reservation = try await Reservation.find(id, on: req.db)
        else {
            throw Abort(.notFound)
        }
        guard let workshop = try await Workshop.find(reservation.workshop.id, on: req.db) else {
            throw Abort(.badRequest, reason: ("Workshop id doesn't exist"))
        }
        let dto = try req.content.decode(UpdateReservationDTO.self)

        guard dto.status == "validated" else {
            throw Abort(.badRequest, reason: "Bad status.")
        }
        if workshop.totalSubscribers < workshop.maxCapacity {
            reservation.status = "validated"
            workshop.totalSubscribers += 1
            try await reservation.update(on: req.db)
            try await workshop.update(on: req.db)
        }
        return try reservation.toDTO()
    }
    
    func delete(req: Request) async throws -> CreateReservationResponseDTO {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest, reason: "ID expected")
        }
        guard let reservation = try await Reservation.find(id, on: req.db)
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
