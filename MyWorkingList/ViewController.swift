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

public protocol ViewControllerDelegate {
    /**
     하나의 셀 업데이트
    */
    func reloadTableWithUpdateCell(indexPath:IndexPath, body:String) -> Void;
    
    /**
     모든 셀 업데이트
    */
    func reloadTableAll() -> Void;
}

class ViewController: UIViewController, ViewControllerDelegate {
    func reloadTableWithUpdateCell(indexPath:IndexPath, body:String) {
        //해당 셀 데이터 업데이트
        var padding = 0
        for i in 0..<indexPath.section {
            padding += self.monthSectionArr[i].0;
        }
        
        self.taskData[padding + indexPath.row].body = body;
        
        DispatchQueue.main.async {
            self.tableView.reloadData();
        }
    }
    
    func reloadTableAll() {
        let dayKeyFormatter = DateFormatter();
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd");
        
//        self.taskData.append(myTask(dayTask!.id, date, dayTask!.body, .unknown));
        for (index, element) in self.taskData.enumerated() {
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: element.date);
            //******************************
            let dayTask:myTask! = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask;
            
            if (dayTask != nil) {
                self.taskData[index] = myTask.init(dayTask.id, self.taskData[index].date, dayTask.body, self.taskData[index].taskType);
            }
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData();
        }
    }
    
    let disposeBag = DisposeBag();
    let MARGIN_TO_PAST_DAY = -2;
    let MARGIN_TO_AFTER_DAY = 30;
//    let APPDELEGATE_INSTANCE = (UIApplication.shared.delegate as! AppDelegate);

    @IBOutlet weak var titleLabel: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    
    /**
     테이블의 모든 셀의 데이터를 담는다.(사용자가 기입하지 않은 날의 데이터도 들어있음)
    */
    var taskData: Array<myTask> = [];
    
    /**
     0:해당 월의 값이 몇개인지
     1:해당 월
    */
    var monthSectionArr: Array<(Int, String)> = [];
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl();
        refreshControl.attributedTitle = NSAttributedString(string: "Load data a month ago");
        refreshControl.addTarget(self, action: #selector(refreshWeatherData(_:)), for: .valueChanged)
        
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //초기화
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        self.tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "TableViewCell");
        
        if #available(iOS 10.0, *) {
            self.tableView.refreshControl = refreshControl
        } else {
            self.tableView.addSubview(refreshControl);
        }
        
        //데이터 초기화 옵져버
        Observable<myWorkspace>.create{ observer in
            SharedData.instance.workSpaceUpdateObserver = observer;
            return Disposables.create();
        }.observeOn(MainScheduler.instance)
        .subscribe{
            self.titleLabel.title = $0.element?.name;
            self.initTaskData(pivotDate: Date());
            
            //클라우드에서 일일데이터를 가져오고 테이블 리로드
            (UIApplication.shared.delegate as! AppDelegate).getDayTask(startDate: (self.taskData.first?.date)!, endDate: (self.taskData.last?.date)!, workSpaceId: (SharedData.instance.seletedWorkSpace?.id)!);
            
        }.disposed(by: self.disposeBag);
        
        SharedData.instance.viewContrllerDelegate = self;
    }
    
    /**
     테이블 뷰 데이터 초기화
    */
    func initTaskData(pivotDate:Date!) -> Void {
        let dateFormatter = DateFormatter();
        dateFormatter.setLocalizedDateFormatFromTemplate("M");
        let tempdate:Date = (Calendar.current.date(byAdding: .day, value: MARGIN_TO_PAST_DAY, to: pivotDate))!;
        var tempMonth:String = dateFormatter.string(from: tempdate);
        var sectionContainNum:Int = 0;
        
        let dayKeyFormatter = DateFormatter();
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd");
        //과거로부터 현재 미래까지
        for i in MARGIN_TO_PAST_DAY..<MARGIN_TO_AFTER_DAY{
            let date:Date = (Calendar.current.date(byAdding: .day, value: i, to: pivotDate))!;
            
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: date);
            //******************************
            let dayTask:myTask? = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask;
            
            if (dayTask != nil) {
                if(i == 0){
                    self.taskData.append(myTask(dayTask!.id, date, dayTask!.body, .today));
                } else {
                    self.taskData.append(myTask(dayTask!.id, date, dayTask!.body, .unknown));
                }
            } else {
                if(i == 0){
                    self.taskData.append(myTask("", date, "", .today));
                } else {
                    self.taskData.append(myTask("", date, "", .unknown));
                }
            }
            
            //월이 바뀌면 섹션을 추가한다.
            let month:String = dateFormatter.string(from: date);
            if(month != tempMonth){
                self.monthSectionArr.append((sectionContainNum, tempMonth));
                tempMonth = month;
                sectionContainNum = 0;
            }
            
            sectionContainNum += 1;
        }
        
        self.monthSectionArr.append((sectionContainNum, tempMonth));
    }
    
    func insertTaskData(pivotDate:Date!, amountOfNumber:Int) -> Void {
        let dateFormatter = DateFormatter();
        dateFormatter.setLocalizedDateFormatFromTemplate("M");
        var pivotMonth:String = dateFormatter.string(from: pivotDate);
        
        let dayKeyFormatter = DateFormatter();
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd");
        //과거로부터 현재 미래까지
        for i in 1..<amountOfNumber+1{
            let pastDate:Date = (Calendar.current.date(byAdding: .day, value: -i, to: pivotDate))!;
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: pastDate);
            //******************************
            let dayTask:myTask? = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask;
            
            if(dayTask != nil){
                self.taskData.insert(myTask((dayTask?.id)!, pastDate, (dayTask?.body)!, .unknown), at: 0);
            } else {
                self.taskData.insert(myTask("", pastDate, "", .unknown), at: 0);
            }
            
            //월이 바뀌면 섹션을 추가한다.
            let pastMonth:String = dateFormatter.string(from: pastDate);
            if(pivotMonth != pastMonth){
                self.monthSectionArr.insert((1, pastMonth), at: 0);
                pivotMonth = pastMonth;
                
            } else {
                self.monthSectionArr[0].0 += 1;
            }
        }
    }
    
    func appendTaskData(pivotDate:Date!, amountOfNumber:Int) -> Void {
        let dateFormatter = DateFormatter();
        dateFormatter.setLocalizedDateFormatFromTemplate("M");
        var tempMonth:String = dateFormatter.string(from: pivotDate);

        let dayKeyFormatter = DateFormatter();
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd");
        //과거로부터 현재 미래까지
        for i in 1..<amountOfNumber+1{
            let date:Date = (Calendar.current.date(byAdding: .day, value: i, to: pivotDate))!;
            //*********dayKey 생성***********
            let dayKey:String = dayKeyFormatter.string(from: date);
            //******************************
            let dayTask:myTask? = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask;
            
            if(dayTask != nil){
                self.taskData.append(myTask((dayTask?.id)!, date, (dayTask?.body)!, .unknown));
            } else {
                self.taskData.append(myTask("", date, "", .unknown));
            }

            //월이 바뀌면 섹션을 추가한다.
            let month:String = dateFormatter.string(from: date);
            if(month != tempMonth){
                self.monthSectionArr.append((1, month));
                tempMonth = month;
                
            } else {
                self.monthSectionArr[self.monthSectionArr.count-1].0 += 1;
            }
        }
    }

    /**
     워크스페이스 사이드뷰 띄우는 버튼
    */
    @IBAction func pressWorkSpaceBtn(_ sender: Any) {
        let sideVC = SideViewController();
        if #available(iOS 11.0, *) {
            sideVC.view.frame = self.view.safeAreaLayoutGuide.layoutFrame
        } else {
            var frame = self.view.frame;
            frame.origin.y = frame.origin.y + UIApplication.shared.statusBarFrame.size.height;
            frame.size.height = frame.size.height - UIApplication.shared.statusBarFrame.size.height;
            sideVC.view.frame = frame;
        };
        
        self.addChildViewController(sideVC);
        self.view.addSubview(sideVC.view);
    }
    
    /**
     해달 날짜 달력 조회 버튼
    */
    @IBAction func pressSearchCalendarBtn(_ sender: Any) {
    }
    
    /**
     오늘 날짜 조회 버튼
     */
    @IBAction func pressTodayBtn(_ sender: Any) {
        //데이터 초기화
        self.taskData = [];
        self.monthSectionArr = [];
        
        initTaskData(pivotDate: Date());
        self.tableView.reloadData();
        
        //스크롤 맨 위로 올리기
        let indexPath = IndexPath(row: 0, section: 0);
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true);
    }
}

// MARK: UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let detailVC = DetailViewController();
        
        var padding = 0
        for i in 0..<indexPath.section {
            padding += self.monthSectionArr[i].0;
        }
        
        let task:myTask = self.taskData[padding + indexPath.row];
        
        let dayKeyFormatter = DateFormatter();
        dayKeyFormatter.setLocalizedDateFormatFromTemplate("yyMMdd");
        let dayKey:String = dayKeyFormatter.string(from: task.date);
        detailVC.dayTask = SharedData.instance.taskAllDic.object(forKey: dayKey) as? myTask;
        detailVC.tableIndexPath = indexPath;
        
        if (detailVC.dayTask == nil) {
            detailVC.dayTask = task;
        }
        
        if #available(iOS 11.0, *) {
            detailVC.view.frame = self.view.safeAreaLayoutGuide.layoutFrame
        } else {
            var frame = self.view.frame;
            frame.origin.y = frame.origin.y + UIApplication.shared.statusBarFrame.size.height;
            frame.size.height = frame.size.height - UIApplication.shared.statusBarFrame.size.height;
            detailVC.view.frame = frame;
        };

        self.addChildViewController(detailVC);
        self.view.addSubview(detailVC.view);
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) { //reach bottom
            appendTaskData(pivotDate: self.taskData[self.taskData.count-1].date, amountOfNumber: 30);
            self.tableView.reloadData();
        }
    }
}

// MARK: UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:TableViewCell! = self.tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell;
        cell.selectionStyle = .none;
        var padding = 0
        
        for i in 0..<indexPath.section {
            padding += self.monthSectionArr[i].0;
        }
        
        let task:myTask = self.taskData[padding + indexPath.row];

        //요일/일자 뽑아내기
        let dateFormatter = DateFormatter();
        dateFormatter.setLocalizedDateFormatFromTemplate("EEEE");
        let dayOfWeek:String = dateFormatter.string(from: task.date);
        dateFormatter.setLocalizedDateFormatFromTemplate("dd");
        let day:String = dateFormatter.string(from: task.date);
        
        if task.taskType == .today {
            cell.titleLabel?.text = "\(day) [\(dayOfWeek)] - today!";
        } else {
            cell.titleLabel?.text = "\(day) [\(dayOfWeek)]";
        }
        
        
        cell.bodyLabel?.text = task.body;
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var padding = 0
        for i in 0..<indexPath.section {
            padding += self.monthSectionArr[i].0;
        }
        
        if(self.taskData[padding + indexPath.row].body == ""){
            return 40;
        }
        
        return 200;
    }
    
    // MARK: 해더 관련
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.monthSectionArr.count;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.monthSectionArr[section].0;
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.monthSectionArr[section].1;
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    // MARK: Pull to refresh
    @objc private func refreshWeatherData(_ sender: Any) {
        // Fetch Weather Data
        insertTaskData(pivotDate: self.taskData[0].date, amountOfNumber: 30);
        self.tableView.reloadData();
        self.refreshControl.endRefreshing();
    }
}
