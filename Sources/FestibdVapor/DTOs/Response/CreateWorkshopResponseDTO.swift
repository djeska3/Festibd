//
//  CreateWorkshopResponseDTO.swift
//  FestibdVapor
//
//  Created by Apprenant76 on 01/10/2026.
//

import Fluent
import Vapor

struct CreateWorkshopResponseDTO: Content {

    var id: UUID?
    var name: String
    var startTime: Date
    var endTime: Date
    var category_id: UUID?
    var maxCapacity: Int
    var totalSubscribers: Int
    var description: String
    
}
