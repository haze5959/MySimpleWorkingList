//
//  SideViewController.swift
//  MyWorkingList
//
//  Created by 권오규 on 2018. 7. 4..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit
import CloudKit

class SideViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func pressDonationBtn(_ sender: Any) {
    }
    
    @IBAction func pressEditBtn(_ sender: Any) {
        self.tableView.setEditing(!self.tableView.isEditing, animated: true);
    }
    
    @IBAction func pressAddBtn(_ sender: Any) {
        let alert = UIAlertController(title: "New WorkSpace", message: nil, preferredStyle: .alert);
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil));
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "input your new workspace name..."
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            let name:String? = alert.textFields?.first?.text;
            if (name != nil) && name != ""  {
//                print("Your name: \(name!)");
                
                //******클라우드에 새 워크스페이즈 저장******
                (UIApplication.shared.delegate as! AppDelegate).makeWorkSpace(workSpaceName: name!);
                //***********************************
                self.tableView.reloadData();
                self.view.removeFromSuperview();
                self.removeFromParentViewController();
                
            } else {
                let cancelAlert = UIAlertController(title: "alert", message: "value is empty.", preferredStyle: .alert);
                cancelAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil));
                self.navigationController?.present(cancelAlert, animated: true);
            }
        }))
        
        self.navigationController?.present(alert, animated: true);
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
            UserDefaults().set(SharedData.instance.seletedWorkSpace?.id, forKey: "seletedWorkSpaceId");
            UserDefaults().set(SharedData.instance.seletedWorkSpace?.name, forKey: "seletedWorkSpaceName");
            self.view.removeFromSuperview();
            self.removeFromParentViewController();
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            (UIApplication.shared.delegate as! AppDelegate).deleteRecord(recordId: SharedData.instance.workSpaceArr[indexPath.row].id);
            
            if(SharedData.instance.workSpaceArr[indexPath.row].name == SharedData.instance.seletedWorkSpace?.name){ //선택된 셀을 지우는 거라면
                SharedData.instance.workSpaceArr.remove(at: indexPath.row);
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic);
                
                SharedData.instance.seletedWorkSpace = SharedData.instance.workSpaceArr[0];
                SharedData.instance.taskUpdateObserver?.onNext(SharedData.instance.seletedWorkSpace!);
                tableView.reloadData();
                SharedData.instance.taskUpdateObserver?.onNext(SharedData.instance.seletedWorkSpace!);
                
            } else {
                SharedData.instance.workSpaceArr.remove(at: indexPath.row);
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic);
                
            }
        } else if (editingStyle == UITableViewCellEditingStyle.insert) {
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let more = UITableViewRowAction(style: .normal, title: "Rename") { action, index in
            let alert = UIAlertController(title: "Rename WorkSpace", message: nil, preferredStyle: .alert);
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil));
            
            alert.addTextField(configurationHandler: { textField in
                textField.placeholder = "input your new workspace name..."
                textField.text = SharedData.instance.workSpaceArr[editActionsForRowAt.row].name;
            })
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                let name:String? = alert.textFields?.first?.text;
                if (name != nil) && name != ""  {
                    //******클라우드에 새 워크스페이즈 저장******
                    (UIApplication.shared.delegate as! AppDelegate).updateWorkSpace(recordId: SharedData.instance.workSpaceArr[editActionsForRowAt.row].id, newName: name!);
                    //***********************************
                    SharedData.instance.workSpaceArr[editActionsForRowAt.row] = myWorkspace(id: SharedData.instance.workSpaceArr[editActionsForRowAt.row].id, name: name!);
                    self.tableView.reloadData();
                    SharedData.instance.seletedWorkSpace = SharedData.instance.workSpaceArr[editActionsForRowAt.row];
                    SharedData.instance.taskUpdateObserver?.onNext(SharedData.instance.seletedWorkSpace!);
                } else {
                    let cancelAlert = UIAlertController(title: "alert", message: "value is empty.", preferredStyle: .alert);
                    cancelAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil));
                    self.navigationController?.present(cancelAlert, animated: true);
                }
            }))
            
            self.navigationController?.present(alert, animated: true);
        }
        more.backgroundColor = .lightGray
        
//        let favorite = UITableViewRowAction(style: .normal, title: "Favorite") { action, index in
//            print("favorite button tapped")
//        }
//        favorite.backgroundColor = .orange
//        
//        let share = UITableViewRowAction(style: .normal, title: "Share") { action, index in
//            print("share button tapped")
//        }
//        share.backgroundColor = .blue
        
        return [more]
    }
}








