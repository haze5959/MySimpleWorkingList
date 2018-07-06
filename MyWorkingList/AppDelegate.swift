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
//    var publicDB: CKDatabase!
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
//            self.publicDB = self.container.publicCloudDatabase;
            self.privateDB = self.container.privateCloudDatabase;

            let predicate = NSPredicate(value: true);
            let query = CKQuery(recordType: "workSpace", predicate: predicate);

            self.privateDB.perform(query, inZoneWith: nil) { records, error in
                guard error == nil else {
                    print("err: \(String(describing: error))");
                    self.alertPopUp(bodyStr: (error?.localizedDescription)!, alertClassify: .exit)
                    return;
                }
                
                if records?.count == 0 {    //최초 실행
                    let record = CKRecord(recordType: "workSpace")
                    record.setValue("default", forKey: "name")
                    self.privateDB.save(record) { savedRecord, error in
                        //해당 데이터를 워크스페이스 보관 배열에 넣는다.
                        let workSpace = myWorkspace.init(id: savedRecord?.value(forKey: "name") as! String, name: (savedRecord?.recordID.recordName)!);
                        UserDefaults().set(workSpace.id, forKey: "seletedWorkSpaceId");
                        UserDefaults().set(workSpace.name, forKey: "seletedWorkSpaceName");
                        SharedData.instance.workSpaceArr.append(workSpace);
                        
                        DispatchQueue.main.async {
                            pinWheel.hideProgressView();
                        }
                        
                        SharedData.instance.taskUpdateObserver?.onNext(workSpace);
                    }
                    
                } else {
                    let sharedData = SharedData.instance;
                    
                    var isSameValue = false; //클라우드 데이터에 디바이스 값이 들어있는지 판별
                    for record in records!{
                        let value:String = record.value(forKey: "name") as! String;
                        print("testOQ: \(value)");
                        sharedData.workSpaceArr.append(myWorkspace.init(id:record.recordID.recordName, name:record.value(forKey: "name") as! String));
                        
                        if value == sharedData.seletedWorkSpace?.name {  //디바이스에 저장된 값과 클라우드에서 가져온 값이 일치한다면
                            isSameValue = true;
                        }
                    }
                    
                    if !isSameValue {
                        let workSpace = myWorkspace.init(id:(records![0].recordID.recordName) , name:records![0].value(forKey: "name") as! String);
                        sharedData.seletedWorkSpace = workSpace;
                        UserDefaults().set(workSpace.id, forKey: "seletedWorkSpaceId");
                        UserDefaults().set(workSpace.name, forKey: "seletedWorkSpaceName");
                    }
                    
                    DispatchQueue.main.async {
                        pinWheel.hideProgressView();
                    }
                    sharedData.taskUpdateObserver?.onNext(sharedData.seletedWorkSpace!);
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
    
    // MARK: 얼럿뷰
    enum AlertClassify {
        case normal;
        case exit;
    }
    
    func alertPopUp(bodyStr:String, alertClassify:AlertClassify) -> Void {
        let alert = UIAlertController(title: "알림", message: bodyStr, preferredStyle: .alert);
        
        switch alertClassify {
        case .normal:
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil));
        case .exit:
            alert.addAction(UIAlertAction(title: "Exit", style: .cancel, handler: {
                action in exit(0);
            }));
        }
        
        self.navigationVC.present(alert, animated: true);
    }
}

