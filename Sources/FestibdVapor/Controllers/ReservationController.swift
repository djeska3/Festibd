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
    
    func create(req: Request) async throws -> ReservationDTO {
        let dto = try req.content.decode(CreateReservationDTO.self)
        let reservation = dto.toModel()
        let maxCapacity = reservation.workshop.maxCapacity
        let totalSubscribers = reservation.workshop.totalSubscribers
        if totalSubscribers < maxCapacity {
            reservation.status = "validated"
            reservation.workshop.totalSubscribers += 1
        } else {
            reservation.status = "pending"
        }
        try await reservation.create(on: req.db)
        return try reservation.toDTO()
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
        
        let dto = try req.content.decode(ReservationDTO.self)
        let newReservation = dto.toModel()
        guard newReservation.status == "validated" else {
            throw Abort(.badRequest, reason: "Bad status.")
        }
        let maxCapacity = reservation.workshop.maxCapacity
        let totalSubscribers = reservation.workshop.totalSubscribers
        if totalSubscribers < maxCapacity {
            reservation.status = "validated"
            reservation.workshop.totalSubscribers += 1
            try await reservation.update(on: req.db)
        }
        return try reservation.toDTO()
    }
    
    func delete(req: Request) async throws -> ReservationDTO {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest)
        }
        guard let reservation = try await Reservation.find(id, on: req.db)
        else {
            throw Abort(.notFound)
        }
        reservation.status = "cancelled"
        reservation.workshop.totalSubscribers -= 1
        try await reservation.update(on: req.db)
        return try reservation.toDTO()
    }
}
