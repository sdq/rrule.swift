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
        let now = NSDate(year: 2015, month: 2, day: 16, hour: 7, minute: 20, second: 0)
        let rule = rrule(frequency: .Weekly, wkst: 2, dtstart: now, byweekday: [1,5], until: nil, count: nil)
        let recurrences = rule.getOccurrencesBetween(beginDate: NSDate(year: 2016, month: 2, day: 16), endDate: NSDate(year: 2017, month: 2, day: 16))
        for recurrence in recurrences {
            print("recurrence://\(recurrence + 8.hours)\n")
        }
    }
}

