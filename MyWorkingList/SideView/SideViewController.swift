//
//  SideViewController.swift
//  MyWorkingList
//
//  Created by 권오규 on 2018. 7. 4..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit
import CloudKit
import Dialog

class SideViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var buyPremiumBtn: UIBarButtonItem!
    
    var pickedDateType:DateType = .day

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.resetDonationBtn()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.resetDonationBtn),
                                               name: .IAPHelperPurchaseNotification,
                                               object: nil)
    }
    
    @IBAction func pressDonationBtn(_ sender: Any) {
        print("[SideVC] press Preminum Btn!")
        (UIApplication.shared.delegate as! AppDelegate).showPhurcaseDialog()
    }
    
    @IBAction func pressEditBtn(_ sender: Any) {
        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
    }
    
    @IBAction func pressAddBtn(_ sender: Any) {
        self.pickedDateType = .day
        let alert = UIAlertController(title: "New WorkSpace", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Input your new workspace name..."
        })
        
        let contentVC = UIViewController()
        contentVC.preferredContentSize = CGSize(width: 250,height: 100)
        let pickerFrame = UIPickerView(frame: CGRect(x: 0, y: 0, width: 250, height: 100))
        //set the pickers datasource and delegate
        pickerFrame.delegate = self
        pickerFrame.dataSource = self
        //Add the picker to the alert controller
        contentVC.view.addSubview(pickerFrame)
        alert.setValue(contentVC, forKey: "contentViewController")
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            let name:String? = alert.textFields?.first?.text
            if (name != nil) && name != ""  {
//                print("Your name: \(name!)");
                let parentVC = self.parent as! ViewController
                parentVC.shadowView.isHidden = true
                parentVC.taskData = []
                parentVC.monthSectionArr = []
                SharedData.instance.taskAllDic.removeAllObjects()
                
                //******클라우드에 새 워크스페이즈 저장******
                (UIApplication.shared.delegate as! AppDelegate).makeWorkSpace(workSpaceName:  name!, dateType: self.pickedDateType)
                //***********************************
                self.tableView.reloadData()
                self.view.removeFromSuperview()
                self.removeFromParent()
                
            } else {
                let cancelAlert = UIAlertController(title: "alert", message: "value is empty.", preferredStyle: .alert)
                cancelAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.navigationController?.present(cancelAlert, animated: true)
            }
        }))
        
        self.navigationController?.present(alert, animated: true)
    }
    
    @IBAction func pressOutOfView(_ sender: Any) {
        let parentVC = self.parent as! ViewController
        
        UIView.animate(withDuration: 0.3, animations: {
            parentVC.shadowView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0)
            self.view.frame.origin.x = -self.view.frame.size.width
        }) { (value) in
            parentVC.shadowView.isHidden = true
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
    }
    
    @objc func resetDonationBtn() {
        if PremiumProducts.store.isProductPurchased(PremiumProducts.premiumVersion) {
            self.buyPremiumBtn.title = "Premium"
            self.buyPremiumBtn.isEnabled = false
        }
    }
}

// MARK: UITableViewDelegate
extension SideViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //기존이랑 똑같은 워크스페이스를 선택하지 않았다면
        if(SharedData.instance.workSpaceArr[indexPath.row].name != SharedData.instance.seletedWorkSpace?.name){
            let parentVC = self.parent as! ViewController
            
            SharedData.instance.seletedWorkSpace = SharedData.instance.workSpaceArr[indexPath.row]
            SharedData.instance.workSpaceUpdateObserver?.onNext(SharedData.instance.seletedWorkSpace!)
            UserDefaults().set(SharedData.instance.seletedWorkSpace?.id, forKey: "seletedWorkSpaceId")
            UserDefaults().set(SharedData.instance.seletedWorkSpace?.name, forKey: "seletedWorkSpaceName")
            UserDefaults().set(SharedData.instance.seletedWorkSpace?.dateType.rawValue, forKey: "seletedWorkSpaceDateType")
            self.view.removeFromSuperview()
            self.removeFromParent()
            parentVC.shadowView.isHidden = true
        }
    }
}

// MARK: UITableViewDataSource
extension SideViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "Cell")
        
        var dateType = ""
        switch SharedData.instance.workSpaceArr[indexPath.row].dateType! {
        case .day:
            dateType = "Daily"
        case .week:
            dateType = "Weekly"
        case .month:
            dateType = "Monthly"
        }
        
        if(SharedData.instance.workSpaceArr[indexPath.row].name == SharedData.instance.seletedWorkSpace?.name){
            cell.textLabel?.text = SharedData.instance.workSpaceArr[indexPath.row].name + " [\(dateType)]" + " - Seleted!"
        } else {
            cell.textLabel?.text = SharedData.instance.workSpaceArr[indexPath.row].name + " [\(dateType)]"
        }
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SharedData.instance.workSpaceArr.count
    }
    
    // 왼쪽 공백 제거
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.layoutMargins = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCell.EditingStyle.delete) {
            (UIApplication.shared.delegate as! AppDelegate).deleteRecord(recordId: SharedData.instance.workSpaceArr[indexPath.row].id)
            
            if(SharedData.instance.workSpaceArr[indexPath.row].name == SharedData.instance.seletedWorkSpace?.name){ //선택된 셀을 지우는 거라면
                SharedData.instance.workSpaceArr.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                
                SharedData.instance.seletedWorkSpace = SharedData.instance.workSpaceArr[0]
                tableView.reloadData()
                SharedData.instance.workSpaceUpdateObserver?.onNext(SharedData.instance.seletedWorkSpace!)
                
            } else {
                SharedData.instance.workSpaceArr.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                
            }
        } else if (editingStyle == UITableViewCell.EditingStyle.insert) {
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let renameAction = UITableViewRowAction(style: .normal, title: "Rename") { action, index in
            let alert = UIAlertController(title: "Rename WorkSpace", message: nil, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            alert.addTextField(configurationHandler: { textField in
                textField.placeholder = "Input your new workspace name..."
                textField.text = SharedData.instance.workSpaceArr[editActionsForRowAt.row].name
            })
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                let name:String? = alert.textFields?.first?.text
                if (name != nil) && name != ""  {
                    //******클라우드에 새 워크스페이즈 저장******
                    (UIApplication.shared.delegate as! AppDelegate).updateWorkSpace(recordId: SharedData.instance.workSpaceArr[editActionsForRowAt.row].id, newName: name!)
                    //***********************************
                    SharedData.instance.workSpaceArr[editActionsForRowAt.row] = myWorkspace(id: SharedData.instance.workSpaceArr[editActionsForRowAt.row].id, name: name!, dateType: SharedData.instance.workSpaceArr[editActionsForRowAt.row].dateType)
                    self.tableView.reloadData()
                    
                    UserDefaults().set(SharedData.instance.seletedWorkSpace?.id, forKey: "seletedWorkSpaceId")
                    UserDefaults().set(SharedData.instance.seletedWorkSpace?.name, forKey: "seletedWorkSpaceName")
                    UserDefaults().set(SharedData.instance.seletedWorkSpace?.dateType.rawValue, forKey: "seletedWorkSpaceDateType")
                    SharedData.instance.seletedWorkSpace = SharedData.instance.workSpaceArr[editActionsForRowAt.row]
                    SharedData.instance.workSpaceUpdateObserver?.onNext(SharedData.instance.seletedWorkSpace!)
                } else {
                    let cancelAlert = UIAlertController(title: "alert", message: "value is empty.", preferredStyle: .alert)
                    cancelAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.navigationController?.present(cancelAlert, animated: true)
                }
            }))
            
            self.navigationController?.present(alert, animated: true)
        }
        renameAction.backgroundColor = .lightGray
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
            if SharedData.instance.workSpaceArr.count < 2 { //워크스페이스가 2개 미만이라면
                let cancelAlert = UIAlertController(title: "alert", message: "at least you must have two workspace.", preferredStyle: .alert)
                cancelAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.navigationController?.present(cancelAlert, animated: true)
                return
            }
            //******클라우드 해당 워크스페이스 및 일정들 삭제******
            (UIApplication.shared.delegate as! AppDelegate).deleteRecord(recordId: SharedData.instance.workSpaceArr[editActionsForRowAt.row].id)
            //***********************************
            
            //선택된 워크스페이스랑 똑같은 워크스페이스를 선택했다면
            if(SharedData.instance.workSpaceArr[editActionsForRowAt.row].name == SharedData.instance.seletedWorkSpace?.name){
                //데이터 초기화
                let parentVC = self.parent as! ViewController
                SharedData.instance.seletedWorkSpace = SharedData.instance.workSpaceArr[0]
                SharedData.instance.workSpaceUpdateObserver?.onNext(SharedData.instance.seletedWorkSpace!)
                UserDefaults().set(SharedData.instance.seletedWorkSpace?.id, forKey: "seletedWorkSpaceId")
                UserDefaults().set(SharedData.instance.seletedWorkSpace?.name, forKey: "seletedWorkSpaceName")
                UserDefaults().set(SharedData.instance.seletedWorkSpace?.dateType.rawValue, forKey: "seletedWorkSpaceDateType")
                self.view.removeFromSuperview()
                self.removeFromParent()
                parentVC.shadowView.isHidden = true
            }
            
            SharedData.instance.workSpaceArr.remove(at: editActionsForRowAt.row)
            self.tableView.reloadData()
        }
        deleteAction.backgroundColor = .red
        
        return [deleteAction, renameAction]
    }
    
    // MARK: - UIPickerViewDataSource
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return DateType.allCases.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch row {
        case DateType.day.rawValue:
            return "Daily"
        case DateType.week.rawValue:
            return "Weekly"
        case DateType.month.rawValue:
            return "Monthly"
        default:
            return "Daily"
        }
    }
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.pickedDateType = DateType(rawValue: row)!
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
}








