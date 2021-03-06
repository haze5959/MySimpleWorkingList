//
//  DetailViewController.swift
//  MyWorkingList
//
//  Created by 권오규 on 2018. 7. 10..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DetailViewController: UIViewController, UITextViewDelegate {

    var dayTask:myTask?
    var tableIndexPath:IndexPath?
    @IBOutlet weak var titleLabel: UINavigationItem!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    @IBOutlet weak var bottomMargin: NSLayoutConstraint!
    private let disposeBag = DisposeBag()
    //    @IBOutlet weak var alarmBtn: UIButton!
//    @IBOutlet weak var alarmBtnWidth: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.saveBtn.isEnabled = false
        self.textView.delegate = self
        
        let dayKeyFormatter = DateFormatter()
        
        guard let dateType = SharedData.instance.seletedWorkSpace?.dateType else {
            print("dateType is nil")
            return
        }
        
        switch dateType {
        case .day:
            dayKeyFormatter.setLocalizedDateFormatFromTemplate("EEEE")
            let dateEEE:String = dayKeyFormatter.string(from: (self.dayTask?.date)!)
            let dateShort:String = DateFormatter.localizedString(from: (self.dayTask?.date)!, dateStyle: .short, timeStyle: .none)
            let day:String  = "\(dateShort) \(dateEEE)"
            
            self.titleLabel.title = day
        case .week:
            let weekNumber = Calendar.current.component(.weekOfMonth, from: (self.dayTask?.date)!)  //첫 주는 1부터 시작
            dayKeyFormatter.setLocalizedDateFormatFromTemplate("MM/dd")
            let sunday = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: (self.dayTask?.date)!))!   
            let sundayStr:String = dayKeyFormatter.string(from: sunday)
            let saturday = Calendar.current.date(byAdding: .day, value: 6, to: sunday)
            let saturdayStr:String = dayKeyFormatter.string(from: saturday!)
            let week:String  = "\(weekNumber) Week(\(sundayStr)~\(saturdayStr))"
            
            self.titleLabel.title = week
        case .month:
            dayKeyFormatter.setLocalizedDateFormatFromTemplate("MM")
            let month:String  = dayKeyFormatter.string(from: (self.dayTask?.date)!)
            
            self.titleLabel.title = month
        }
        
        self.textView.text = self.dayTask?.body
        self.textView.font = UIFont.systemFont(ofSize: SharedData().fontSize.getValue())
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        self.textView.becomeFirstResponder()   //포커스 잡기
    }

    @IBAction func pressSaveBtn(_ sender: Any) {
        
        guard self.textView.text.count < 5000 else {
            (UIApplication.shared.delegate as! AppDelegate).alertPopUp(bodyStr: "Can't exceed 5000 characters.", alertClassify: .normal)
            return
        }
        
        if self.dayTask?.id == nil || self.dayTask?.id == "" {    //새로 저장
            //******클라우드에 새 메모 저장******
            (UIApplication.shared.delegate as! AppDelegate).makeDayTask(workSpaceId: (SharedData.instance.seletedWorkSpace?.id)!, taskDate: (self.dayTask?.date)!, taskBody: self.textView.text, indexPath: self.tableIndexPath!)
            //***********************************
        } else { //기존 수정
            //******클라우드에 매모 수정******
            self.dayTask?.body = self.textView.text
            (UIApplication.shared.delegate as! AppDelegate).updateDayTask(task: self.dayTask!, indexPath: self.tableIndexPath!)
            //***********************************
        }
        
        self.closeDetailView()
    }
    
    @IBAction func pressBackBtn(_ sender: Any) {
        self.closeDetailView()
    }
    
    func closeDetailView() {
        if let parent = self.parent as? ViewController {
            parent.setEdgeGesture()
        }
        
        self.view.endEditing(true)
        self.removeFromParent()
        self.view.removeFromSuperview()
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
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            self.bottomMargin.constant = keyboardHeight
        }
    }
}
