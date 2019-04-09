//
//  CalendarViewController.swift
//  MyWorkingList
//
//  Created by 권오규 on 2018. 10. 4..
//  Copyright © 2018년 OQ. All rights reserved.
//

import UIKit
import FSCalendar

class CalendarViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate {

    @IBOutlet weak var calendar: FSCalendar!
    
    fileprivate let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    fileprivate let gregorian: NSCalendar! = NSCalendar(calendarIdentifier:NSCalendar.Identifier.gregorian)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.calendar.appearance.caseOptions = [.headerUsesUpperCase,.weekdayUsesUpperCase]
        self.calendar.select(Date())
    }

    @IBAction func pressOutOfView(_ sender: Any) {
        self.view.removeFromSuperview();
        self.removeFromParent();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK:- FSCalendarDataSource
    
    func calendar(_ calendar: FSCalendar, titleFor date: Date) -> String? {
        return self.gregorian.isDateInToday(date) ? "Today" : nil
    }
    
    // MARK:- FSCalendarDelegate
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        print("change page to \(self.formatter.string(from: calendar.currentPage))")
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        print("calendar did select date \(self.formatter.string(from: date))")
        if monthPosition == .previous || monthPosition == .next {
            calendar.setCurrentPage(date, animated: true)
        } else {
            let parentVC = self.parent as! ViewController;
            parentVC.taskData = [];
            parentVC.monthSectionArr = [];
            SharedData.instance.taskAllDic.removeAllObjects();
            SharedData.instance.seletedWorkSpace?.pivotDate = date;
            SharedData.instance.workSpaceUpdateObserver?.onNext(SharedData.instance.seletedWorkSpace!);
            self.view.removeFromSuperview();
            self.removeFromParent();
        }
    }

}
