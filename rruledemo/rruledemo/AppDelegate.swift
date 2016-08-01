//
//  AppDelegate.swift
//  rruledemo
//
//  Created by sdq on 7/20/16.
//  Copyright © 2016 sdq. All rights reserved.
//

import Cocoa
import SwiftDate

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        //test()
    }
    
    func test() {
        let rule = rrule(frequency: .Daily, dtstart: NSDate(year: 2016, month: 8, day:1), interval: 2, inclusionDates: [NSDate(year: 2016, month: 8, day:2)], exclusionDates: [NSDate(year: 2016, month: 8, day:3)])
        
        let occurenceArray = rule.getOccurrences()
        print(occurenceArray)
    }
}

