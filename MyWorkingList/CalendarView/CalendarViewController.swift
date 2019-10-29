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
        self.closeCalendarView()
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
            SharedData.instance.seletedWorkSpace?.pivotDate = date;
            SharedData.instance.workSpaceUpdateObserver?.onNext(SharedData.instance.seletedWorkSpace!);
            self.closeCalendarView()
        }
    }

    func closeCalendarView() {
        if let parent = self.parent as? ViewController {
            parent.setEdgeGesture()
        }
        
        self.removeFromParent()
        self.view.removeFromSuperview()
    }
}
