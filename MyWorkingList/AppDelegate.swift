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

        // Register for notifications
        application.registerForRemoteNotifications()

        //iCloud 권한 체크
        CKContainer.default().accountStatus{ status, error in
            guard status == .available else {
                self.alertPopUp(bodyStr: "user’s iCloud is not available", alertClassify: .exit);
                return
            }
            //The user’s iCloud account is available..

            self.container = CKContainer.default();
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
                    self.makeWorkSpace(workSpaceName: "default");

                } else {
                    let sharedData = SharedData.instance;

                    var isSameValue = false; //클라우드 데이터에 디바이스 값이 들어있는지 판별
                    for record in records!{
                        let value:String = record.value(forKey: "name") as! String;
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
                    sharedData.workSpaceUpdateObserver?.onNext(sharedData.seletedWorkSpace!);
                }

                //클라우드 변경사항 노티 적용
                self.saveSubscription()
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}
    
    // MARK: ==============================
    // MARK: CloudKit 메서드
    // 워크스페이스 생성
    func makeWorkSpace(workSpaceName:String) -> Void {
        //******클라우드에 새 워크스페이즈 저장******
        let pinWheel = PinWheelView.shared;
        pinWheel.showProgressView(self.navigationVC.view);
        let record = CKRecord(recordType: "workSpace")
        record.setValue(workSpaceName, forKey: "name")
        (UIApplication.shared.delegate as! AppDelegate).privateDB.save(record) { savedRecord, error in
            //해당 데이터를 워크스페이스 보관 배열에 넣는다.
            let workSpace = myWorkspace.init(id: (savedRecord?.recordID.recordName)!, name: savedRecord?.value(forKey: "name") as! String);
            UserDefaults().set(workSpace.id, forKey: "seletedWorkSpaceId");
            UserDefaults().set(workSpace.name, forKey: "seletedWorkSpaceName");
            SharedData.instance.workSpaceArr.append(workSpace);
            SharedData.instance.seletedWorkSpace = workSpace;
            
            DispatchQueue.main.async {
                pinWheel.hideProgressView();
            }
            
            SharedData.instance.workSpaceUpdateObserver?.onNext(workSpace);
        }
        //***********************************
    }
    
    // 워크스페이스 수정
    func updateWorkSpace(recordId:String, newName:String) -> Void {
        //******클라우드에 워크스페이즈 수정******
        let pinWheel = PinWheelView.shared;
        pinWheel.showProgressView(self.navigationVC.view);
        let recordId = CKRecordID(recordName: recordId)
        (UIApplication.shared.delegate as! AppDelegate).privateDB.fetch(withRecordID: recordId) { updatedRecord, error in
            if error != nil {
                return
            }
            
            updatedRecord?.setObject(newName as CKRecordValue, forKey: "name");
            (UIApplication.shared.delegate as! AppDelegate).privateDB.save(updatedRecord!) { savedRecord, error in
                DispatchQueue.main.async {
                    pinWheel.hideProgressView();
                }
            }
        }
        //***********************************
    }
    
    // 테스크 가져오기
    func getDayTask(startDate:Date, endDate:Date?, workSpaceId:String) -> Void {
        let pinWheel = PinWheelView.shared;
        DispatchQueue.main.async {
            pinWheel.showProgressView(self.navigationVC.view);
        }
        
        let startDateAddDay = startDate.addingTimeInterval(-86400.0);
        
        var predicate = NSPredicate(format: "workSpaceId = %@ AND date >= %@", workSpaceId, startDateAddDay as NSDate);
        if endDate != nil {
            let endDateAddDay = endDate?.addingTimeInterval(86400.0);
            predicate = NSPredicate(format: "workSpaceId = %@ AND date >= %@ AND date <= %@", workSpaceId, startDateAddDay as NSDate, endDateAddDay! as NSDate);
        }
        
        let query = CKQuery(recordType: "dayTask", predicate: predicate);
        
        self.privateDB.perform(query, inZoneWith: nil) { records, error in
            guard error == nil else {
                print("err: \(String(describing: error))");
                self.alertPopUp(bodyStr: (error?.localizedDescription)!, alertClassify: .exit)
                return;
            }
            
            let dateFormatter = DateFormatter();
            dateFormatter.setLocalizedDateFormatFromTemplate("yyMMdd");
            
            for record in records!{
                let body:String = record.value(forKey: "body") as! String;
                let title:String = record.value(forKey: "title") as! String;
                let date:Date = record.value(forKey: "date") as! Date;
                
                let task:myTask = myTask.init(record.recordID.recordName, date, body, title);
                let dayKey:String = dateFormatter.string(from: task.date);
                
                SharedData.instance.taskAllDic.setValue(task, forKey: dayKey);
            }
            
            SharedData.instance.viewContrllerDelegate.reloadTableAll();
            
            DispatchQueue.main.async {
                pinWheel.hideProgressView();
            }
        };
    }
    
    // 테스크 생성
    func makeDayTask(workSpaceId:String, taskDate:Date, taskBody:String, taskTitle:String?, indexPath:IndexPath) -> Void {
        //*********클라우드에 새 테스크 저장*********
        let pinWheel = PinWheelView.shared;
        pinWheel.showProgressView(self.navigationVC.view);
        let record = CKRecord(recordType: "dayTask");
        record.setValue(workSpaceId, forKey: "workSpaceId");
        record.setValue(taskDate, forKey: "date");
        record.setValue(taskBody, forKey: "body");
        record.setValue(taskTitle, forKey: "title");
        (UIApplication.shared.delegate as! AppDelegate).privateDB.save(record) { savedRecord, error in
            //해당 데이터를 워크스페이스 보관 배열에 넣는다.
            let task = myTask.init((savedRecord?.recordID.recordName)!, savedRecord?.value(forKey: "date") as! Date, savedRecord?.value(forKey: "body") as! String, savedRecord?.value(forKey: "title") as? String);
            
            let dateFormatter = DateFormatter();
            dateFormatter.setLocalizedDateFormatFromTemplate("yyMMdd");
            let dayKey:String = dateFormatter.string(from: task.date);
            
            SharedData.instance.taskAllDic.setValue(task, forKey: dayKey);
            
            DispatchQueue.main.async {
                pinWheel.hideProgressView();
            }
            
            SharedData.instance.viewContrllerDelegate.reloadTableWithUpdateCell(indexPath: indexPath, title: taskTitle!, body: taskBody)
        }
        //***********************************
    }
    
    // 테스크 수정
    func updateDayTask(task:myTask, indexPath:IndexPath) -> Void {
        //*********클라우드에 테스크 수정*********
        let pinWheel = PinWheelView.shared;
        pinWheel.showProgressView(self.navigationVC.view);
        let recordId = CKRecordID(recordName: task.id)
        (UIApplication.shared.delegate as! AppDelegate).privateDB.fetch(withRecordID: recordId) { updatedRecord, error in
            if error != nil {
                return
            }
            
            if task.title != nil {
                updatedRecord?.setObject(task.title! as CKRecordValue, forKey: "title");
            }
        
            updatedRecord?.setObject(task.body as CKRecordValue, forKey: "body");
            (UIApplication.shared.delegate as! AppDelegate).privateDB.save(updatedRecord!) { savedRecord, error in
                DispatchQueue.main.async {
                    pinWheel.hideProgressView();
                }
                
                SharedData.instance.viewContrllerDelegate.reloadTableWithUpdateCell(indexPath: indexPath, title: task.title!, body: task.body);
            }
        }
        //***********************************
    }
    
    //해당 리코드 삭제
    func deleteRecord(recordId:String) -> Void {
        //********클라우드 워크스페이스 삭제********        
        let pinWheel = PinWheelView.shared;
        pinWheel.showProgressView(self.navigationVC.view);
        
        //일일 테스트 먼저 삭제
        let predicate = NSPredicate(format: "workSpaceId = %@", recordId);
        let query = CKQuery(recordType: "dayTask", predicate: predicate);
        
        self.privateDB.perform(query, inZoneWith: nil) { records, error in
            guard error == nil else {
                print("err: \(String(describing: error))");
                self.alertPopUp(bodyStr: (error?.localizedDescription)!, alertClassify: .exit)
                return;
            }
            
            let dateFormatter = DateFormatter();
            dateFormatter.setLocalizedDateFormatFromTemplate("yyMMdd");
            
            let dispatchGroup = DispatchGroup()
            for record in records!{
                DispatchQueue(label: "kr.myWorkingList.deleteRecord").async(group: dispatchGroup) {
                    (UIApplication.shared.delegate as! AppDelegate).privateDB.delete(withRecordID: record.recordID) { deletedRecordId, error in
                        guard error == nil else {
                            print("err: \(String(describing: error))");
                            self.alertPopUp(bodyStr: (error?.localizedDescription)!, alertClassify: .exit)
                            return;
                        }
                    }
                }
            }
            
            dispatchGroup.notify(queue: DispatchQueue.main) {
                //워크스페이스 삭제
                let recordId = CKRecordID(recordName: recordId)
                (UIApplication.shared.delegate as! AppDelegate).privateDB.delete(withRecordID: recordId) { deletedRecordId, error in
                    guard error == nil else {
                        print("err: \(String(describing: error))");
                        self.alertPopUp(bodyStr: (error?.localizedDescription)!, alertClassify: .exit)
                        return;
                    }
                    
                    print("delete complete!")
                    SharedData.instance.viewContrllerDelegate.reloadTableAll();
                    
                    DispatchQueue.main.async {
                        pinWheel.hideProgressView();
                    }
                }
            }
        };
        
        //***********************************
    }
    // MARK: ==============================
    
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
    
    // MARK: - Notification related cloud
    public func saveSubscription() {
        // RecordType specifies the type of the record
        let subscriptionID = "cloudkit-recordType-changes"
        // Let's keep a local flag handy to avoid saving the subscription more than once.
        // Even if you try saving the subscription multiple times, the server doesn't save it more than once
        // Nevertheless, let's save some network operation and conserve resources
        let subscriptionSaved = UserDefaults.standard.bool(forKey: subscriptionID)
        guard !subscriptionSaved else {
            return
        }
        
        // Subscribing is nothing but saving a query which the server would use to generate notifications.
        // The below predicate (query) will raise a notification for all changes.
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: "dayTask",
                                               predicate: predicate,
                                               subscriptionID: subscriptionID,
                                               options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])
        
        let notificationInfo = CKNotificationInfo()
        // Set shouldSendContentAvailable to true for receiving silent pushes
        // Silent notifications are not shown to the user and don’t require the user's permission.
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        // Use CKModifySubscriptionsOperation to save the subscription to CloudKit
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.modifySubscriptionsCompletionBlock = { (_, _, error) in
            guard error == nil else {
                return
            }
            UserDefaults.standard.set(true, forKey: subscriptionID)
        }
        // Add the operation to the corresponding private or public database
        self.privateDB.add(operation)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Whenever there's a remote notification, this gets called
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        if (notification.subscriptionID == "cloudkit-recordType-changes") {
            print("[CLOUD UPDATE] notification - \(notification)")
            SharedData.instance.workSpaceUpdateObserver?.onNext(SharedData.instance.seletedWorkSpace!) //일정 업데이트
        }
        completionHandler(UIBackgroundFetchResult.noData)
    }
}

