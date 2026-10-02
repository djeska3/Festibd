//
//  CreateBookingDTO.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//
import Fluent
import Vapor

struct CreateReservationDTO: Content {
    
    var workshopID: UUID
    var userID: UUID
    
}

extension CreateReservationDTO {
    
    func toModel() -> Reservation {
        let reservation = Reservation()
        reservation.status = "pending"
        reservation.$user.id = userID
        reservation.$workshop.id = workshopID
        
      return reservation
    }
}
