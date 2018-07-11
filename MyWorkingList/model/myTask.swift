//
//  task.swift
//  MyWorkingList
//
//  Created by OQ on 2018. 7. 3..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit

enum TaskType: Int {
    case unknown
    case today
}

class myTask: NSObject {
    let id:String!
    let date:Date!
    var body:String!
    let taskType:TaskType!
    
    init(_ id:String, _ dateVal:Date, _ bodyVal:String, _ taskType:TaskType) {
        self.id = id;
        self.body = bodyVal;
        self.date = dateVal;
        self.taskType = taskType;
    }
}
