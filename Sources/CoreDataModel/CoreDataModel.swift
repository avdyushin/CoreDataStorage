//
//  CoreDataModel.swift
//
//  Created by Grigory Avdyushin on 21/05/2020.
//  Copyright © 2020 Grigory Avdyushin. All rights reserved.
//

import CoreData
import Foundation

/// NSEntityDescription wrapper
public struct Entity {
    /// Name value
    public let name: String
    /// Managed object class name
    public let className: AnyClass
    /// Properties
    public let properties: [Property]

    @_functionBuilder public struct EntityBuilder {
        public static func buildBlock(_ attribute: Property) -> Property { attribute }
        public static func buildBlock(_ attributes: Property...) -> [Property] { attributes }
    }

    public init(name: String, className: AnyClass, @EntityBuilder _ property: () -> Property) {
        self.init(name: name, className: className, properties: [property()])
    }

    public init(name: String, className: AnyClass, @EntityBuilder _ properties: () -> [Property]) {
        self.init(name: name, className: className, properties: properties())
    }

    public init(name: String, className: AnyClass, properties: [Property]) {
        self.name = name
        self.className = className
        self.properties = properties
    }
}

/// NSAttributeDescription wrapper
public struct Property {
    public let name: String
    public let type: NSAttributeType
    public let isOptional: Bool

    public init(name: String, type: NSAttributeType, isOptional: Bool = false) {
        self.name = name
        self.type = type
        self.isOptional = isOptional
    }
}

public struct CoreDataModel {

    private var entities: [Entity]

    @_functionBuilder public struct CoreDataModelBuilder {
        static func buildBlock(_ entity: Entity) -> Entity { entity }
        static func buildBlock(_ entities: Entity...) -> [Entity] { entities }
    }

    public init(@CoreDataModelBuilder _ entity: () -> Entity) {
        self.entities = [entity()]
    }

    public init(@CoreDataModelBuilder _ entities: () -> [Entity]) {
        self.entities = entities()
    }

    public func build() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.entities = entities.map { entity in
            let desciption = NSEntityDescription()
            desciption.name = entity.name
            desciption.managedObjectClassName = NSStringFromClass(entity.className)
            desciption.properties = entity.properties.map { attr in
                let attribute = NSAttributeDescription()
                attribute.name = attr.name
                attribute.attributeType = attr.type
                attribute.isOptional = attr.isOptional
                return attribute
            }
            return desciption
        }
        return model
    }
}
