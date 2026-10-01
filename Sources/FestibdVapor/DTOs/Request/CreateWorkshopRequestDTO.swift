//
//  CreateWorkshopDTO.swift
//  FestibdVapor
//
//  Created by ShoSho on 30/09/2026.
//

import Fluent
import Vapor

struct CreateWorkshopDTO: Content {
    
    var name: String
    var startTime: Date
    var endTime: Date
    var category_id: UUID
    var capacity: Int
    var totalSubscribers: Int
    var description: String
    
}

extension CreateWorkshopDTO {
    
    func toModel() -> Workshop {
        let workshop = Workshop()
        workshop.name = name
        workshop.startTime = startTime
        workshop.endTime = endTime
        workshop.$category.id = category_id
        workshop.maxCapacity = capacity
        workshop.totalSubscribers = 0
        workshop.description = description
        
      return workshop
    }
}
