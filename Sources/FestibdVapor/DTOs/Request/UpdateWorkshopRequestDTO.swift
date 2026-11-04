//
//  UpdateWorkshopRequestDTO.swift
//  FestibdVapor
//
//  Created by Apprenant76 on 29/10/2026.
//


import Fluent
import Vapor

struct UpdateWorkshopDTO: Content {

    var name: String
    var startTime: Date
    var endTime: Date
    var category_id: UUID
    var capacity: Int
    var totalSubscribers: Int
    var description: String
    
}

extension UpdateWorkshopDTO {

    func toModel() -> Workshop {
        let workshop = Workshop()
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
