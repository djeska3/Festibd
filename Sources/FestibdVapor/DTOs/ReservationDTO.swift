//
//  BookingDTO.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//
import Fluent
import Vapor

struct ReservationDTO: Content {
    var id: UUID
    var status: String
    var workshopName : String
    var workshopStartTime: Date
    var workshopEndTime: Date
    var workshopCategory: String
   
}

extension ReservationDTO {
    
    func toModel() -> Reservation {
        let reservation = Reservation()
        reservation.id = id
        reservation.status = status
        reservation.workshop.name = workshopName
        reservation.workshop.startTime = workshopStartTime
        reservation.workshop.endTime = workshopEndTime
        reservation.workshop.category.name = workshopCategory
        
      return reservation
    }
}
