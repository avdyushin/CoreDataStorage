//
//  CoreDataStorage.swift
//
//  Created by Grigory Avdyushin on 20/05/2020.
//  Copyright © 2020 Grigory Avdyushin. All rights reserved.
//

import Combine
import CoreData

public struct CoreDataStorage {
    /// Main/UI context
    public var mainContext: NSManagedObjectContext { container.viewContext }
    /// Background context
    public let privateContext: NSManagedObjectContext
    /// Persistent container
    public let container: NSPersistentContainer

    public init(container: NSPersistentContainer) {
        self.container = container
        self.container.loadPersistentStores { storeDescription, error in
            debugPrint("CoreData: Inited \(storeDescription)")
            if let error = error {
                debugPrint("CoreData: Unresolved error \(error)")
                return
            }
        }
        self.container.viewContext.automaticallyMergesChangesFromParent = true
        self.privateContext = container.newBackgroundContext()
    }

    /// Performs given `block` on background context and calls `save()` if `hasChanges` is true.
    /// Calls `rollback()` in case of `save()` throws en error.
    public func performInBackgroundAndSave<T>(_ block: @escaping (NSManagedObjectContext) -> T) -> AnyPublisher<T, Error> {
        Future<T, Error> { [container] promise in
            container.performBackgroundTask { context in

                let result = block(context)

                guard context.hasChanges else {
                    promise(.success(result))
                    return
                }

                do {
                    try context.save()
                    promise(.success(result))
                } catch {
                    context.rollback()
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}
