//
//  HasUserReservedDTO.swift
//  FestibdVapor
//
//  Created by Apprenant76 on 02/11/2026.
//

import Vapor

struct HasUserReservedDTO: Content {
    var hasReserved: Bool
    var reservationID: UUID?
}
