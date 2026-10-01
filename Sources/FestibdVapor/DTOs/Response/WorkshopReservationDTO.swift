//
//  WorkshopReservationDTO.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 29/09/2026.
//

import Fluent
import Vapor

struct WorkshopReservationDTO: Content {
    
    var id: UUID
    var status: String
    var username: String
}
