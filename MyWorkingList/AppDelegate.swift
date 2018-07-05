//
//  AppDelegate.swift
//  MyWorkingList
//
//  Created by OQ on 2018. 7. 1..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var navigationVC: UINavigationController!
    var container: CKContainer!
    var publicDB: CKDatabase!
    var privateDB: CKDatabase!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //스플레시 뷰 TODO: 스플레시 띄우기
        self.window = UIWindow(frame: UIScreen.main.bounds);
        self.navigationVC = UINavigationController();
        self.navigationVC.navigationBar.isHidden = true;
        let storyBoard = UIStoryboard (name: "Main", bundle: Bundle.main);
        let viewController:UIViewController! = storyBoard.instantiateInitialViewController();
        self.navigationVC.viewControllers = [viewController];
        self.window!.rootViewController = self.navigationVC;
        self.window?.makeKeyAndVisible();
        
        let pinWheel = PinWheelView.shared;
        pinWheel.showProgressView(viewController.view);
        
        //iCloud 권한 체크
        CKContainer.default().accountStatus{ status, error in
            guard status == .available else {
                return
            }
            //The user’s iCloud account is available..

            self.container = CKContainer.default();
            self.publicDB = self.container.publicCloudDatabase;
            self.privateDB = self.container.privateCloudDatabase;

            let predicate = NSPredicate(value: true);
            let query = CKQuery(recordType: "workSpace", predicate: predicate);
            self.publicDB.perform(query, inZoneWith: nil) { records, error in
                guard error != nil else {
                    print("err: \(String(describing: error))");
                    return;
                }
                
                if records?.count == 0 {    //최초 실행
                    let record = CKRecord(recordType: "workSpace")
                    record.setValue("default", forKey: "name")
                    self.publicDB.save(record) { savedRecord, error in
                        DispatchQueue.main.async {
                            pinWheel.hideProgressView();
                        }
                    }
                    
                } else {
                    let sharedData = SharedData.instance;
                    
                    var isSameValue = false; //클라우드 데이터에 디바이스 값이 들어있는지 판별
                    for record in records!{
                        let value:String = record.value(forKey: "name") as! String;
                        print("testOQ: \(value)");
                        
                        if value == sharedData.workSpace {  //디바이스에 저장된 값과 클라우드에서 가져온 값이 일치한다면
                            isSameValue = true;
                            break;
                        }
                    }
                    
                    if !isSameValue {
                        sharedData.workSpace = records![0].value(forKey: "name") as! String;
                    }
                    
                    DispatchQueue.main.async {
                        pinWheel.hideProgressView();
                    }
                    
                }
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}
    
    // MARK: CloudKit 메서드
    func makeWorkSpace(workSpaceName:String) -> Void {
        
    }
}

