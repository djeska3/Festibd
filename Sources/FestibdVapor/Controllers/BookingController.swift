//
//  BookingController.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 29/09/2026.
//
import Fluent
import Vapor

struct BookingController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let bookings = routes.grouped("bookings")
        bookings.post(use: create)
        bookings.get(":id", use: show)
        bookings.delete(":id", use: delete)
    }
    
    
    func create(req: Request) async throws -> BookingDTO {
        let booking = try req.content.decode(
            Booking.self
        )
        let maxCapacity = booking.workshop.maxCapacity
        let totalSubscribers = booking.workshop.totalSubscribers
        if totalSubscribers < maxCapacity {
            booking.status = "validated"
            booking.workshop.totalSubscribers += 1
        } else {
            booking.status = "pending"
        }
        try await booking.create(on: req.db)
        return try booking.toDTO()
    }
    
    func show(req: Request) async throws -> BookingDTO {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest, reason: "This ID isn't correct.")
        }
        guard let booking = try await Booking.find(id, on: req.db)
        else {
            throw Abort(.notFound, reason: "This workshop doesn't exist.")
        }
        return try booking.toDTO()
    }
    
    func update(req: Request) async throws -> BookingDTO {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest)
        }
        guard let booking = try await Booking.find(id, on: req.db)
        else {
            throw Abort(.notFound)
        }
        
        let newBooking = try req.content.decode(Booking.self)
        guard newBooking.status == "validated" else {
            throw Abort(.badRequest, reason: "Bad status.")
        }
        let maxCapacity = booking.workshop.maxCapacity
        let totalSubscribers = booking.workshop.totalSubscribers
        if totalSubscribers < maxCapacity {
            booking.status = "validated"
            booking.workshop.totalSubscribers += 1
            try await booking.update(on: req.db)
        }
        return try booking.toDTO()
    }
    
    func delete(req: Request) async throws -> BookingDTO {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest)
        }
        guard let booking = try await Booking.find(id, on: req.db)
        else {
            throw Abort(.notFound)
        }
        booking.status = "cancelled"
        booking.workshop.totalSubscribers -= 1
        try await booking.update(on: req.db)
        return try booking.toDTO()
    }
}
