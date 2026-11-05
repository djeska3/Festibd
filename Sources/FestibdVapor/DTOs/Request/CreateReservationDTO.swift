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

}

extension CreateReservationDTO {
    
    func toModel() -> Reservation {
        let reservation = Reservation()
        reservation.status = "pending"
        reservation.$workshop.id = workshopID
        
      return reservation
    }
}
