//
//  task.swift
//  MyWorkingList
//
//  Created by OQ on 2018. 7. 3..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit

class task: NSObject {
    let date:date!
    let title:string!
    let body:string!
    
    init(_ dateVal:date) {
        self.date = dateVal;
    }
}
