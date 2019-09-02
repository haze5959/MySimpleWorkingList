//
//  task.swift
//  MyWorkingList
//
//  Created by OQ on 2018. 7. 3..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit

class myTask: NSObject {
    let id:String!
    let date:Date!
    var body:String!
    var alarmDate:Date?
    
    init(_ id:String, _ dateVal:Date, _ bodyVal:String) {
        self.id = id;
        self.body = bodyVal;
        self.date = dateVal;
    }
}
