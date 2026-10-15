//
//  JWTMiddleware.swift
//  FestibdVapor
//
//  Created by ShoSho on 02/10/2026.
//

import Vapor
import JWT

final class JWTMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        //
        guard let token = request.headers.bearerAuthorization?.token else {
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "Missing token."))
        }
        guard let jwtKey = Environment.get("JWT_KEY") else {
            return request.eventLoop.future(error: Abort(.internalServerError, reason: "JWT key not found"))
        }
        let signer = JWTSigner.hs256(key: jwtKey) //
        let payload: UserPayload
        
        do {
            //
            payload = try signer.verify(String(token), as: UserPayload.self)
        } catch {
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "Invalid token."))
        }
        //
        request.auth.login(payload)
        //
        return next.respond(to: request)
    }
}
