//
//  RRuleSwift.swift
//  RecurrenceTest
//
//  Created by sdq on 6/29/16.
//  Copyright © 2016 sdq. All rights reserved.
//

import Foundation
import EventKit
import SwiftDate

public enum RecurrenceFrequency {
    case Yearly
    case Monthly
    case Weekly
    case Daily
    case Hourly //Todo
    case Minutely //Todo
    case Secondly //Todo
}

private struct DateMask {
    var year: Int = 0
    var month: Int = 0
    var leapYear: Bool = false
    var nextYearLength: Int = 0
    var lastdayOfMonth: [Int]?
    var weekdayOf1stYearday: Int = 0
    var yeardayToWeekday: [Int]?
    var yeardayToMonth: [Int]?
    var yeardayToMonthday: [Int]?
    var yeardayToMonthdayNegtive: [Int]?
    var yearLength: Int = 0
    var yeardayIsNthWeekday: [Int:Bool]?
    var yeardayIsInWeekno: [Int:Bool]?
}

class rrule {
    
    var frequency: RecurrenceFrequency
    var interval = 1
    var wkst: Int = 1
    var dtstart = NSDate()
    var until: NSDate?
    var count: Int?
    var bysetpos = [Int]()
    var byyearday = [Int]()
    var bymonth = [Int]()
    var byweekno = [Int]()
    var bymonthday = [Int]()
    var bymonthdayNegative = [Int]()
    var byweekday = [Int]()
    var byweekdaynth = [Int]()
    var byhour = [Int]()
    var byminute = [Int]()
    var bysecond = [Int]()
    
    private var year: Int = 0
    private var month: Int = 0
    private var day: Int = 0
    private var hour: Int = 0
    private var minute: Int = 0
    private var second: Int = 0
    private var dayset: [Int]?
    private var total: Int?
    private var masks = DateMask()

    init(frequency: RecurrenceFrequency, dtstart: NSDate? = nil, until: NSDate? = nil, count:Int? = nil, interval:Int = 1, wkst: Int = 1, bysetpos: [Int] = [], bymonth: [Int] = [], bymonthday: [Int] = [], byyearday: [Int] = [], byweekno: [Int] = [], byweekday: [Int] = [], byhour: [Int] = [], byminute: [Int] = [], bysecond: [Int] = []) {
        self.frequency = frequency
        if let dtstart = dtstart {
            self.dtstart = dtstart
        }
        if let until = until {
            self.until = until
        }
        if let count = count {
            self.count = count
        }
        
        self.interval = interval
        self.wkst = wkst
        self.bysetpos = bysetpos
        self.bymonth = bymonth
        self.byyearday = byyearday
        self.byweekno = byweekno
        self.byweekday = byweekday
        self.byhour = byhour
        self.byminute = byminute
        self.bysecond = bysecond

        for monthday in bymonthday {
            if monthday < -31 || monthday > 31 {
                continue
            }
            if monthday < 0 {
                self.bymonthdayNegative.append(monthday)
            } else {
                self.bymonthday.append(monthday)
            }
        }

        // Complete the recurrence rule
        if self.byweekno.count == 0 && self.byyearday.count == 0 && self.bymonthday.count == 0 && self.byweekday.count == 0 {
            switch frequency {
            case .Yearly:
                if bymonth.count == 0 {
                    if let month = dtstart?.month {
                        self.bymonth = [month]
                    }
                }
                if let day = dtstart?.day {
                    self.bymonthday = [day]
                }
            case .Monthly:
                if let day = dtstart?.day {
                    self.bymonthday = [day]
                }
            case .Weekly:
                if let weekday = dtstart?.weekday {
                    self.byweekday = [weekday]
                }
            default:
                break
            }
        }
    }
    
    func getOccurrences() -> [NSDate] {

        year = dtstart.year
        month = dtstart.month
        day = dtstart.day
        hour = dtstart.hour
        minute = dtstart.minute
        second = dtstart.second
        
        let max = MaxRepeatCycle[frequency]!

        var occurrences = [NSDate]()
        
        for _ in 0..<max {
            // 1. get dayset in the next interval
            if masks.year == 0 || masks.month == 0 || masks.year != year || masks.month != month {
                //only if year change
                if masks.year != year {
                    masks.leapYear = isLeapYear(year)
                    if isLeapYear(year) {
                        masks.yearLength = 366
                        masks.yeardayToMonth = M366MASK
                        masks.yeardayToMonthday = MDAY366MASK
                        masks.yeardayToMonthdayNegtive = NMDAY366MASK
                        masks.lastdayOfMonth = M366RANGE
                    } else {
                        masks.yearLength = 365
                        masks.yeardayToMonth = M365MASK
                        masks.yeardayToMonthday = MDAY365MASK
                        masks.yeardayToMonthdayNegtive = NMDAY365MASK
                        masks.lastdayOfMonth = M365RANGE
                    }
                    if isLeapYear(year+1) {
                        masks.nextYearLength = 366
                    } else {
                        masks.nextYearLength = 365
                    }
                    let weekdayOf1stYearday = NSDate(year: year, month: 1, day: 1).weekday
                    let yeardayToWeekday = Array(WDAYMASK.suffixFrom(weekdayOf1stYearday-1))
                    masks.weekdayOf1stYearday = weekdayOf1stYearday
                    masks.yeardayToWeekday = yeardayToWeekday
                    if byweekno.count > 0 {
                        buildWeeknoMask(year, month: month, day: day)
                    }
                }
                // everytime month or year changes
                if byweekdaynth.count != 0 {
                    //TODO: deal with weekdaynth mask
                }
                masks.year = year
                masks.month = month
            }

            var dayset = getDaySet(year, month: month, day: day, masks: masks)
            var filterDayset = [Int]()

            // 2. filter the dayset by mask
            for yeardayFromZero in dayset {
                if bymonth.count != 0 && !bymonth.contains(masks.yeardayToMonth![yeardayFromZero]) {
                    continue
                }
                if byweekno.count != 0 && masks.yeardayIsInWeekno![yeardayFromZero] == nil {
                    continue
                }
                if byyearday.count != 0 {
                    if yeardayFromZero < masks.yearLength {
                        if !byyearday.contains(yeardayFromZero + 1) && !byyearday.contains(yeardayFromZero - masks.yearLength) {
                            continue
                        }
                    } else {
                        if !byyearday.contains(yeardayFromZero + 1 - masks.yearLength) && !byyearday.contains(yeardayFromZero - masks.yearLength - masks.nextYearLength) {
                            continue
                        }
                    }
                }
                if (bymonthday.count != 0 || bymonthdayNegative.count != 0) && !bymonthday.contains(masks.yeardayToMonthday![yeardayFromZero]) && !bymonthdayNegative.contains(masks.yeardayToMonthdayNegtive![yeardayFromZero]) {
                    continue
                }
                if byweekday.count != 0 && !byweekday.contains(masks.yeardayToWeekday![yeardayFromZero]) {
                    continue
                }
                if byweekdaynth.count != 0 && masks.yeardayIsNthWeekday![yeardayFromZero] == nil {
                    continue
                }
                let yearday = yeardayFromZero + 1
                filterDayset.append(yearday)
            }

            dayset = filterDayset

            // setup BYSETPOS
            if bysetpos.count > 0 {
                for i in 0..<bysetpos.count {
                    if bysetpos[i] < 0 {
                        bysetpos[i] = dayset.count + 1 + bysetpos[i]
                    }
                }
            }

            // 3. filter the dayset by conditions

            for (index, yearday) in dayset.enumerate() {
                //yearday to month and day
                if bysetpos.count > 0 && !bysetpos.contains(index+1) {
                    continue
                }
                let occurrence = NSDate(year: year, month: 1, day: yearday, hour: hour, minute: minute, second: second)
                if self.dtstart > (occurrence + 1.seconds) {
                    continue
                }
                if occurrences.count >= self.count || (self.until != nil && occurrence > self.until) {
                    break
                }
                print("recurrence://\(occurrence + 0.hours)\n")
                occurrences.append(occurrence)
            }
            if occurrences.count >= self.count {
                break
            }

            // 4. prepare for the next interval

            var daysIncrement = 0
            switch frequency {
            case .Yearly:
                year = year + interval
            case .Monthly:
                month = month + interval
                if month > 12 {
                    year = year + month / 12
                    month = month % 12
                    if month == 0 {
                        month = 12
                        year = year - 1
                    }
                }
            case .Weekly:
                daysIncrement = 7 * interval
            case .Daily:
                daysIncrement = interval
            default:
                break
            }
            if daysIncrement > 0 {
                let newDate = NSDate(year: year, month: month, day: (day + daysIncrement))
                year = newDate.year
                month = newDate.month
                day = newDate.day
            }
        }
        return []
    }
    
    private func getDaySet(year: Int, month: Int, day: Int, masks: DateMask) -> [Int] {
        //This method returns an array of days of the year (numbered from 0 to 365) of the current timeframe (year, month, week, day) containing the current date.
        let date = NSDate(year: year, month: month, day: day)
        switch frequency {
        case .Yearly:
            let yearLen = masks.yearLength
            var returnArray = [Int]()
            for i in 0..<yearLen {
                returnArray.append(i)
            }
            return returnArray
        case .Monthly:
            let start = masks.lastdayOfMonth![month - 1]
            let end = masks.lastdayOfMonth![month]
            var returnArray = [Int]()
            for i in start..<end {
                returnArray.append(i)
            }
            return returnArray
        case .Weekly:
            var returnArray = [Int]()
            var i = NSCalendar.currentCalendar().ordinalityOfUnit(.Day, inUnit: .Year, forDate: date)
            for _ in 0..<7 {
                returnArray.append(i)
                i = i + 1
//                if ( masks.yeardayToWeekday![i] == wkst ) {
//                    break
//                }
            }
            return returnArray
        case .Daily:
            fallthrough
        case .Hourly:
            fallthrough
        case .Minutely:
            fallthrough
        case .Secondly:
            let i = NSCalendar.currentCalendar().ordinalityOfUnit(.Day, inUnit: .Year, forDate: date)
            return [i]
        }
    }
    
    func between(after after: NSDate, before: NSDate, inc:Bool = false) -> [NSDate] {

        return []
    }
    
    private func buildWeeknoMask(year: Int, month: Int, day: Int) {
        masks.yeardayIsInWeekno = [Int:Bool]()

        let firstWkst = (7 - masks.weekdayOf1stYearday + wkst) % 7
        var firstWkstOffset: Int
        var days: Int
        if firstWkst >= 4 {
            firstWkstOffset = 0
            days = masks.yearLength + masks.weekdayOf1stYearday - wkst
        } else {
            firstWkstOffset = firstWkst
            days = masks.yearLength - firstWkst
        }
        let weeks = days / 7 + (days % 7) / 4

        for weekno in byweekno {
            var n = weekno
            if n < 0 {
                n = n + weeks + 1
            }
            if n <= 0 || n > weeks {
                continue
            }
            var i = 0
            if n > 1 {
                i = firstWkstOffset + (n - 1) * 7
                if firstWkstOffset != firstWkst {
                    i = i - (7 - firstWkst)
                }
            } else {
                i = firstWkstOffset
            }

            for _ in 0..<7 {
                masks.yeardayIsInWeekno![i] = true
                i = i + 1
                if masks.yeardayToWeekday![i] == wkst {
                    break
                }
            }
        }

        if byweekno.contains(1) {

            // TODO: Check -numweeks for next year.

            var i = firstWkstOffset + weeks * 7
            if firstWkstOffset != firstWkst {
                i = i - (7 - firstWkst)
            }
            if i < masks.yearLength {
                for _ in 0..<7 {
                    masks.yeardayIsInWeekno![i] = true
                    i = i + 1
                    if masks.yeardayToWeekday![i] == wkst {
                        break
                    }
                }
            }
        }

        var weeksLastYear = -1
        if !byweekno.contains(-1) {
            let weekdayOf1stYearday = NSDate(year: year-1, month: 1, day: 1).weekday
            var firstWkstOffsetLastYear = (7 - weekdayOf1stYearday + wkst) % 7
            let lastYearLen = isLeapYear(year-1) ? 366 : 365
            if firstWkstOffsetLastYear >= 4 {
                firstWkstOffsetLastYear = 0
                weeksLastYear = 52 + ((lastYearLen + (weekdayOf1stYearday - wkst) % 7) % 7) / 4
            } else {
                weeksLastYear = 52 + ((masks.yearLength - firstWkstOffset) % 7) / 4
            }
        }
        if byweekno.contains(weeksLastYear) {
            for i in 0..<firstWkstOffset {
                masks.yeardayIsInWeekno![i] = true
            }
        }
    }
    
    private let M366MASK = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                            2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
                            3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
                            4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
                            5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
                            6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
                            7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
                            8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
                            9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
                            10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,
                            11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,
                            12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,
                            1,1,1,1,1,1,1] //7 days longer
    
    private let M365MASK = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                            2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
                            3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
                            4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
                            5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
                            6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
                            7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
                            8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
                            9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
                            10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,
                            11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,
                            12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,
                            1,1,1,1,1,1,1]
    
    private let MDAY366MASK = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7]
    
    private let MDAY365MASK = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,
                               1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
                               1,2,3,4,5,6,7]
    
    private let NMDAY366MASK = [-31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25]
    
    private let NMDAY365MASK = [-31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
                                -31,-30,-29,-28,-27,-26,-25]
    
    private let WDAYMASK = [1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,
                            1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,
                            1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,
                            1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,
                            1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,
                            1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,
                            1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,
                            1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,
                            1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,
                            1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,
                            1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7] //55 weeks
    
    private let M366RANGE = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366]
    
    private let M365RANGE = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
    
    private let MaxRepeatCycle: [RecurrenceFrequency:Int] = [.Yearly: 100,
                                                       .Monthly: 1200,
                                                       .Weekly: 5200,
                                                       .Daily: 36500,
                                                       .Hourly: 24,
                                                       .Minutely: 1440,
                                                       .Secondly: 86400]
    
    private func isLeapYear(year:Int) -> Bool {
        if ( year % 4 == 0 ) {
            return true
        }
        if ( year % 100 == 0 ) {
            return false
        }
        if ( year % 400 == 0 ) {
            return true
        }
        return false
    }
}
