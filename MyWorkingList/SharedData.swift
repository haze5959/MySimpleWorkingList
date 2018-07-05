//
//  SharedData.swift
//  MyWorkingList
//
//  Created by 권오규 on 2018. 7. 5..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit

class SharedData: NSObject {
    static let instance: SharedData = SharedData();
    
    var workSpace:String;
    
    override init() {
        self.workSpace = UserDefaults().object(forKey: "MyWorkSpace") as! String;
    }
}
