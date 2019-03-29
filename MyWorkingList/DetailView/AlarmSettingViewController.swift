//
//  AlarmSettingViewController.swift
//  MyWorkingList
//
//  Created by 권오규 on 29/03/2019.
//  Copyright © 2019 OQ. All rights reserved.
//

import UIKit

class AlarmSettingViewController: UIViewController {
    @IBOutlet weak var alarmSwitch: UISwitch!
    @IBOutlet weak var alarmDaySegment: UISegmentedControl!
    @IBOutlet weak var alarmTimePicker: UIDatePicker!
    @IBOutlet weak var alarmConfirmBtn: UIButton!
    
    enum daySegment: Int {
        case today
        case oneDayAgo
        case twoDaysAgo
        case weekAgo
        
        func getIntDay() -> Int {
            switch self {
            case .today:
                return 0
            case .oneDayAgo:
                return 1
            case .twoDaysAgo:
                return 2
            default:
                return 7
            }
        }
    }
    
    var taskDate:Date?
    var alarmDate:Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //초기화
        if let alarmDate = self.alarmDate, let taskDate = self.taskDate {
            self.alarmSwitch.isOn = true
            self.alarmSwitch.isEnabled = true
            self.alarmTimePicker.isEnabled = true
            
            //Day 설정
            let calendar = Calendar.current
            let alarmDay = calendar.startOfDay(for: alarmDate)
            let taskDay = calendar.startOfDay(for: taskDate)
            
            let betweenDay:daySegment = daySegment(rawValue:calendar.dateComponents([.day], from: alarmDay, to: taskDay).day!)!
            
            switch betweenDay {
            case .today:
                self.alarmDaySegment.selectedSegmentIndex = 0
            case .oneDayAgo:
                self.alarmDaySegment.selectedSegmentIndex = 1
            case .twoDaysAgo:
                self.alarmDaySegment.selectedSegmentIndex = 2
            default:
                self.alarmDaySegment.selectedSegmentIndex = 3
            }
            
            //Time 설정
            self.alarmTimePicker.date = alarmDay
            
        } else {
            self.alarmSwitch.isOn = false
            self.alarmSwitch.isEnabled = false
            self.alarmTimePicker.isEnabled = false
            
        }
        
    }

    @IBAction func pressAlarmSwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.alarmSwitch.isOn = true
            self.alarmSwitch.isEnabled = true
            self.alarmTimePicker.isEnabled = true
            
            if let alarmDate = self.alarmDate, let taskDate = self.taskDate {
                //Day 설정
                let calendar = Calendar.current
                let alarmDay = calendar.startOfDay(for: alarmDate)
                let taskDay = calendar.startOfDay(for: taskDate)
                
                let betweenDay:daySegment = daySegment(rawValue:calendar.dateComponents([.day], from: alarmDay, to: taskDay).day!)!
                
                switch betweenDay {
                case .today:
                    self.alarmDaySegment.selectedSegmentIndex = 0
                case .oneDayAgo:
                    self.alarmDaySegment.selectedSegmentIndex = 1
                case .twoDaysAgo:
                    self.alarmDaySegment.selectedSegmentIndex = 2
                default:
                    self.alarmDaySegment.selectedSegmentIndex = 3
                }
                
                //Time 설정
                self.alarmTimePicker.date = alarmDay
                
            } else {    //첫 알람 설정
                self.alarmDaySegment.selectedSegmentIndex = 0
                self.alarmTimePicker.date = Date()
                
            }
            
        } else {
            self.alarmSwitch.isOn = false
            self.alarmSwitch.isEnabled = false
            self.alarmTimePicker.isEnabled = false
            
        }
    }
    
    @IBAction func pressAlarmConfirmBtn(_ sender: Any) {
        if self.alarmSwitch.isOn {
            let betweenDay:daySegment = daySegment(rawValue:self.alarmDaySegment.selectedSegmentIndex)!
            
            let calendar = Calendar.current
            guard let taskDate = self.taskDate else {
                return
            }
            
            let date:Date = (calendar.date(byAdding: .day, value: betweenDay.getIntDay(), to: taskDate))!
            self.alarmDate = date
            
            //TODO: 알람 세팅 기능!!
        } else {
            self.alarmDate = nil
            
            //TODO: 알람 삭제 기능!!
        }
        
        let parentVC = self.parent as! DetailViewController
        parentVC.dayTask?.alarmDate = self.alarmDate
        parentVC.setAlarmBtnTitle(date: self.alarmDate)
        
        self.view.removeFromSuperview();
        self.removeFromParentViewController();
    }
}
