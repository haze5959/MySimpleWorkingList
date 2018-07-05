//
//  ViewController.swift
//  MyWorkingList
//
//  Created by OQ on 2018. 7. 1..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let MARGIN_TO_PAST_DAY = -2;
    let MARGIN_TO_AFTER_DAY = 30;
    let APPDELEGATE_INSTANCE = (UIApplication.shared.delegate as! AppDelegate);

    @IBOutlet weak var titleLabel: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var taskData: Array<myTask> = [];
    /**
     0:해당 월의 값이 몇개인지
     1:해당 월
    */
    fileprivate var monthSectionArr: Array<(Int, String)> = [];
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl();
        refreshControl.attributedTitle = NSAttributedString(string: "일주일 이전 데이터 로드");
        refreshControl.addTarget(self, action: #selector(refreshWeatherData(_:)), for: .valueChanged)
//        refreshControl.tintColor = UIColor.red
        
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //초기화
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        self.tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "TableViewCell");
        
        self.titleLabel.title = "List";
        
        initTaskData(pivotDate: Date());
        
        if #available(iOS 10.0, *) {
            self.tableView.refreshControl = refreshControl
        } else {
            self.tableView.addSubview(refreshControl)
        }
        
//        let context = APPDELEGATE_INSTANCE.persistentContainer.viewContext
//        let work = Work(context: context) // Link Task & Context
//        work.setValue("test", forKey: "body");
//        
//        // Save the data to coredata
//        APPDELEGATE_INSTANCE.saveContext()
//        
//        let _ = navigationController?.popViewController(animated: true)
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
        
        //과거로부터 현재 미래까지
        for i in MARGIN_TO_PAST_DAY..<MARGIN_TO_AFTER_DAY{
            let date:Date = (Calendar.current.date(byAdding: .day, value: i, to: pivotDate))!;
            
            if(i == 0){
                self.taskData.append(myTask(date, .today));
            } else {
                self.taskData.append(myTask(date, .unknown));
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
//        let pastdate:Date = (Calendar.current.date(byAdding: .day, value: -amountOfNumber, to: pivotDate))!;
//        var pastMonth:String = dateFormatter.string(from: pastdate);
        var pivotMonth:String = dateFormatter.string(from: pivotDate);
        
        //과거로부터 현재 미래까지
        for i in 1..<amountOfNumber+1{
            let pastDate:Date = (Calendar.current.date(byAdding: .day, value: -i, to: pivotDate))!;
            self.taskData.insert(myTask(pastDate, .unknown), at: 0);
            
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

        //과거로부터 현재 미래까지
        for i in 1..<amountOfNumber+1{
            let date:Date = (Calendar.current.date(byAdding: .day, value: i, to: pivotDate))!;
            self.taskData.append(myTask(date, .unknown));

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
        print("click! - ", indexPath.row);
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
            cell.titleLabel?.text = "\(day) [\(dayOfWeek)] today!";
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
        
        return 120;
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
        insertTaskData(pivotDate: self.taskData[0].date, amountOfNumber: 10);
        self.tableView.reloadData();
        self.refreshControl.endRefreshing();
    }
}
