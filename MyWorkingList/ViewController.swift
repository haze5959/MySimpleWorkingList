//
//  ViewController.swift
//  MyWorkingList
//
//  Created by OQ on 2018. 7. 1..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit
import CloudKit
import RxSwift
import RxCocoa
import EventKit
import FSCalendar
import Dialog
import Floaty

public enum reloadState {
    case none
    case append
    case insert
}

public protocol ViewControllerDelegate {
    /**
     하나의 셀 업데이트
    */
    func reloadTableWithUpdateCell(indexPath:IndexPath, body:String) -> Void
    
    /**
     모든 셀 업데이트
    */
    
    func reloadTableAll(reloadState:reloadState) -> Void
}

class ViewController: UIViewController, ViewControllerDelegate {
    
    func reloadTableWithUpdateCell(indexPath:IndexPath, body:String) {
        //해당 셀 데이터 업데이트
        var padding = 0
        for i in 0..<indexPath.section {
            padding += self.monthSectionArr[i].0
        }
        
        self.taskData[padding + indexPath.row].body = body
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func reloadTableAll(reloadState:reloadState) {
        let dayKeyFormatter = DateFormatter()
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        
        for (index, element) in self.taskData.enumerated() {
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: element.date)
            //******************************
            let dayTask:myTask! = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask
            
            if (dayTask != nil) {
                self.taskData[index] = myTask.init(dayTask.id, self.taskData[index].date, dayTask.body)
            }
        }
        
        switch reloadState {
        case .append:
            switch SharedData.instance.seletedWorkSpace!.dateType! {
            case .day:
                appendTaskData(pivotDate: self.taskData[self.taskData.count-1].date, amountOfNumber: MARGIN_TO_AFTER_DAY)
            case .week:
                appendTaskDataForWeek(pivotDate: self.taskData[self.taskData.count-1].date, amountOfWeek: MARGIN_TO_AFTER_WEEK)
            case .month:
                appendTaskDataForMonth(pivotDate: self.taskData[self.taskData.count-1].date, amountOfNumber: MARGIN_TO_AFTER_MONTH)
            }
        case .insert:
            switch SharedData.instance.seletedWorkSpace!.dateType! {
            case .day:
                insertTaskData(pivotDate: self.taskData[0].date, amountOfNumber: MARGIN_TO_AFTER_DAY)
            case .week:
                insertTaskDataForWeek(pivotDate: self.taskData[0].date, amountOfWeek: MARGIN_TO_AFTER_WEEK)
            case .month:
                insertTaskDataForMonth(pivotDate: self.taskData[0].date, amountOfNumber: MARGIN_TO_AFTER_MONTH)
            }
        default:
            break
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()

            let floaty = Floaty()
            floaty.addItem("Small font", icon: UIImage(named: "font_small")!, handler: { item in
                SharedData().fontSize = .small
                self.tableView.reloadData()
                floaty.close()
            })
            
            floaty.addItem("Normal font", icon: UIImage(named: "font_normal")!, handler: { item in
                SharedData().fontSize = .normal
                self.tableView.reloadData()
                floaty.close()
            })
            
            floaty.addItem("Large font", icon: UIImage(named: "font_large")!, handler: { item in
                SharedData().fontSize = .large
                self.tableView.reloadData()
                floaty.close()
            })
            
            self.view.addSubview(floaty)
        }
    }
    
    let disposeBag = DisposeBag()
    let MARGIN_TO_PAST_DAY = -1
    let MARGIN_TO_AFTER_DAY = 30
    let MARGIN_TO_AFTER_WEEK = 20
    let MARGIN_TO_AFTER_MONTH = 12

    @IBOutlet weak var titleLabel: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var shadowView: UIView!
    /**
     테이블의 모든 셀의 데이터를 담는다.(사용자가 기입하지 않은 날의 데이터도 들어있음)
    */
    var taskData: Array<myTask> = []
    
    /**
     0:해당 월의 값이 몇개인지
     1:해당 월
    */
    var monthSectionArr: Array<(Int, String)> = []
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Load Data...")
        refreshControl.addTarget(self, action: #selector(refreshWeatherData(_:)), for: .valueChanged)
        
        return refreshControl
    }()
    
    let appendTaskSubject = PublishSubject<Void>()
    
    var edgeGesture: UIScreenEdgePanGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //초기화
        self.shadowView.isHidden = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "TableViewCell")
        
        if #available(iOS 10.0, *) {
            self.tableView.refreshControl = refreshControl
        } else {
            self.tableView.addSubview(refreshControl)
        }
        
        //데이터 초기화 옵져버
        Observable<myWorkspace>.create{ observer in
            SharedData.instance.workSpaceUpdateObserver = observer;
            return Disposables.create()
        }.observeOn(MainScheduler.instance)
        .subscribe{
            self.taskData = [];
            self.monthSectionArr = [];
            SharedData.instance.taskAllDic.removeAllObjects();
            
            guard let workSpace = $0.element else {
                return
            }
            
            self.titleLabel.title = workSpace.name

            if  ((workSpace.pivotDate) != nil) {
                switch workSpace.dateType! {
                case .day:
                    self.initTaskData(pivotDate: workSpace.pivotDate)
                case .week:
                    self.initTaskDataForWeek(pivotDate: workSpace.pivotDate)
                case .month:
                    self.initTaskDataForMonth(pivotDate: workSpace.pivotDate)
                }
            } else {
                switch workSpace.dateType! {
                case .day:
                    self.initTaskData(pivotDate: Date())
                case .week:
                    self.initTaskDataForWeek(pivotDate: Date())
                case .month:
                    self.initTaskDataForMonth(pivotDate: Date())
                }
            }
            
            //클라우드에서 일일데이터를 가져오고 테이블 리로드
            (UIApplication.shared.delegate as! AppDelegate).getDayTask(startDate: (self.taskData.first?.date)!, endDate: (self.taskData.last?.date)!, workSpaceId: (SharedData.instance.seletedWorkSpace?.id)!, reloadState: .none)
            
        }.disposed(by: self.disposeBag)
        
        SharedData.instance.viewContrllerDelegate = self
        
        self.appendTaskSubject
            .throttle(RxTimeInterval.seconds(3), scheduler: MainScheduler.instance)
            .subscribe(onNext: { () in
                switch SharedData.instance.seletedWorkSpace!.dateType! {
                case .day:
                    (UIApplication.shared.delegate as! AppDelegate).getDayTask(startDate:self.taskData[self.taskData.count-1].date, endDate: self.taskData[self.taskData.count-1].date.addingTimeInterval(86400.0 * Double(self.MARGIN_TO_AFTER_DAY)), workSpaceId: (SharedData.instance.seletedWorkSpace?.id)!, reloadState: .append)
                case .week:
                    let startDate = (Calendar.current.date(byAdding: .weekOfMonth, value: self.MARGIN_TO_AFTER_WEEK, to: self.taskData[self.taskData.count-1].date))!
                    (UIApplication.shared.delegate as! AppDelegate).getDayTask(startDate: startDate, endDate: self.taskData[self.taskData.count-1].date, workSpaceId: (SharedData.instance.seletedWorkSpace?.id)!, reloadState: .append)
                case .month:
                    let startDate = (Calendar.current.date(byAdding: .month, value: self.MARGIN_TO_AFTER_MONTH, to: self.taskData[self.taskData.count-1].date))!
                    (UIApplication.shared.delegate as! AppDelegate).getDayTask(startDate: startDate, endDate: self.taskData[self.taskData.count-1].date, workSpaceId: (SharedData.instance.seletedWorkSpace?.id)!, reloadState: .append)
                }
            }).disposed(by: self.disposeBag)
        
        self.setEdgeGesture()
//        requestAccessToCalendar()
    }
    
    func setEdgeGesture() {
        self.edgeGesture = UIScreenEdgePanGestureRecognizer(target: self,
                                                              action: #selector(self.pressWorkSpaceBtn))
        self.edgeGesture?.edges = .left
        if let edgeGesture = self.edgeGesture {
            self.view.addGestureRecognizer(edgeGesture)
        }
    }

    /**
     워크스페이스 사이드뷰 띄우는 버튼
    */
    @IBAction func pressWorkSpaceBtn(_ sender: Any) {
        if let _ = self.edgeGesture {
            self.edgeGesture = nil
        } else {
            return
        }
        
        let sideVC = SideViewController()
        if #available(iOS 11.0, *) {
            var frame = self.view.safeAreaLayoutGuide.layoutFrame
            frame.origin.x = -frame.size.width
            sideVC.view.frame = frame
        } else {
            var frame = self.view.frame
            frame.origin.y = frame.origin.y + UIApplication.shared.statusBarFrame.size.height
            frame.origin.x = -frame.size.width
            frame.size.height = frame.size.height - UIApplication.shared.statusBarFrame.size.height
            sideVC.view.frame = frame
        }
        
        self.addChild(sideVC)
        self.view.addSubview(sideVC.view)
        self.shadowView.backgroundColor?.withAlphaComponent(0)
        self.shadowView.isHidden = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.shadowView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
            sideVC.view.frame.origin.x = 0
        })
    }
    
    /**
     해달 날짜 달력 조회 버튼
    */
    @IBAction func pressSearchCalendarBtn(_ sender: Any) {
        if let _ = self.edgeGesture {
            self.edgeGesture = nil
        }
        
        let calendarVC = CalendarViewController()
        if #available(iOS 11.0, *) {
            calendarVC.view.frame = self.view.safeAreaLayoutGuide.layoutFrame
        } else {
            var frame = self.view.frame
            frame.origin.y = frame.origin.y + UIApplication.shared.statusBarFrame.size.height
            frame.size.height = frame.size.height - UIApplication.shared.statusBarFrame.size.height
            calendarVC.view.frame = frame
        };
        
        self.addChild(calendarVC)
        self.view.addSubview(calendarVC.view)
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    /**
     오늘 날짜 조회 버튼
     */
    @IBAction func pressTodayBtn(_ sender: Any) {
        //데이터 초기화
        self.taskData = []
        self.monthSectionArr = []
        
        switch SharedData.instance.seletedWorkSpace!.dateType! {
        case .day:
            initTaskData(pivotDate: Date())
        case .week:
            initTaskDataForWeek(pivotDate: Date())
        case .month:
            initTaskDataForMonth(pivotDate: Date())
        }
        
        self.tableView.reloadData()
        
        //스크롤 맨 위로 올리기
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    /**
     캘린더 권한 체크
     */
    func requestAccessToCalendar() {
        EKEventStore.init().requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in
            
            if accessGranted == true {
                DispatchQueue.main.async(execute: {
                    //캘린더 접근 허용
//                    self.getALLEvents();
                })
            } else {
                (UIApplication.shared.delegate as! AppDelegate).alertPopUp(bodyStr: "캘린더 접근이 허용되지 않았습니다. 설정에서 해당 앱의 캘린더 접근 권한을 허용해주십시오.", alertClassify: .reload)
            }
        })
    }
    
    /**
     공휴일 일정 가져오기
     */
//    func getALLEvents(){
//        let caledar = NSCalendar.current
//        let oneDayAgoComponents = NSDateComponents.init()
//        oneDayAgoComponents.day = -1
//        let oneDayAgo = caledar.date(byAdding: oneDayAgoComponents as DateComponents, to: Date(), wrappingComponents: true)
//
//
//        let oneYearFromNowComponents = NSDateComponents.init()
//        oneYearFromNowComponents.year = 1
//        let oneYearFromNow = caledar.date(byAdding: oneYearFromNowComponents as DateComponents, to: Date(), wrappingComponents: true)
//
//        let store = EKEventStore.init();
//
//        let predicate = store.predicateForEvents(withStart: oneDayAgo!, end: oneYearFromNow!, calendars: nil)
//
//        let event = store.events(matching: predicate)
//    }
}

// MARK: UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            let detailVC = DetailViewController()
            
            var padding = 0
            for i in 0..<indexPath.section {
                padding += self.monthSectionArr[i].0
            }
            
            let task:myTask = self.taskData[padding + indexPath.row]
            
            let dayKeyFormatter = DateFormatter()
            dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
            let dayKey:String = dayKeyFormatter.string(from: task.date)
            detailVC.dayTask = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask
            detailVC.tableIndexPath = indexPath
            
            if (detailVC.dayTask == nil) {
                detailVC.dayTask = task
            }
            
            detailVC.view.frame = self.view.safeAreaLayoutGuide.layoutFrame

            self.addChild(detailVC)
            self.view.addSubview(detailVC.view)
            
            if let _ = self.edgeGesture {
                self.edgeGesture = nil
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (self.taskData.count > 0 && scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) { //reach bottom
            self.appendTaskSubject.onNext(())
        }
    }
}

// MARK: UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:TableViewCell! = (self.tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell)
        cell.selectionStyle = .none
        var padding = 0
        
        for i in 0..<indexPath.section {
            padding += self.monthSectionArr[i].0
        }
        
        let task:myTask = self.taskData[padding + indexPath.row]

        //요일/일자 뽑아내기
        let dateCompareFormatter = DateFormatter()
        dateCompareFormatter.setLocalizedDateFormatFromTemplate("MM/dd/yyyy")
        let taskDate:String = dateCompareFormatter.string(from: task.date)
        
        let dateFormatter = DateFormatter()
        
        switch SharedData.instance.seletedWorkSpace!.dateType! {
        case .day:
            dateFormatter.setLocalizedDateFormatFromTemplate("EEEE")
            let dayOfWeek:String = dateFormatter.string(from: task.date)
            dateFormatter.setLocalizedDateFormatFromTemplate("dd")
            let day:String = dateFormatter.string(from: task.date)
            
            let todayDate:String = dateCompareFormatter.string(from: Date());
            
            if taskDate == todayDate {  //오늘이라면
                cell.titleLabel?.text = "\(day) [\(dayOfWeek)] - today!"
                cell.titleLabel.backgroundColor = UIColor.init(red: 255/255, green: 224/255, blue: 178/255, alpha: 1)
            } else {
                let weekDay = Calendar.current.component(Calendar.Component.weekday, from: task.date)
                if weekDay == 1 {   //일요일이라면
                    cell.titleLabel.backgroundColor = UIColor.init(red: 252/255, green: 228/255, blue: 236/255, alpha: 1)
                } else {
                    cell.titleLabel.backgroundColor = UIColor.init(red: 227/255, green: 242/255, blue: 253/255, alpha: 1)
                }
                
                cell.titleLabel?.text = "\(day) [\(dayOfWeek)]"
            }
        case .week:
            let weekNumber = Calendar.current.component(.weekOfMonth, from: task.date)  //첫 주는 1부터 시작
            dateFormatter.setLocalizedDateFormatFromTemplate("MM/dd")
            let sunday = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: task.date))!
            let sundayStr:String = dateFormatter.string(from: sunday)
            let saturday = Calendar.current.date(byAdding: .day, value: 6, to: sunday)
            let saturdayStr:String = dateFormatter.string(from: saturday!)
            
            let weekPivot = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!   //일요일로 변경
            let todayDate:String = dateCompareFormatter.string(from: weekPivot)
            
            if taskDate == todayDate {  //오늘이라면
                cell.titleLabel?.text = "\(weekNumber) Week(\(sundayStr)~\(saturdayStr)) - today!"
                cell.titleLabel.backgroundColor = UIColor.init(red: 255/255, green: 224/255, blue: 178/255, alpha: 1)
            } else {
                cell.titleLabel?.text = "\(weekNumber) Week(\(sundayStr)~\(saturdayStr))"
                cell.titleLabel.backgroundColor = UIColor.init(red: 227/255, green: 242/255, blue: 253/255, alpha: 1)
            }
        case .month:
            dateFormatter.setLocalizedDateFormatFromTemplate("MM")
            let monthStr:String = dateFormatter.string(from: task.date)
            
            let monthPivot = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!   //해당 달의 첫째날로 변경
            let todayDate:String = dateCompareFormatter.string(from: monthPivot)
            
            if taskDate == todayDate {  //오늘이라면
                cell.titleLabel?.text = "\(monthStr) - today!"
                cell.titleLabel.backgroundColor = UIColor.init(red: 255/255, green: 224/255, blue: 178/255, alpha: 1)
            } else {
                cell.titleLabel?.text = "\(monthStr)"
                cell.titleLabel.backgroundColor = UIColor.init(red: 227/255, green: 242/255, blue: 253/255, alpha: 1)
            }
        }
        
        //캘린더에서 이벤트 가져오기
//        let store = EKEventStore.init();
//        let predicate = store.predicateForEvents(withStart: task.date, end: task.date, calendars: nil);
//        let allEvent = store.events(matching: predicate);
//
//        if allEvent.count > 0 {
//            cell.titleLabel?.text?.append("(\(allEvent[0].title!))");
//        }
        
        cell.bodyLabel?.text = task.body
        cell.bodyLabel.font = UIFont.systemFont(ofSize: SharedData().fontSize.getValue())
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var padding = 0
        for i in 0..<indexPath.section {
            padding += self.monthSectionArr[i].0
        }
        
        switch SharedData.instance.seletedWorkSpace!.dateType! {
        case .day:
            if(self.taskData[padding + indexPath.row].body == ""){
                return 40
            }
            
            return 200
        case .week:
            return 200
        case .month:
            return 300
        }
    }
    
    // MARK: 해더 관련
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.monthSectionArr.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.monthSectionArr[section].0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.monthSectionArr[section].1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    // MARK: Pull to refresh
    @objc private func refreshWeatherData(_ sender: Any) {
        // Fetch Weather Data
        switch SharedData.instance.seletedWorkSpace!.dateType! {
        case .day:
            (UIApplication.shared.delegate as! AppDelegate).getDayTask(startDate: self.taskData[0].date.addingTimeInterval(-86400.0 * Double(MARGIN_TO_AFTER_DAY)), endDate: self.taskData[0].date, workSpaceId: (SharedData.instance.seletedWorkSpace?.id)!,reloadState: .insert)
        case .week:
            let startDate = (Calendar.current.date(byAdding: .weekOfMonth, value: -MARGIN_TO_AFTER_WEEK, to: self.taskData[0].date))!
            (UIApplication.shared.delegate as! AppDelegate).getDayTask(startDate: startDate, endDate: self.taskData[0].date, workSpaceId: (SharedData.instance.seletedWorkSpace?.id)!,reloadState: .insert)
        case .month:
            let startDate = (Calendar.current.date(byAdding: .month, value: -MARGIN_TO_AFTER_MONTH, to: self.taskData[0].date))!
            (UIApplication.shared.delegate as! AppDelegate).getDayTask(startDate: startDate, endDate: self.taskData[0].date, workSpaceId: (SharedData.instance.seletedWorkSpace?.id)!,reloadState: .insert)
        }
        
        self.refreshControl.endRefreshing()
    }
}

// MARK: Day init
extension ViewController {
    /**
     테이블 뷰 데이터 초기화
     */
    func initTaskData(pivotDate:Date!) -> Void {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy MM")
        let tempdate:Date = (Calendar.current.date(byAdding: .day, value: MARGIN_TO_PAST_DAY, to: pivotDate))!
        var tempMonth:String = dateFormatter.string(from: tempdate)
        var sectionContainNum:Int = 0
        
        let dayKeyFormatter = DateFormatter();
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        //과거로부터 현재 미래까지
        for i in MARGIN_TO_PAST_DAY..<MARGIN_TO_AFTER_DAY {
            let date:Date = (Calendar.current.date(byAdding: .day, value: i, to: pivotDate))!
            
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: date)
            //******************************
            let dayTask:myTask? = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask
            
            if dayTask != nil {
                if(i == 0) {
                    self.taskData.append(myTask(dayTask!.id, date, dayTask!.body))
                } else {
                    self.taskData.append(myTask(dayTask!.id, date, dayTask!.body))
                }
            } else {
                if(i == 0) {
                    self.taskData.append(myTask("", date, ""))
                } else {
                    self.taskData.append(myTask("", date, ""))
                }
            }
            
            //월이 바뀌면 섹션을 추가한다.
            let month:String = dateFormatter.string(from: date)
            if month != tempMonth {
                self.monthSectionArr.append((sectionContainNum, tempMonth))
                tempMonth = month
                sectionContainNum = 0
            }
            
            sectionContainNum += 1
        }
        
        self.monthSectionArr.append((sectionContainNum, tempMonth));
    }
    
    func insertTaskData(pivotDate:Date!, amountOfNumber:Int) -> Void {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy MM")
        var pivotMonth:String = dateFormatter.string(from: pivotDate)
        
        let dayKeyFormatter = DateFormatter()
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        //과거로부터 현재 미래까지
        for i in 1..<amountOfNumber+1 {
            let pastDate:Date = (Calendar.current.date(byAdding: .day, value: -i, to: pivotDate))!
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: pastDate)
            //******************************
            let dayTask:myTask? = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask
            
            if(dayTask != nil) {
                self.taskData.insert(myTask((dayTask?.id)!, pastDate, (dayTask?.body)!), at: 0)
            } else {
                self.taskData.insert(myTask("", pastDate, ""), at: 0)
            }
            
            //월이 바뀌면 섹션을 추가한다.
            let pastMonth:String = dateFormatter.string(from: pastDate)
            if(pivotMonth != pastMonth) {
                self.monthSectionArr.insert((1, pastMonth), at: 0)
                pivotMonth = pastMonth
                
            } else {
                self.monthSectionArr[0].0 += 1
            }
        }
    }
    
    func appendTaskData(pivotDate:Date!, amountOfNumber:Int) -> Void {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy MM")
        var tempMonth:String = dateFormatter.string(from: pivotDate)
        
        let dayKeyFormatter = DateFormatter()
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        //과거로부터 현재 미래까지
        for i in 1..<amountOfNumber+1 {
            let date:Date = (Calendar.current.date(byAdding: .day, value: i, to: pivotDate))!
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: date)
            //******************************
            let dayTask:myTask? = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask
            
            if(dayTask != nil) {
                self.taskData.append(myTask((dayTask?.id)!, date, (dayTask?.body)!))
            } else {
                self.taskData.append(myTask("", date, ""))
            }
            
            //월이 바뀌면 섹션을 추가한다.
            let month:String = dateFormatter.string(from: date)
            if(month != tempMonth) {
                self.monthSectionArr.append((1, month))
                tempMonth = month
                
            } else {
                self.monthSectionArr[self.monthSectionArr.count-1].0 += 1
            }
        }
    }
}

// MARK: Week init
extension ViewController {
    /**
     테이블 뷰 데이터 초기화
     */
    func initTaskDataForWeek(pivotDate:Date!) -> Void {
        let weekPivot = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: pivotDate))!   //일요일로 변경
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy MM")
        
        var tempMonth:String = dateFormatter.string(from: weekPivot)
        var sectionContainNum:Int = 0
        
        var weekNumber = Calendar.current.component(.weekOfMonth, from: weekPivot)  //첫 주는 1부터 시작
        
        let dayKeyFormatter = DateFormatter()
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        //과거로부터 현재 미래까지
        for i in 0..<MARGIN_TO_AFTER_WEEK {
            let date:Date = (Calendar.current.date(byAdding: .weekOfMonth, value: i, to: weekPivot))!
            
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: date)
            //******************************
            let dayTask:myTask? = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask
            
            if dayTask != nil {
                if(i == 0) {
                    self.taskData.append(myTask(dayTask!.id, date, dayTask!.body))
                } else {
                    self.taskData.append(myTask(dayTask!.id, date, dayTask!.body))
                }
            } else {
                if(i == 0){
                    self.taskData.append(myTask("", date, ""))
                } else {
                    self.taskData.append(myTask("", date, ""))
                }
            }
            
            //월이 바뀌면 섹션을 추가한다.
            let tempWeekNumber = Calendar.current.component(.weekOfMonth, from: date)  //첫 주는 1부터 시작
            if weekNumber > tempWeekNumber {
                self.monthSectionArr.append((sectionContainNum, tempMonth))
                tempMonth = dateFormatter.string(from: date)
                sectionContainNum = 0
            }
            
            weekNumber = tempWeekNumber
            sectionContainNum += 1
        }
        
        self.monthSectionArr.append((sectionContainNum, tempMonth))
    }
    
    func insertTaskDataForWeek(pivotDate:Date!, amountOfWeek:Int) -> Void {
        let weekPivot = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: pivotDate))!   //일요일로 변경
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy MM")
        
        var tempMonth:String = dateFormatter.string(from: weekPivot)
        
        var weekNumber = Calendar.current.component(.weekOfMonth, from: weekPivot)
        
        let dayKeyFormatter = DateFormatter()
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        //과거로부터 현재 미래까지
        for i in 1..<amountOfWeek+1{
            let pastDate:Date = (Calendar.current.date(byAdding: .weekOfMonth, value: -i, to: weekPivot))!
            
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: pastDate)
            //******************************
            let dayTask:myTask? = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask
            
            if(dayTask != nil){
                self.taskData.insert(myTask((dayTask?.id)!, pastDate, (dayTask?.body)!), at: 0)
            } else {
                self.taskData.insert(myTask("", pastDate, ""), at: 0)
            }
            
            //월이 바뀌면 섹션을 추가한다.
            let tempWeekNumber = Calendar.current.component(.weekOfMonth, from: pastDate)  //첫 주는 1부터 시작
            if weekNumber < tempWeekNumber {
                tempMonth = dateFormatter.string(from: pastDate)
                self.monthSectionArr.insert((1, tempMonth), at: 0)
            } else {
                self.monthSectionArr[0].0 += 1
            }
            
            weekNumber = tempWeekNumber
        }
    }
    
    func appendTaskDataForWeek(pivotDate:Date!, amountOfWeek:Int) -> Void {
        let weekPivot = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: pivotDate))!   //일요일로 변경
        let nextWeek:Date = (Calendar.current.date(byAdding: .weekOfMonth, value: 1, to: weekPivot))!
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy MM")
        
        var tempMonth:String = dateFormatter.string(from: nextWeek)
        
        var weekNumber = Calendar.current.component(.weekOfMonth, from: nextWeek)
        
        let dayKeyFormatter = DateFormatter()
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        //과거로부터 현재 미래까지
        for i in 0..<amountOfWeek{
            let date:Date = (Calendar.current.date(byAdding: .weekOfMonth, value: i, to: nextWeek))!
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: date)
            //******************************
            let dayTask:myTask? = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask
            
            if(dayTask != nil){
                self.taskData.append(myTask((dayTask?.id)!, date, (dayTask?.body)!))
            } else {
                self.taskData.append(myTask("", date, ""))
            }
            
            //월이 바뀌면 섹션을 추가한다.
            let tempWeekNumber = Calendar.current.component(.weekOfMonth, from: date)  //첫 주는 1부터 시작
            if weekNumber > tempWeekNumber {
                tempMonth = dateFormatter.string(from: date)
                self.monthSectionArr.append((1, tempMonth))
            } else {
                self.monthSectionArr[self.monthSectionArr.count-1].0 += 1
            }
            
            weekNumber = tempWeekNumber
        }
    }
}

// MARK: Month init
extension ViewController {
    /**
     테이블 뷰 데이터 초기화
     */
    func initTaskDataForMonth(pivotDate:Date!) -> Void {
        let monthPivot = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: pivotDate))!   //해당 달의 첫째날로 변경
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy")
        
        var tempYear:String = dateFormatter.string(from: monthPivot)
        var sectionContainNum:Int = 0
        
        var yearNumber = Calendar.current.component(.year, from: monthPivot)
        
        let dayKeyFormatter = DateFormatter()
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        //과거로부터 현재 미래까지
        for i in 0..<MARGIN_TO_AFTER_MONTH {
            let date:Date = (Calendar.current.date(byAdding: .month, value: i, to: monthPivot))!
            
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: date)
            //******************************
            let dayTask:myTask? = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask
            
            if dayTask != nil {
                if(i == 0) {
                    self.taskData.append(myTask(dayTask!.id, date, dayTask!.body))
                } else {
                    self.taskData.append(myTask(dayTask!.id, date, dayTask!.body))
                }
            } else {
                if(i == 0){
                    self.taskData.append(myTask("", date, ""))
                } else {
                    self.taskData.append(myTask("", date, ""))
                }
            }
            
            //월이 바뀌면 섹션을 추가한다.
            let tempYearNumber = Calendar.current.component(.year, from: date)
            if yearNumber != tempYearNumber {
                self.monthSectionArr.append((sectionContainNum, tempYear))
                tempYear = dateFormatter.string(from: date)
                yearNumber = tempYearNumber
                sectionContainNum = 0
            }
            
            sectionContainNum += 1
        }
        
        self.monthSectionArr.append((sectionContainNum, tempYear))
    }
    
    func insertTaskDataForMonth(pivotDate:Date!, amountOfNumber:Int) -> Void {
        let monthPivot = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: pivotDate))!   //해당 달의 첫째날로 변경
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy")
        
        var tempYear:String = dateFormatter.string(from: monthPivot)
        
        var yearNumber = Calendar.current.component(.year, from: monthPivot)
        
        let dayKeyFormatter = DateFormatter()
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        //과거로부터 현재 미래까지
        for i in 1..<amountOfNumber+1 {
            let pastDate:Date = (Calendar.current.date(byAdding: .month, value: -i, to: monthPivot))!
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: pastDate)
            //******************************
            let dayTask:myTask? = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask
            
            if(dayTask != nil){
                self.taskData.insert(myTask((dayTask?.id)!, pastDate, (dayTask?.body)!), at: 0)
            } else {
                self.taskData.insert(myTask("", pastDate, ""), at: 0)
            }
            
            //월이 바뀌면 섹션을 추가한다.
            let tempYearNumber = Calendar.current.component(.year, from: pastDate)
            if yearNumber != tempYearNumber {
                tempYear = dateFormatter.string(from: pastDate)
                self.monthSectionArr.insert((1, tempYear), at: 0)
            } else {
                self.monthSectionArr[0].0 += 1
            }
            
            yearNumber = tempYearNumber
        }
    }
    
    func appendTaskDataForMonth(pivotDate:Date!, amountOfNumber:Int) -> Void {
        let monthPivot = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: pivotDate))!   //해당 달의 첫째날로 변경
        let nextWeek:Date = (Calendar.current.date(byAdding: .weekOfMonth, value: 1, to: monthPivot))!
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy")
        
        var tempYear:String = dateFormatter.string(from: nextWeek)
        
        var yearNumber = Calendar.current.component(.year, from: nextWeek)
        
        let dayKeyFormatter = DateFormatter()
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd")
        //과거로부터 현재 미래까지
        for i in 1..<amountOfNumber+1 {
            let date:Date = (Calendar.current.date(byAdding: .month, value: i, to: nextWeek))!
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: date)
            //******************************
            let dayTask:myTask? = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask
            
            if(dayTask != nil){
                self.taskData.append(myTask((dayTask?.id)!, date, (dayTask?.body)!))
            } else {
                self.taskData.append(myTask("", date, ""))
            }
            
            //월이 바뀌면 섹션을 추가한다.
            let tempYearNumber = Calendar.current.component(.year, from: date)
            if yearNumber != tempYearNumber {
                tempYear = dateFormatter.string(from: date)
                self.monthSectionArr.append((1, tempYear))
            } else {
                self.monthSectionArr[self.monthSectionArr.count-1].0 += 1
            }
            
            yearNumber = tempYearNumber
        }
    }
}
