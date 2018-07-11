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
        if UserDefaults().object(forKey: "seletedWorkSpaceId") != nil && UserDefaults().object(forKey: "seletedWorkSpaceName") != nil {
            self.seletedWorkSpace = myWorkspace(id: UserDefaults().object(forKey: "seletedWorkSpaceId") as! String, name: UserDefaults().object(forKey: "seletedWorkSpaceName") as! String);
        }
    }
}
