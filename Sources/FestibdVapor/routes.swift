import Fluent
import Vapor

func routes(_ app: Application) throws {

    try app.routes.register(collection: CategoryController())
    try app.routes.register(collection: ReservationController())
    try app.routes.register(collection: WorkshopController())
    try app.routes.register(collection: UserController())
}
