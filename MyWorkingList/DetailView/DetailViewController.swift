//
//  DetailViewController.swift
//  MyWorkingList
//
//  Created by 권오규 on 2018. 7. 10..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    var dayTask:myTask?
    var tableIndexPath:IndexPath?
    @IBOutlet weak var titleLabel: UINavigationItem!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    @IBOutlet weak var titleTextField: UITextField!
//    @IBOutlet weak var alarmBtn: UIButton!
//    @IBOutlet weak var alarmBtnWidth: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.saveBtn.isEnabled = false
        self.textView.delegate = self
        self.titleTextField.delegate = self
        
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("MM-dd-EEEE");
        let day:String = dateFormatter.string(from: (self.dayTask?.date)!);
        self.titleLabel.title = day
        self.titleTextField.text = self.dayTask?.title
        self.textView.text = self.dayTask?.body
        self.textView.becomeFirstResponder()   //포커스 잡기
        
//        self.setAlarmBtnTitle(date: self.dayTask?.alarmDate)
    }

    @IBAction func pressSaveBtn(_ sender: Any) {
        
        guard self.textView.text.count < 2000 else {
            (UIApplication.shared.delegate as! AppDelegate).alertPopUp(bodyStr: "2000자를 넘길 수 없습니다.", alertClassify: .normal)
            return
        }
        
        if self.dayTask?.id == nil || self.dayTask?.id == "" {    //새로 저장
            //******클라우드에 새 메모 저장******
            (UIApplication.shared.delegate as! AppDelegate).makeDayTask(workSpaceId: (SharedData.instance.seletedWorkSpace?.id)!, taskDate: (self.dayTask?.date)!, taskBody: self.textView.text, taskTitle: self.titleTextField.text, indexPath: self.tableIndexPath!)
            //***********************************
        } else { //기존 수정
            //******클라우드에 매모 수정******
            self.dayTask?.body = self.textView.text
            self.dayTask?.title = self.titleTextField.text
            (UIApplication.shared.delegate as! AppDelegate).updateDayTask(task: self.dayTask!, indexPath: self.tableIndexPath!)
            //***********************************
        }
        
        self.view.removeFromSuperview();
        self.removeFromParent();
    }
    
    @IBAction func pressBackBtn(_ sender: Any) {
        self.view.removeFromSuperview();
        self.removeFromParent();
    }
    
//    @IBAction func pressAlarmBtn(_ sender: Any) {
//        self.view.endEditing(true)
//        let AlarmSettingVC = AlarmSettingViewController()
//
//        var frame = self.view.frame;
//        frame.origin.y = 0;
//        AlarmSettingVC.view.frame = frame
//
//        AlarmSettingVC.taskDate = self.dayTask?.date
//        AlarmSettingVC.alarmDate = self.dayTask?.alarmDate
//
//        self.addChildViewController(AlarmSettingVC)
//        self.view.addSubview(AlarmSettingVC.view)
//    }
    
//    open func setAlarmBtnTitle(date: Date?) {
//        if let alarmDate = date {    //알람 있음
//            let dateFormatter = DateFormatter()
//            dateFormatter.setLocalizedDateFormatFromTemplate("MM/dd/hh:mm")
//            let alarmTime:String = dateFormatter.string(from: alarmDate)
//            self.alarmBtn.titleLabel?.text = "\(alarmTime)🔔"
//            self.alarmBtn.titleLabel?.setNeedsLayout()
//            self.alarmBtnWidth.constant = 200
//        } else {    //알람 없음
//            self.alarmBtn.titleLabel?.text = "🔕"
//        }
//    }
    
    // MARK: UITextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        saveBtn.isEnabled = true;
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        saveBtn.isEnabled = true;
        return true;
    }
}
