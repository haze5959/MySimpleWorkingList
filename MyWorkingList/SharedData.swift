//
//  SharedData.swift
//  MyWorkingList
//
//  Created by 권오규 on 2018. 7. 5..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit
import RxSwift

enum FontSize: String {
    case small
    case normal
    case large
    
    func getValue() -> CGFloat {
        switch self {
        case .small:
            return 14
        case .normal:
            return 16
        case .large:
            return 20
        }
    }
}

class SharedData: NSObject {
    static let instance: SharedData = SharedData();
    
    var isPremeumUser = true
    
    var seletedWorkSpace:myWorkspace?
    var workSpaceArr:Array<myWorkspace> = []
    var taskAllDic:NSMutableDictionary = [:]
    
    var workSpaceUpdateObserver:AnyObserver<myWorkspace>?
    var viewContrllerDelegate:ViewControllerDelegate!
    
    var fontSize: FontSize {
        get {
            if let fontSizeStr = UserDefaults().string(forKey: "fontSize"),
                let fontSize = FontSize.init(rawValue: fontSizeStr) {
                return fontSize
            }
            
            return .normal
        }
        
        set {
            UserDefaults().set(newValue.rawValue, forKey: "fontSize")
        }
    }
    
    override init() {
        if let seletedWorkSpaceId = UserDefaults().object(forKey: "seletedWorkSpaceId") as? String,
            let seletedWorkSpaceName = UserDefaults().object(forKey: "seletedWorkSpaceName") as? String,
            let seletedWorkSpaceDateType = UserDefaults().object(forKey: "seletedWorkSpaceDateType") as? Int {
            self.seletedWorkSpace = myWorkspace(id: seletedWorkSpaceId, name: seletedWorkSpaceName, dateType: DateType(rawValue: seletedWorkSpaceDateType)!)
        }
    }
}
