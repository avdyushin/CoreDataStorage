//
//  CoreDataStorage.swift
//
//  Created by Grigory Avdyushin on 20/05/2020.
//  Copyright © 2020 Grigory Avdyushin. All rights reserved.
//

import Combine
import CoreData

public struct CoreDataStorage {

    public enum Context {
        case main, background
    }

    /// Main/UI context
    public var mainContext: NSManagedObjectContext { container.viewContext }
    /// Background context
    public let backgroundContext: NSManagedObjectContext
    /// Persistent container
    public let container: NSPersistentContainer

    private func context(inContext: Context) -> NSManagedObjectContext {
        switch inContext {
        case .main: return mainContext
        case .background: return backgroundContext
        }
    }

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
        self.backgroundContext = container.newBackgroundContext()
    }

    /// Performs given fetch request on given context
    public func fetch<T>(_ fetchRequest: NSFetchRequest<T>, inContext context: Context = .main) -> AnyPublisher<[T], Error> {
        weak var context = self.context(inContext: context)
        return Future<[T], Error> { promise in
            guard let context = context else { return }
            context.perform {
                do {
                    promise(.success(try context.fetch(fetchRequest)))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
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
