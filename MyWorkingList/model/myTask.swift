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
    let date:Date!
    let body:String!
    let taskType:TaskType!
    
    init(_ dateVal:Date, _ taskType:TaskType) {
        self.body = "";
        self.date = dateVal;
        self.taskType = taskType;
    }
}
