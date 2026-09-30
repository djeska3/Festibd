//
//  Reservation.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//
import Fluent
import Vapor
final class Reservation: Model, Content, @unchecked Sendable {

    static let schema = "reservations"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "status")
    var status: String
    
   @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "workshop_id")
    var workshop: Workshop
    
    init() {}
    init(id: UUID? = nil, status: String) {
        self.id = id
        self.status = status
        
    }
   
}

extension Reservation {
    
    func toDTO() throws -> ReservationDTO {
        return ReservationDTO(id: try requireID(), status: status, workshopeName: workshop.name, workshopStartTime: workshop.startTime, workshopEndTime: workshop.endTime, workshopCategory: workshop.$category.name)
   
    }
    
    
}
