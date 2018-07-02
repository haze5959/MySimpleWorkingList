//
//  Day+CoreDataProperties.swift
//  
//
//  Created by 권오규 on 2018. 7. 2..
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Day {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Day> {
        return NSFetchRequest<Day>(entityName: "Day")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: Int16
    @NSManaged public var relationship: Work?
    @NSManaged public var relationship1: WorkSpace?

}
