//
//  SideViewController.swift
//  MyWorkingList
//
//  Created by 권오규 on 2018. 7. 4..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit

class SideViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func pressDonationBtn(_ sender: Any) {
    }
    
    @IBAction func pressEditBtn(_ sender: Any) {
    }
    
    @IBAction func pressAddBtn(_ sender: Any) {
    }
    
    @IBAction func pressOutOfView(_ sender: Any) {
        self.view.removeFromSuperview();
        self.removeFromParentViewController();
    }
    
    
}

// MARK: UITableViewDelegate
extension SideViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("click! - ", indexPath.row);
        
        if(SharedData.instance.workSpaceArr[indexPath.row].name != SharedData.instance.seletedWorkSpace?.name){
            SharedData.instance.seletedWorkSpace = SharedData.instance.workSpaceArr[indexPath.row];
            SharedData.instance.taskUpdateObserver?.onNext(SharedData.instance.seletedWorkSpace!);
        }
    }
}

// MARK: UITableViewDataSource
extension SideViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Cell");
        if(SharedData.instance.workSpaceArr[indexPath.row].name == SharedData.instance.seletedWorkSpace?.name){
            cell.textLabel?.text = SharedData.instance.workSpaceArr[indexPath.row].name + " - Seleted!";
        } else {
            cell.textLabel?.text = SharedData.instance.workSpaceArr[indexPath.row].name;
        }
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SharedData.instance.workSpaceArr.count;
    }
    
    // 왼쪽 공백 제거
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.layoutMargins = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
    }
}








