//
//  ViewController.swift
//  MyWorkingList
//
//  Created by OQ on 2018. 7. 1..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    static let MARGIN_TO_CURRENT_DAY = 30;

    @IBOutlet weak var titleLabel: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var taskData: Array<NSDictionary> = []
    fileprivate let itemsTitle: [String] = ["월(23)", "화(24)", "수(25)"]
    fileprivate let itemsBody: [String] = ["task1 4h", "task2 2h", "task3 1h"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //초기화
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        self.tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "TableViewCell");
        
        self.titleLabel.title = "워크스페이스";
        
        self.taskData = initTaskData(pivotDate: Date());
    }
    
    /**
     
    */
    func initTaskData(pivotDate:Date) -> Array<NSDictionary> {
        let dateFormatter = DateFormatter();
        dateFormatter.setLocalizedDateFormatFromTemplate("EEEE");
        
        for i in 0..<99 {
            print("(i)")
        }
        
        //과거로부터 현재까지
        for i in 30..>0{
            Calendar.current.date(byAdding: .day, value: i, to: pivotDate)
        }
        
        for i in 0..<(MARGIN_TO_CURRENT_DAY){
            Calendar.current.date(byAdding: .day, value: i, to: pivotDate)
        }
        
        
//        dateFormatter.string(from: <#T##Date#>)
        
        
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"EEEE"];
        NSLog(@"%@", [dateFormatter stringFromDate:[NSDate date]]);
        return [];
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return self.taskData.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:TableViewCell! = self.tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell;
    
        cell.titleLabel?.text = itemsTitle[indexPath.row];
        var bodyStr = "";
        for task:String in itemsBody {
            bodyStr.append("\(task)\n");
        }
        
        cell.bodyLabel?.text = bodyStr;
        return cell
        
//        cell.textLabel?.text = items[indexPath.row];
        
    }
}
