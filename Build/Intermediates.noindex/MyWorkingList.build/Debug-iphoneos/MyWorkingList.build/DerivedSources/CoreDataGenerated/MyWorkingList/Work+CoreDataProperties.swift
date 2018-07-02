//
//  Work+CoreDataProperties.swift
//  
//
//  Created by 권오규 on 2018. 7. 2..
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Work {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Work> {
        return NSFetchRequest<Work>(entityName: "Work")
    }

    @NSManaged public var body: String?
    @NSManaged public var date: Date?
    @NSManaged public var id: Int16
    @NSManaged public var time: Date?
    @NSManaged public var title: String?
    @NSManaged public var workSpaceId: Int16
    @NSManaged public var relationship: Day?

}
