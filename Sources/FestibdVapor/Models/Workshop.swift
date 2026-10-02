//
//  Workshop.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//

import Fluent
import Vapor
final class Workshop: Model, Content, @unchecked Sendable {

    static let schema = "workshops"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "start_time")
    var startTime: Date
    
    @Field(key: "end_time")
    var endTime: Date

    @Field(key: "max_capacity")
    var maxCapacity: Int
 
    @Field(key: "total_subscribers")
    var totalSubscribers: Int
    
    @Field(key: "description")
    var description: String
    
    @Children(for: \.$workshop)
    var reservations: [Reservation]

    @Parent(key: "category_id")
    var category: Category
    
    init() {}
    init(id: UUID? = nil, name: String, startTime: Date, endTime: Date, maxCapacity: Int, totalSubscribers: Int, description: String) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.maxCapacity = maxCapacity
        self.totalSubscribers = totalSubscribers
        self.description = description
    }
   
}

extension Workshop {
    
    func toDTO() -> WorkshopDTO {
        return WorkshopDTO(
            id: id,
            name: name,
            startTime: startTime,
            endTime: endTime,
            category_id: $category.id,
            category_name: category.name,
            capacity: maxCapacity,
            totalSubscribers: totalSubscribers,
            description: description
        )
    }
    
    func toManageWorkshop() throws -> ManageWorkshopDTO {
        return ManageWorkshopDTO(
            id: try requireID(),
            name: name,
            startTime: startTime,
            endTime: endTime,
            category_id: $category.id,
            category_name: $category.name,
            capacity: maxCapacity,
            totalSubscribers: totalSubscribers,
            description: description,
            reservations: try reservations.map { WorkshopReservationDTO(
                id: try requireID(),
                status: $0.status,
                username: $0.$user.name
            )}
        )
    }

    func toCreateWorkshopResponseDTO() -> CreateWorkshopResponseDTO {
        return CreateWorkshopResponseDTO(
            id: id,
            name: name,
            startTime: startTime,
            endTime: endTime,
            category_id: $category.id,
            maxCapacity: maxCapacity,
            totalSubscribers: totalSubscribers,
            description: description
        )
    }
}
