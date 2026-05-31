//
//  FoodItemEntity+CoreDataProperties.swift
//  NutriLoad
//
//  Created by Atakan Özcan on 30.05.2026.
//
//

import Foundation
import CoreData


extension FoodItemEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FoodItemEntity> {
        return NSFetchRequest<FoodItemEntity>(entityName: "FoodItemEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var protein: Double
    @NSManaged public var calories: Double
    @NSManaged public var date: Date?
    @NSManaged public var meal: String?

}

extension FoodItemEntity : Identifiable {

}
