//
//  WorkshopControllerTests.swift
//  FestibdVapor
//
//  Created by Apprenant76 on 03/11/2026.
//

@testable import FestibdVapor
import VaporTesting
import Testing
import Fluent

@Suite("WorkshopController tests", .serialized)
struct WorkshopControllerTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        setenv("JWT_KEY", "test-secret-key", 1)
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await app.autoRevert()
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    @Test("POST /workshops")
    func createWorkshop() async throws {
        try await withApp { app  in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)

            let workshopDTO = CreateWorkshopDTO(
                name: "workshop",
                startTime: Date(),
                endTime: Date().addingTimeInterval(1800),
                category_id: categoryID,
                capacity: 15,
                totalSubscribers: 0,
                description: "description"
            )

            try await app.testing().test(
                .POST,
                "workshops",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(workshopDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let data = try res.content.decode(CreateWorkshopResponseDTO.self)
                    #expect(data.id != nil)
                    #expect(data.name == workshopDTO.name)
                    #expect(data.category_id == workshopDTO.category_id)
                    #expect(
                        Calendar.current
                            .compare(
                                data.startTime,
                                to: workshopDTO.startTime,
                                toGranularity: .second
                            ) == .orderedSame
                    )
                    #expect(
                        Calendar.current
                            .compare(
                                data.endTime,
                                to: workshopDTO.endTime,
                                toGranularity: .second
                            ) == .orderedSame
                    )
                    #expect(data.maxCapacity == workshopDTO.capacity)
                    #expect(data.totalSubscribers == workshopDTO.totalSubscribers)
                    #expect(data.description == workshopDTO.description)
                }
            )
        }
    }

    @Test("POST /workshops no token")
    func createWorkshopNoToken() async throws {
        try await withApp { app  in
            try await app
                .testing()
                .test(
                    .POST,
                    "workshops",
                    afterResponse: {res async throws in
                        #expect(res.status == .unauthorized)
                    }
                )
        }
    }

    @Test("POST /workshops not authorized")
    func createWorkshopNotAuthorized() async throws {
        try await withApp { app  in
            let token = try await getUserToken(app)

            try await app
                .testing()
                .test(
                    .POST,
                    "workshops",
                    beforeRequest: {req in
                        req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    },
                    afterResponse: {res async throws in
                        #expect(res.status == .forbidden)
                    }
                )
        }
    }

    @Test("POST /workshops: bad name")
    func createWorkshopBadName() async throws {
        try await withApp { app  in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)

            let workshopDTO = CreateWorkshopDTO(
                name: "",
                startTime: Date(),
                endTime: Date().addingTimeInterval(1800),
                category_id: categoryID,
                capacity: 15,
                totalSubscribers: 0,
                description: "description"
            )

            try await app.testing().test(
                .POST,
                "workshops",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(workshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("POST /workshops: bad times")
    func createWorkshopBadTimes() async throws {
        try await withApp { app  in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)

            let workshopDTO = CreateWorkshopDTO(
                name: "workshop",
                startTime: Date().addingTimeInterval(1800),
                endTime: Date(),
                category_id: categoryID,
                capacity: 15,
                totalSubscribers: 0,
                description: "description"
            )

            try await app.testing().test(
                .POST,
                "workshops",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(workshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("POST /workshops: bad category id")
    func createWorkshopBadCategory() async throws {
        try await withApp { app  in
            let token = try await getStaffToken(app)

            let workshopDTO = CreateWorkshopDTO(
                name: "workshop",
                startTime: Date(),
                endTime: Date().addingTimeInterval(1800),
                category_id: UUID(),
                capacity: 15,
                totalSubscribers: 0,
                description: "description"
            )

            try await app.testing().test(
                .POST,
                "workshops",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(workshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }

    }

    @Test("POST /workshops: bad capacity")
    func createWorkshopBadCapacity() async throws {
        try await withApp { app  in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)

            let workshopDTO = CreateWorkshopDTO(
                name: "workshop",
                startTime: Date(),
                endTime: Date().addingTimeInterval(1800),
                category_id: categoryID,
                capacity: -10,
                totalSubscribers: 0,
                description: "description"
            )

            try await app.testing().test(
                .POST,
                "workshops",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(workshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }

    }

    @Test("POST /workshops: bad description")
    func createWorkshopBadDescription() async throws {
        try await withApp { app  in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)

            let workshopDTO = CreateWorkshopDTO(
                name: "workshop",
                startTime: Date(),
                endTime: Date().addingTimeInterval(1800),
                category_id: categoryID,
                capacity: 15,
                totalSubscribers: 0,
                description: ""
            )

            try await app.testing().test(
                .POST,
                "workshops",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(workshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("GET /workshops")
    func getWorkshops() async throws {
        try await withApp() { app in
            let token = try await getUserToken(app)
            let categoryID = try await getCategoryID(app)
            let workshops = try await addWorkshopsInDb(app, categoryID: categoryID)

            try await app.testing().test(
                .GET,
                "workshops",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let data = try res.content.decode([WorkshopDTO].self)
                    for i in 0...3 {
                        #expect(data[i].id != nil)
                        #expect(data[i].name == workshops[i].name)
                        #expect(
                            Calendar.current
                                .compare(
                                    data[i].startTime,
                                    to: workshops[i].startTime,
                                    toGranularity: .second
                                ) == .orderedSame
                        )
                        #expect(
                            Calendar.current
                                .compare(
                                    data[i].endTime,
                                    to: workshops[i].endTime,
                                    toGranularity: .second
                                ) == .orderedSame
                        )
                        #expect(data[i].capacity == workshops[i].maxCapacity)
                        #expect(data[i].totalSubscribers == workshops[i].totalSubscribers)
                        #expect(data[i].description == workshops[i].description)
                    }
                })
        }
    }

    @Test("GET /workshops no token")
    func getWorkshopNoToken() async throws {
        try await withApp { app in

            try await app.testing().test(
                .GET,
                "workshops",
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }

    @Test("GET /workshops/:id")
    func getOneWorkshop() async throws {
        try await withApp() { app in
            let token = try await getUserToken(app)
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)

            try await app.testing().test(
                .GET,
                "workshops/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let data = try res.content.decode(WorkshopDTO.self)
                    #expect(data.id == workshop.id!)
                    #expect(data.name == workshop.name)
                    #expect(data.category_id == workshop.$category.id)
                    #expect(
                        Calendar.current
                            .compare(
                                data.startTime,
                                to: workshop.startTime,
                                toGranularity: .second
                            ) == .orderedSame
                    )
                    #expect(
                        Calendar.current
                            .compare(
                                data.endTime,
                                to: workshop.endTime,
                                toGranularity: .second
                            ) == .orderedSame
                    )
                    #expect(data.capacity == workshop.maxCapacity)
                    #expect(data.totalSubscribers == workshop.totalSubscribers)
                    #expect(data.description == workshop.description)
                }
            )
        }
    }

    @Test("GET /workshops/:id no token")
    func getWorkshopByIDNoToken() async throws {
        try await withApp { app in

            try await app.testing().test(
                .GET,
                "workshops/\(UUID())",
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }

    @Test("GET /workshops/:id bad id")
    func getOneWorkshopBadId() async throws {
        try await withApp() { app in
            let token = try await getUserToken(app)

            try await app.testing().test(
                .GET,
                "workshops/\(UUID())",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                })
        }
    }


    @Test("PUT /workshops")
    func updateWorkshop() async throws  {
        try await withApp { app in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)

            let updateDTO = UpdateWorkshopDTO(
                name: "updated workshop",
                startTime: workshop.startTime,
                endTime: workshop.endTime,
                category_id: workshop.$category.id,
                capacity: workshop.maxCapacity,
                totalSubscribers: workshop.totalSubscribers,
                description: workshop.description
            )

            try await app.testing().test(
                .PUT,
                "workshops/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(updateDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let data = try res.content.decode(CreateWorkshopResponseDTO.self)
                    #expect(data.id == workshop.id!)
                    #expect(data.name == updateDTO.name)
                    #expect(data.category_id == workshop.$category.id)
                    #expect(
                        Calendar.current
                            .compare(
                                data.startTime,
                                to: updateDTO.startTime,
                                toGranularity: .second
                            ) == .orderedSame
                    )
                    #expect(
                        Calendar.current
                            .compare(
                                data.endTime,
                                to: updateDTO.endTime,
                                toGranularity: .second
                            ) == .orderedSame
                    )
                    #expect(data.maxCapacity == updateDTO.capacity)
                    #expect(data.totalSubscribers == updateDTO.totalSubscribers)
                    #expect(data.description == updateDTO.description)
                }
            )
        }
    }

    @Test("PUT /workshops no token")
    func updateWorkshopNoToken() async throws {
        try await withApp { app in
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)

            let updateDTO = UpdateWorkshopDTO(
                name: "updated workshop",
                startTime: workshop.startTime,
                endTime: workshop.endTime,
                category_id: workshop.$category.id,
                capacity: workshop.maxCapacity,
                totalSubscribers: workshop.totalSubscribers,
                description: workshop.description
            )

            try await app.testing().test(
                .PUT,
                "workshops/\(UUID())",
                beforeRequest: {req in
                    try req.content.encode(updateDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }

    @Test("PUT /workshops not authorized")
    func updateWorkshopNotAuthorized() async throws {
        try await withApp { app in
            let token = try await getUserToken(app)
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)

            let updateDTO = UpdateWorkshopDTO(
                name: "updated workshop",
                startTime: workshop.startTime,
                endTime: workshop.endTime,
                category_id: workshop.$category.id,
                capacity: workshop.maxCapacity,
                totalSubscribers: workshop.totalSubscribers,
                description: workshop.description
            )

            try await app.testing().test(
                .PUT,
                "workshops/\(UUID())",
                beforeRequest: {req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(updateDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .forbidden)
                }
            )
        }
    }

    @Test("PUT /workshops/:id bad id")
    func updateWorkshopBadID() async throws {
        try await withApp { app in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)
            let updateDTO = UpdateWorkshopDTO(
                name: "updated workshop",
                startTime: Date(),
                endTime: Date().addingTimeInterval(1800),
                category_id: categoryID,
                capacity: 15,
                totalSubscribers: 0,
                description: ""
            )

            try await app.testing().test(
                .PUT,
                "workshops/bad_id",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(updateDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
        }
    }

    @Test("PUT /workshops/:id bad name")
    func updateWorkshopBadName() async throws {
        try await withApp { app in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)
            let updateDTO = UpdateWorkshopDTO(
                name: "",
                startTime: workshop.startTime,
                endTime: workshop.endTime,
                category_id: workshop.$category.id,
                capacity: workshop.maxCapacity,
                totalSubscribers: workshop.totalSubscribers,
                description: workshop.description
            )

            try await app.testing().test(
                .PUT,
                "workshops/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(updateDTO, as:.json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("PUT /workshops/:id bad category")
    func updateWorkshopBadCategory() async throws {
        try await withApp { app in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)
            let updateDTO = UpdateWorkshopDTO(
                name: "updated workshop",
                startTime: workshop.startTime,
                endTime: workshop.endTime,
                category_id: UUID(),
                capacity: workshop.maxCapacity,
                totalSubscribers: workshop.totalSubscribers,
                description: workshop.description
            )

            try await app.testing().test(
                .PUT,
                "workshops/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(updateDTO, as:.json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("PUT /workshops/:id bad times")
    func updateWorkshopBadTimes() async throws {
        try await withApp { app in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)

            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)
            let updateDTO = UpdateWorkshopDTO(
                name: "updated workshop",
                startTime: workshop.endTime,
                endTime: workshop.startTime,
                category_id: workshop.$category.id,
                capacity: workshop.maxCapacity,
                totalSubscribers: workshop.totalSubscribers,
                description: workshop.description
            )
            try await app.testing().test(
                .PUT,
                "workshops/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(updateDTO, as:.json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("PUT /workshops/:id bad capacity")
    func updateWorkshopBadCapacity() async throws {
        try await withApp { app in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)

            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)
            let updateDTO = UpdateWorkshopDTO(
                name: "updated workshop",
                startTime: workshop.startTime,
                endTime: workshop.endTime,
                category_id: workshop.$category.id,
                capacity: -10,
                totalSubscribers: workshop.totalSubscribers,
                description: workshop.description
            )

            try await app.testing().test(
                .PUT,
                "workshops/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(updateDTO, as:.json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("PUT /workshops/:id bad description")
    func updateWorkshopBadDescription() async throws {
        try await withApp { app in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)
            let updateDTO = UpdateWorkshopDTO(
                name: "updated workshop",
                startTime: workshop.startTime,
                endTime: workshop.endTime,
                category_id: workshop.$category.id,
                capacity: workshop.maxCapacity,
                totalSubscribers: workshop.totalSubscribers,
                description: ""
            )

            try await app.testing().test(
                .PUT,
                "workshops/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(updateDTO, as:.json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("GET /workshops/search")
    func getWorkshopByDay() async throws {
        try await withApp() { app in
            let token = try await getUserToken(app)
            let categoryID = try await getCategoryID(app)
            let todayWorkshop = try await addWorkshopsInDbMultiDays(app, categoryID: categoryID)

            try await app.testing().test(
                .GET,
                "workshops/search?date=\(Date().ISO8601Format())",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let data = try res.content.decode([WorkshopDTO].self)
                    #expect(data.count == 1)
                    #expect(data.first!.id == todayWorkshop.id!)
                    #expect(data.first!.name == todayWorkshop.name)
                    #expect(data.first!.category_id == todayWorkshop.$category.id)
                    #expect(
                        Calendar.current
                            .compare(
                                data.first!.startTime,
                                to: todayWorkshop.startTime,
                                toGranularity: .second
                            ) == .orderedSame
                    )
                    #expect(
                        Calendar.current
                            .compare(
                                data.first!.endTime,
                                to: todayWorkshop.endTime,
                                toGranularity: .second
                            ) == .orderedSame
                    )
                    #expect(data.first!.capacity == todayWorkshop.maxCapacity)
                    #expect(data.first!.totalSubscribers == todayWorkshop.totalSubscribers)
                    #expect(data.first!.description == todayWorkshop.description)
                }
            )
        }
    }

    @Test("GET /workshop/search no token")
    func getWorkshopByDayNoToken() async throws {
        try await withApp() { app in
            let categoryID = try await getCategoryID(app)
            let _ = try await addWorkshopsInDbMultiDays(app, categoryID: categoryID)

            try await app.testing().test(
                .GET,
                "workshops/search?date=\(Date().ISO8601Format())",
                beforeRequest: { req in
                },
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)
                })
        }
    }

    @Test("GET /workshops/search no query parameters")
    func getWorkshopByDayNoQuery() async throws {
        try await withApp() { app in
            let token = try await getUserToken(app)
            let _ = try await getCategoryID(app)

            try await app.testing().test(
                .GET,
                "workshops/search",
                beforeRequest: {req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("GET /workshops/search bad date format")
    func getWorkshopByDayBadFormat() async throws {
        try await withApp() { app in
            let token = try await getUserToken(app)
            let _ = try await getCategoryID(app)

            try await app.testing().test(
                .GET,
                "workshops/search=date=\(Date())",
                beforeRequest: {req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("DELETE /workshops/id")
    func deleteWorkshop() async throws {
        try await withApp { app in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)

            try await app
                .testing()
                .test(
                    .DELETE,
                    "workshops/\(workshop.id!)",
                    beforeRequest: { req in
                        req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    },
                    afterResponse: { res async throws in
                        #expect(res.status == .noContent)
                    }
                )
        }
    }

    @Test("DELETE /workshops/id No Token")
    func deleteWorkshopNoToken() async throws {
        try await withApp { app in
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)

            try await app
                .testing()
                .test(
                    .DELETE,
                    "workshops/\(workshop.id!)",
                    afterResponse: { res async throws in
                        #expect(res.status == .unauthorized)
                    }
                )
        }
    }

    @Test("DELETE /workshops/id Not Authorized")
    func deleteWorkshopNotAuthorized() async throws {
        try await withApp { app in
            let token = try await getUserToken(app)
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)

            try await app
                .testing()
                .test(
                    .DELETE,
                    "workshops/\(workshop.id!)",
                    beforeRequest: { req in
                        req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    },
                    afterResponse: { res async throws in
                        #expect(res.status == .forbidden)
                    }
                )
        }
    }

    @Test("DELETE /workshops/id no id")
    func deleteWorkshopNoId() async throws {
        try await withApp { app in
            let token = try await getStaffToken(app)

            try await app
                .testing()
                .test(
                    .DELETE,
                    "workshops/not_an_id",
                    beforeRequest: { req in
                        req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    },
                    afterResponse: { res async throws in
                        #expect(res.status == .badRequest)
                    }
                )
        }
    }

    @Test("DELETE /workshops/id bad id")
    func deleteWorkshopBadId() async throws {
        try await withApp { app in
            let token = try await getStaffToken(app)

            try await app
                .testing()
                .test(
                    .DELETE,
                    "workshops/\(UUID())",
                    beforeRequest: { req in
                        req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    },
                    afterResponse: { res async throws in
                        #expect(res.status == .notFound)
                    }
                )
        }
    }

    @Test("GET /workshops/manage")
    func getWorkshopsManage() async throws {
        try await withApp() { app  in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)

            try await app.testing().test(
                .GET,
                "workshops/manage/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let data = try res.content.decode(ManageWorkshopDTO.self)
                    #expect(data.id != nil)
                    #expect(data.name == workshop.name)
                    #expect(Calendar.current.compare(
                        data.startTime,
                        to: workshop.startTime,
                        toGranularity: .second
                    ) == .orderedSame)
                    #expect(Calendar.current.compare(
                        data.endTime,
                        to: workshop.endTime,
                        toGranularity: .second
                    ) == .orderedSame)
                    #expect(data.category_id == workshop.$category.id)
                    #expect(data.category_name == workshop.$category.name)
                    #expect(data.capacity == workshop.maxCapacity)
                    #expect(data.totalSubscribers == workshop.totalSubscribers)
                    #expect(data.description == workshop.description)
                    for j in 0..<data.reservations.count {
                        #expect(data.reservations[j].id != nil)
                        #expect(
                            data.reservations[j].status ==
                            workshop.reservations[j].status
                        )
                        #expect(
                            data.reservations[j].username ==
                            workshop.reservations[j].user.username
                        )
                    }
                }
            )
        }
    }

    @Test("GET /workshops/manage no token")
    func getManageWorkshopNoToken() async throws {
        try await withApp() { app in
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)

            try await app.testing().test(
                .GET,
                "workshops/manage/\(workshop.id!)",
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }

    @Test("GET /workshops/manage not authorized")
    func getManageWorkshopNotAuthorized() async throws {
        try await withApp() { app in
            let token = try await getUserToken(app)
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)

            try await app.testing().test(
                .GET,
                "workshops/manage/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .forbidden)
                }
            )
        }
    }

    @Test("GET /workshops/manage no id")
    func getManageWorkshopNoID() async throws {
        try await withApp() { app in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)
            let _ = try await getWorkshopInDB(app, categoryID: categoryID)

            try await app.testing().test(
                .GET,
                "workshops/manage/not_an_id",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }

    @Test("GET /workshops/manage bad id")
    func getManageWorkshopBadID() async throws {
        try await withApp() { app in
            let token = try await getStaffToken(app)
            let categoryID = try await getCategoryID(app)
            let _ = try await getWorkshopInDB(app, categoryID: categoryID)

            try await app.testing().test(
                .GET,
                "workshops/manage/\(UUID())",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
        }
    }

    @Test("GET /workshops/has_reserved no reservation")
    func hasUserReservedNoReservation() async throws {
        try await withApp() { app in
            let categoryID = try await getCategoryID(app)
            let token = try await getUserToken(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)

            try await app.testing().test(
                .GET,
                "workshops/has_reserved/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let data = try res.content.decode(HasUserReservedDTO.self)
                    #expect(data.hasReserved == false)
                }
            )
        }
    }


    @Test("GET /workshops/has_reserved reserved")
    func hasUserReservedReserved() async throws {
        try await withApp() { app in
            let categoryID = try await getCategoryID(app)
            let userID = try await getUserID(app)
            let token = try await getUserToken(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)
            let reservationID = try await reserveWorkshop(app, workshopID: workshop.id!, userID: userID)

            try await app.testing().test(
                .GET,
                "workshops/has_reserved/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let data = try res.content.decode(HasUserReservedDTO.self)
                    #expect(data.hasReserved == true)
                    #expect(data.reservationID == reservationID)
                }
            )
        }
    }

    @Test("GET /workshops/has_reserved no token")
    func hasUserReservedNoToken() async throws {
        try await withApp() { app in
            let categoryID = try await getCategoryID(app)
            let workshop = try await getWorkshopInDB(app, categoryID: categoryID)

            try await app.testing().test(
                .GET,
                "workshops/has_reserved/\(workshop.id!)",
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }

    @Test("GET /workshops/has_reserved bad id")
    func hasUserReservedBadID() async throws {
        try await withApp() { app in
            let categoryID = try await getCategoryID(app)
            _ = try await getWorkshopInDB(app, categoryID: categoryID)
            let token = try await getUserToken(app)

            try await app.testing().test(
                .GET,
                "workshops/has_reserved/\(UUID())",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
        }
    }

    @Test("GET /workshops/has_reserved no id")
    func hasUserReservedNoID() async throws {
        try await withApp() { app in
            let categoryID = try await getCategoryID(app)
            _ = try await getWorkshopInDB(app, categoryID: categoryID)
            let token = try await getUserToken(app)

            try await app.testing().test(
                .GET,
                "workshops/has_reserved/not_an_id)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }
}
