//
//  CoreDataStorageTests.swift
//
//  Created by Grigory Avdyushin on 21/05/2020.
//  Copyright © 2020 Grigory Avdyushin. All rights reserved.
//
import XCTest
@testable import CoreDataModel
@testable import CoreDataStorage

final class CoreDataStorageTests: XCTestCase {

    private final class Item: NSManagedObject {
        @NSManaged var id: UUID
        @NSManaged var name: String?

        override func awakeFromInsert() {
            super.awakeFromInsert()
            id = UUID()
        }
    }

    private static let managedObjectModel = CoreDataModel {
        Entity(name: "Item", className: Item.self) {
            Property(name: "id", type: .UUIDAttributeType)
            Property(name: "name", type: .stringAttributeType, isOptional: true)
        }
    }.build()

    private var storage: CoreDataStorage!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let container = NSPersistentContainer(name: "Temp", managedObjectModel: CoreDataStorageTests.managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        storage = CoreDataStorage(container: container)

        XCTAssertNotNil(storage)
    }

    override func tearDownWithError() throws {
        storage = nil
        try super.tearDownWithError()
    }

    func testMainContextPerform() throws {
        XCTAssertTrue(try storage.mainContext.fetch(Item.fetchRequest()).isEmpty)
        let expectation = XCTestExpectation(description: "Created")
        storage.mainContext.perform { [storage] in
            let item = Item(context: storage!.mainContext)
            item.name = "Foo"
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
        let items: [Item] = try storage.mainContext.fetch(Item.fetchRequest()) as! [Item]
        XCTAssertEqual(items.first?.name, "Foo")
    }

    func testMainContextPerformAndWait() throws {
        XCTAssertTrue(try storage.mainContext.fetch(Item.fetchRequest()).isEmpty)
        storage.mainContext.performAndWait {
            let item = Item(context: storage.mainContext)
            item.name = "Bar"
            XCTAssertTrue(Thread.isMainThread)
        }
        let items: [Item] = try storage.mainContext.fetch(Item.fetchRequest()) as! [Item]
        XCTAssertEqual(items.first?.name, "Bar")
    }

    func testBackgroundContext() throws {

        func validate(objectID: NSManagedObjectID, id: UUID) {
            // Not exists in main context
            XCTAssertThrowsError(
                try storage!.mainContext.existingObject(with: objectID)
            )
            // Fetch item with given id
            let request = NSFetchRequest<Item>(entityName: "Item")
            request.predicate = NSPredicate(format: "%K == %@", #keyPath(Item.id), id as CVarArg)
            let items = try! storage!.mainContext.fetch(request)
            // Assert
            XCTAssertEqual(items.first?.name, "Baz")
        }

        let expectation = XCTestExpectation(description: "Saved")
        let cancellable = storage
            .performInBackgroundAndSave { context in
                XCTAssertFalse(Thread.isMainThread)
                let item = Item(context: context)
                item.name = "Baz"
                return (item.objectID, item.id)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    XCTAssertTrue(Thread.isMainThread)
                } else {
                    XCTFail()
                }
            }, receiveValue: { (objectID: NSManagedObjectID, id: UUID) in
                validate(objectID: objectID, id: id)
                expectation.fulfill()
            })
        wait(for: [expectation], timeout: 10)
        XCTAssertNotNil(cancellable)
    }

    static var allTests = [
        ("testMainContextPerform", testMainContextPerform),
        ("testMainContextWait", testMainContextPerformAndWait),
        ("testBackgroundContextSave", testBackgroundContext),
    ]
}
