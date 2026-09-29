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
    var category: String
    var capacity: Int
    var totalSubscribers: Int
    var description: String
}
