//
//  AppDelegate.swift
//  RecurrenceTest
//
//  Created by sdq on 7/18/16.
//  Copyright © 2016 sdq. All rights reserved.
//

import UIKit
import SwiftDate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        let now = NSDate()
        let rule = rrule(frequency: .Monthly, dtstart: now, until: nil, count: 10)
        let recurrences = rule.getOccurrences()
        for recurrence in recurrences {
            print("recurrence://\(recurrence)\n")
        }

        return true
    }

}

