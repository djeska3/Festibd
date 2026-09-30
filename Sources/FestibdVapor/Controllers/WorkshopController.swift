//
//  WorkshopController.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 29/09/2026.
//
import Fluent
import Vapor

struct WorkshopController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let workshops = routes.grouped("workshops")
        workshops.get(use: index)
        workshops.post(use: create)
        workshops.get(":id", use: show)
        workshops.put(":id", use: update)
        workshops.delete(":id", use: delete)
    }
    
    func index(req: Request) async throws -> [Workshop] {
        return try await Workshop.query(on: req.db).all()
    }
    
    func create(req: Request) async throws -> WorkshopDTO {
        let dto = try req.content.decode(CreateWorkshopDTO.self)
        let workshop = dto.toModel()
        guard !workshop.name.isEmpty else {
            throw Abort(.badRequest, reason: "Name is required.")
        }
        guard workshop.startTime.compare(workshop.endTime) == .orderedAscending else {
            throw Abort(.badRequest, reason: "Your endTime must be after startTime.")
        }
        guard workshop.maxCapacity > 0 else {
            throw Abort(.badRequest, reason : "Max capacity need to be greater than 0.")
        }
        guard workshop.totalSubscribers >= 0 && workshop.totalSubscribers <= workshop.maxCapacity else {
            throw Abort(.badRequest , reason: "Total subscribers need to be greater or equal to 0, and lower or equal to Max capacity.")
        }
        guard !workshop.description.isEmpty else {
            throw Abort(.badRequest , reason: "Description is required.")
        }
        try await workshop.create(on: req.db)
        return try workshop.toDTO()
    }
    
    func show(req: Request) async throws -> WorkshopDTO {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest, reason: "This ID isn't correct.")
        }
        guard let workshop = try await Workshop.find(id, on: req.db)
        else {
            throw Abort(.notFound, reason: "This workshop doesn't exist.")
        }
        return try workshop.toDTO()
    }
    
    func update(req: Request) async throws -> WorkshopDTO {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest)
        }
        guard let workshop = try await Workshop.find(id, on: req.db)
        else {
            throw Abort(.notFound)
        }
        
        let dto = try req.content.decode(WorkshopDTO.self)
        let newWorkshop = dto.toModel()
        guard !newWorkshop.name.isEmpty else {
            throw Abort(.badRequest, reason: "Name is required.")
        }
        guard newWorkshop.startTime.compare(newWorkshop.endTime) == .orderedAscending else {
            throw Abort(.badRequest, reason: "Your endTime must be after startTime.")
        }
        guard newWorkshop.maxCapacity > 0 else {
            throw Abort(.badRequest, reason : "Max capacity need to be greater than 0.")
        }
        guard newWorkshop.totalSubscribers >= 0 && newWorkshop.totalSubscribers <= newWorkshop.maxCapacity else {
            throw Abort(.badRequest , reason: "Total subscribers need to be greater or equal to 0, and lower or equal to Max capacity.")
        }
        guard !newWorkshop.description.isEmpty else {
            throw Abort(.badRequest , reason: "Description is required.")
        }
        
        workshop.name = newWorkshop.name
        workshop.startTime = newWorkshop.startTime
        workshop.endTime = newWorkshop.endTime
        workshop.maxCapacity = workshop.maxCapacity
        workshop.totalSubscribers = newWorkshop.totalSubscribers
        workshop.description = newWorkshop.description
        try await workshop.update(on: req.db)
        return try workshop.toDTO()
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self)
        else {
            throw Abort(.badRequest)
        }
        guard let workshop = try await Workshop.find(id, on: req.db)
        else {
            throw Abort(.notFound)
        }
        try await workshop.delete(on: req.db)
        return .noContent
    }
    
    func search(req: Request) async throws -> [WorkshopDTO] {
        guard let date: Date = req.query["date"] else {
            throw Abort(.badRequest)
        }
        
        let workshops = try await Workshop
            .query(on: req.db)
            .filter(\.$startTime == date)
            .all()
        
        return try workshops.map{try $0.toDTO()}
    }
}
