//
//  ViewController.swift
//  MyWorkingList
//
//  Created by OQ on 2018. 7. 1..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var titleLabel: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let itemsTitle: [String] = ["월(23)", "화(24)", "수(25)"]
    fileprivate let itemsBody: [String] = ["task1 4h", "task2 2h", "task3 1h"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //초기화
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        self.tableView.register(TableViewCell.self,
                                  forCellReuseIdentifier: "TableViewCell");
        
        self.titleLabel.title = "워크스페이스";
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
//        print(items[indexPath.row])
    }
}

// MARK: UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return self.itemsTitle.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell") as! TableViewCell;
        
//        cell.textLabel?.text = items[indexPath.row];
        cell.titleLabel?.text = itemsTitle[indexPath.row];
        var bodyStr = "";
        for task:String in itemsBody {
            bodyStr.append("\(task)\n");
        }
        
        cell.bodyLabel?.text = bodyStr;
        return cell
    }
}
