//
//  CreateReservationResponseDTO.swift
//  FestibdVapor
//
//  Created by Apprenant76 on 01/10/2026.
//
import Vapor

struct CreateReservationResponseDTO: Content {
    let id: UUID?
    let status: String
    let userID: UUID?
    let workshopID: UUID?
}
