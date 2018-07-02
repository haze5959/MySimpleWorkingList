//
//  WorkSpace+CoreDataProperties.swift
//  
//
//  Created by 권오규 on 2018. 7. 2..
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension WorkSpace {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkSpace> {
        return NSFetchRequest<WorkSpace>(entityName: "WorkSpace")
    }

    @NSManaged public var id: Int16
    @NSManaged public var name: String?
    @NSManaged public var workRelation: Work?

}
