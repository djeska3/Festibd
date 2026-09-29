//
//  ManageWorkshopDTO.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 29/09/2026.
//
import Fluent
import Vapor

struct ManageWorkshopDTO: Content {
    
    var id: UUID
    var name: String
    var startTime: Date
    var endTime: Date
    var category: String
    var capacity: Int
    var totalSubscribers: Int
    var description: String
    var bookings: [WorkshopBookingDTO]
  
}


