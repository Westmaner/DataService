//
//  UserEntity+CoreDataProperties.swift
//  DataService
//
//  Created by Tim Yoon on 6/11/23.
//
//

import Foundation
import CoreData


extension UserEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var timestamp: Date
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Date.now, forKey: "timestamp")
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue("", forKey: "name")
    }

}

extension UserEntity : Identifiable {

}
