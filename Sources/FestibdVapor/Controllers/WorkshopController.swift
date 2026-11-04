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
        protectedRoutes.get(":id", use: show)
        protectedRoutes.get("search", use: search)
        protectedRoutes.get("has_reserved", ":id", use: hasUserReserved)

        let adminRoutes = protectedRoutes.grouped(RoleMiddleware())
        adminRoutes.post(use: create)
        adminRoutes.put(":id", use: update)
        adminRoutes.delete(":id", use: delete)
        adminRoutes.get("manage", ":id", use: manage)
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
        guard let _ = try await CategoryModel.find(dto.category_id, on: req.db) else {
            throw Abort(.badRequest, reason: "Bad category ID")
        }
        guard workshop.startTime.compare(workshop.endTime) == .orderedAscending else {
            throw Abort(.badRequest, reason: "Your endTime must be after startTime.")
        }
        guard workshop.maxCapacity > 0 else {
            throw Abort(.badRequest, reason : "Max capacity need to be greater than 0.")
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
            throw Abort(.notFound, reason: "Workshop not found")
        }
        guard let workshop = try await Workshop.find(id, on: req.db)
                else {
            throw Abort(.notFound)
        }

        let workshopUpdateDTO = try req.content.decode(UpdateWorkshopDTO.self)
        guard !workshopUpdateDTO.name.isEmpty else {
            throw Abort(.badRequest, reason: "Name is required.")
        }
        guard let _ = try await CategoryModel.find(workshopUpdateDTO.category_id, on: req.db) else {
            throw Abort(.badRequest, reason: "Bad category ID")
        }
        guard workshopUpdateDTO.startTime
            .compare(workshopUpdateDTO.endTime) == .orderedAscending else {
            throw Abort(.badRequest, reason: "Your endTime must be after startTime.")
        }
        guard workshopUpdateDTO.capacity > 0 else {
            throw Abort(.badRequest, reason : "Max capacity need to be greater than 0.")
        }
        guard workshopUpdateDTO.totalSubscribers >= 0 && workshopUpdateDTO.totalSubscribers <= workshopUpdateDTO.capacity else {
            throw Abort(.badRequest , reason: "Total subscribers need to be greater or equal to 0, and lower or equal to Max capacity.")
        }
        guard !workshopUpdateDTO.description.isEmpty else {
            throw Abort(.badRequest , reason: "Description is required.")
        }
        workshop.name = workshopUpdateDTO.name
        workshop.$category.id = workshopUpdateDTO.category_id
        workshop.startTime = workshopUpdateDTO.startTime
        workshop.endTime = workshopUpdateDTO.endTime
        workshop.maxCapacity = workshop.maxCapacity
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

    func manage(req: Request) async throws -> ManageWorkshopDTO {
        guard let id = req.parameters.get("id", as: UUID.self)
                else {
            throw Abort(.badRequest, reason: "This ID isn't correct.")
        }
        guard let workshop = try await Workshop
            .query(on: req.db)
            .with(\.$category)
            .filter(\.$id == id)
            .first() else {
            throw Abort(.notFound, reason: "This workshop doesn't exist")
        }

        let activeReservations = try await workshop.$reservations
            .query(on: req.db)
            .with(\.$user)
            .filter(\.$status != "cancelled")
            .all()


        return workshop.toManageWorkshopDTO(reservations: activeReservations)
    }

    func hasUserReserved(req: Request) async throws -> HasUserReservedDTO {

        guard let payload = req.auth.get(UserPayload.self) else {
            throw Abort(.unauthorized)
        }

        guard let workshopID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Missing workshop ID")
        }

        guard let workshop = try await Workshop
            .query(on: req.db)
            .with(\.$reservations)
            .filter(\.$id == workshopID)
            .first() else {
            throw Abort(.notFound, reason: "Workshop not found")
        }


        guard let reservation = try await workshop.$reservations
            .query(on: req.db)
            .with(\.$user)
            .filter(\.$user.$id == payload.id)
            .filter(\.$status != "cancelled")
            .first() else {
            return HasUserReservedDTO(hasReserved: false)
        }
        return HasUserReservedDTO(hasReserved: true, reservationID: reservation.id)
    }
}
