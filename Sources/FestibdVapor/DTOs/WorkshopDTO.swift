//
//  WorkshopDTO.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//
import Fluent
import Vapor

struct WorkshopDTO: Content {

    var id: UUID
    var name: String
    var startTime: Date
    var endTime: Date
    var category_id: UUID
    var category_name: String
    var capacity: Int
    var totalSubscribers: Int
    var description: String
}

extension WorkshopDTO {

    func toModel() throws -> Workshop {
        let workshop = Workshop()
        workshop.id = id
        workshop.name = name
        workshop.startTime = startTime
        workshop.endTime = endTime
        workshop.$category.id = category_id
        workshop.maxCapacity = capacity
        workshop.totalSubscribers = totalSubscribers
        workshop.description = description

        return workshop
    }
}
