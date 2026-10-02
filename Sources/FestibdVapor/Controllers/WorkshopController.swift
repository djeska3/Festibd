//
//  WorkshopController.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 29/09/2026.
//
import Fluent
import Vapor
import JWT

struct WorkshopController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        let workshops = routes.grouped("workshops")
        
        let protectedRoutes = workshops.grouped(JWTMiddleware())
        protectedRoutes.get(use: index)
        protectedRoutes.post(use: create)
        protectedRoutes.get(":id", use: show)
        protectedRoutes.put(":id", use: update)
        protectedRoutes.delete(":id", use: delete)
        protectedRoutes.get("search", use: search)
    }

    func index(req: Request) async throws -> [WorkshopDTO] {
        let workshops = try await Workshop.query(on: req.db)
            .with(\.$category)
            .all()
        return workshops.map { $0.toDTO() }
    }

    func create(req: Request) async throws -> CreateWorkshopResponseDTO {
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
        return workshop.toCreateWorkshopResponseDTO()
    }

    func show(req: Request) async throws -> WorkshopDTO {
        guard let id = req.parameters.get("id", as: UUID.self)
                else {
            throw Abort(.badRequest, reason: "This ID isn't correct.")
        }
        guard let workshop = try await Workshop.query(on: req.db)
            .with(\.$category)
            .filter(\.$id == id)
            .first()
                else {
            throw Abort(.notFound, reason: "This workshop doesn't exist.")
        }
        return workshop.toDTO()
    }

    func update(req: Request) async throws -> CreateWorkshopResponseDTO {
        guard let id = req.parameters.get("id", as: UUID.self)
                else {
            throw Abort(.badRequest)
        }
        guard let workshop = try await Workshop.find(id, on: req.db)
                else {
            throw Abort(.notFound)
        }

        let workshopUpdateDTO = try req.content.decode(CreateWorkshopResponseDTO.self)
        guard !workshopUpdateDTO.name.isEmpty else {
            throw Abort(.badRequest, reason: "Name is required.")
        }
        guard workshopUpdateDTO.startTime
            .compare(workshopUpdateDTO.endTime) == .orderedAscending else {
            throw Abort(.badRequest, reason: "Your endTime must be after startTime.")
        }
        guard workshopUpdateDTO.maxCapacity > 0 else {
            throw Abort(.badRequest, reason : "Max capacity need to be greater than 0.")
        }
        guard workshopUpdateDTO.totalSubscribers >= 0 && workshopUpdateDTO.totalSubscribers <= workshopUpdateDTO.maxCapacity else {
            throw Abort(.badRequest , reason: "Total subscribers need to be greater or equal to 0, and lower or equal to Max capacity.")
        }
        guard !workshopUpdateDTO.description.isEmpty else {
            throw Abort(.badRequest , reason: "Description is required.")
        }

        workshop.name = workshopUpdateDTO.name
        workshop.startTime = workshopUpdateDTO.startTime
        workshop.endTime = workshopUpdateDTO.endTime
        workshop.maxCapacity = workshop.maxCapacity
        workshop.totalSubscribers = workshopUpdateDTO.totalSubscribers
        workshop.description = workshopUpdateDTO.description
        try await workshop.update(on: req.db)
        return workshop.toCreateWorkshopResponseDTO()
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
            throw Abort(.badRequest, reason: "Expect date parameter")
        }

        let workshops = try await Workshop
            .query(on: req.db)
            .with(\.$category)
            .filter(\.$startTime >= date)
            .filter(\.$startTime <= date.addingTimeInterval(3600 * 24))
            .all()

        return workshops.map{$0.toDTO()}
    }
}
