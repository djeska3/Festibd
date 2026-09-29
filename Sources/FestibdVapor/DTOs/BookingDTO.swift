//
//  BookingDTO.swift
//  FestibdVapor
//
//  Created by Apprenant 85 on 28/09/2026.
//
import Fluent
import Vapor

struct BookingDTO: Content {
    var id: UUID
    var status: String
    var workshopeName : String
    var workshopStartTime: Date
    var workshopEndTime: Date
    var workshopCategory: String
   
}
