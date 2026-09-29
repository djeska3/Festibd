//
//  CreateBookingDTO.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//
import Fluent
import Vapor

struct CreateBookingDTO: Content {
    
    var workshopID: UUID
    var userID: UUID
    
}

extension CreateBookingDTO {
    
    func toModel() -> Booking {
        let booking = Booking()
        booking.status = "pending"
        booking.$user.id = userID
        booking.$workshop.id = workshopID
        
      return booking
    }
}
