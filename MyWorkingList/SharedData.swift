//
//  SharedData.swift
//  MyWorkingList
//
//  Created by 권오규 on 2018. 7. 5..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit
import RxSwift

class SharedData: NSObject {
    static let instance: SharedData = SharedData();
    
    var seletedWorkSpace:myWorkspace?;
    var workSpaceArr:Array<myWorkspace> = [];
    var taskAllDic:NSMutableDictionary = [:];
    
    var workSpaceUpdateObserver:AnyObserver<myWorkspace>?;
    var viewContrllerDelegate:ViewControllerDelegate!;
    
    override init() {
        if let seletedWorkSpaceId = UserDefaults().object(forKey: "seletedWorkSpaceId") as? String,
            let seletedWorkSpaceName = UserDefaults().object(forKey: "seletedWorkSpaceName") as? String,
            let seletedWorkSpaceDateType = UserDefaults().object(forKey: "seletedWorkSpaceDateType") as? Int {
            self.seletedWorkSpace = myWorkspace(id: seletedWorkSpaceId, name: seletedWorkSpaceName, dateType: DateType(rawValue: seletedWorkSpaceDateType)!)
        }
    }
}
