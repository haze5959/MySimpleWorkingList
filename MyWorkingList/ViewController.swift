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

    @IBOutlet weak var titleLabel: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var taskData: Array<myTask> = [];
    /**
     0:해당 월의 값이 몇개인지
     1:해당 월
    */
    fileprivate var monthSectionArr: Array<(Int, String)> = [];
    fileprivate let itemsBody: [String] = ["task1 4h", "task2 2h", "task3 1h"];
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl();
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
        
        self.titleLabel.title = "워크스페이스";
        
        initTaskData(pivotDate: Date());
        
        if #available(iOS 10.0, *) {
            self.tableView.refreshControl = refreshControl
        } else {
            self.tableView.addSubview(refreshControl)
        }
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
            self.taskData.append(myTask(date));
            
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
        let tempdate:Date = (Calendar.current.date(byAdding: .day, value: -amountOfNumber, to: pivotDate))!;
        var tempMonth:String = dateFormatter.string(from: tempdate);
        var sectionContainNum:Int = 0;
        
        //과거로부터 현재 미래까지
        for i in -amountOfNumber..<0{
            let date:Date = (Calendar.current.date(byAdding: .day, value: i, to: pivotDate))!;
            self.taskData.append(myTask(date));
            
            //월이 바뀌면 섹션을 추가한다.
            let month:String = dateFormatter.string(from: date);
            if(month != tempMonth){
                self.monthSectionArr.append((sectionContainNum, tempMonth));
                tempMonth = month;
                sectionContainNum = 0;
            }
            
            sectionContainNum += 1;
        }
        
//        self.monthSectionArr.append((sectionContainNum, tempMonth));
    }
    
    func appendTaskData(pivotDate:Date!, amountOfNumber:Int) -> Void {
        let dateFormatter = DateFormatter();
        dateFormatter.setLocalizedDateFormatFromTemplate("M");
        let tempdate:Date = (Calendar.current.date(byAdding: .day, value: MARGIN_TO_PAST_DAY, to: pivotDate))!;
        var tempMonth:String = dateFormatter.string(from: tempdate);
        var sectionContainNum:Int = 0;
        
        //과거로부터 현재 미래까지
        for i in MARGIN_TO_PAST_DAY..<MARGIN_TO_AFTER_DAY{
            let date:Date = (Calendar.current.date(byAdding: .day, value: i, to: pivotDate))!;
            self.taskData.append(myTask(date));
            
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
}

// MARK: UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("click! - ", indexPath.row);
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
        
        cell.titleLabel?.text = "\(day)[\(dayOfWeek)]";
        var bodyStr = "";
        for task:String in itemsBody {
            bodyStr.append("\(task)\n");
        }
        
        cell.bodyLabel?.text = bodyStr;
        return cell
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
        self.tableView.reloadData()
        self.refreshControl.endRefreshing();
    }
}
