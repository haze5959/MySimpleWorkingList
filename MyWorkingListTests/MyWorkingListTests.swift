//
//  MyWorkingListTests.swift
//  MyWorkingListTests
//
//  Created by OQ on 2018. 7. 1..
//  Copyright © 2018년 OQ. All rights reserved.
//

import XCTest
@testable import MyWorkingList

class MyWorkingListTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let calendarVC = CalendarViewController()
        let appDelegate = UIApplication.shared.delegate as! MyWorkingList.AppDelegate
        appDelegate.navigationVC.present(calendarVC, animated: true, completion: nil)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
