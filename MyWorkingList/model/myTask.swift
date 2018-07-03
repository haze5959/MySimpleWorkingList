//
//  task.swift
//  MyWorkingList
//
//  Created by OQ on 2018. 7. 3..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit

class myTask: NSObject {
    let date:Date!
    let title:String!
    let body:String!
    
    init(_ dateVal:Date) {
        self.title = "";
        self.body = "";
        self.date = dateVal;
    }
}
