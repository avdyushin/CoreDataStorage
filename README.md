# CoreData Storage

Tiny CoreData helper class and test utils.

### How to use?

Create storage object:

```swift
let storage = CoreDataStorage(container: NSPersistentContainer(name: "Model"))
```

It provides two managed object contexts, Main/UI and background:

```swift
storage.mainContext // Automatically merges changes from parent context
storage.privateContext // Created once as new background context
```

Perform block on background context and save:

```swift
let cancellable = storage
    .performInBackgroundAndSave { context in
        // work with background context
    }
    .receive(on: DispatchQueue.main)
    .sink(
        receiveCompletion: { completion in
        // process completion on main queue
    },
        receiveValue: { value in
        //
    })
```

Fetch items in given context type:

```swift
let cancellable = storage
    .fetch(Item.fetchItems(), inContext: .background)
    .receive(on: DispatchQueue.main)
    .sink(
        receiveCompletion: { completion in
        // process completion on main queue
    },
        receiveValue: { value in
            let items: [Item] = value
    })
```

### How to test?

Use `CoreDataModel` to build `ManagedObjectModel` which you can provide to `NSPersistentContainer`:

```swift
private static let managedObjectModel = CoreDataModel {
    Entity(name: "Item", className: Item.self) {
        Property(name: "id", type: .UUIDAttributeType)
        Property(name: "name", type: .stringAttributeType, isOptional: true)
    }
}.build()
```

Model should be created once. `managedObjectModel` builds model for the managed object:

```swift
private final class Item: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String?
}
```

Create in memory persistent store:

```swift
let container = NSPersistentContainer(name: "Temp", managedObjectModel: managedObjectModel)
let description = NSPersistentStoreDescription()
description.type = NSInMemoryStoreType
description.shouldAddStoreAsynchronously = false
container.persistentStoreDescriptions = [description]
```

### How to add it to Xcode project?

1. In Xcode select **File ⭢ Swift Packages ⭢ Add Package Dependency...**
1. Copy-paste repository URL: **https://github.com/avdyushin/CoreDataStorage**
1. Hit **Next** two times, under **Add to Target** select your build target.
1. Hit **Finish**
