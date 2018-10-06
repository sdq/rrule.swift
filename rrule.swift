//
//  RRuleSwift.swift
//  RecurrenceTest
//
//  Created by sdq on 7/18/16.
//  Copyright © 2016 sdq. All rights reserved.
//

import Foundation
import EventKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


// swiftlint:disable file_length
// swiftlint:disable variable_name
// swiftlint:disable type_name
// swiftlint:disable type_body_length
// swiftlint:disable comma
// swiftlint:disable todo

public enum RruleFrequency {
    case yearly
    case monthly
    case weekly
    case daily
    case hourly //Todo
    case minutely //Todo
    case secondly //Todo
}

private struct DateMask {
    var year: Int = 0
    var month: Int = 0
    var leapYear: Bool = false
    var nextYearLength: Int = 0
    var lastdayOfMonth: [Int] = []
    var weekdayOf1stYearday: Int = 0
    var yeardayToWeekday: [Int] = []
    var yeardayToMonth: [Int] = []
    var yeardayToMonthday: [Int] = []
    var yeardayToMonthdayNegtive: [Int] = []
    var yearLength: Int = 0
    var yeardayIsNthWeekday: [Int:Bool] = [:]
    var yeardayIsInWeekno: [Int:Bool] = [:]
}

class rrule {

    var frequency: RruleFrequency
    var interval = 1
    var wkst: Int = 1
    var dtstart = Date()
    var until: Date?
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
    var exclusionDates = [Date]()
    var inclusionDates = [Date]()

    fileprivate let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    fileprivate var dateComponent = DateComponents()
    fileprivate var year: Int = 0
    fileprivate var month: Int = 0
    fileprivate var day: Int = 0
    fileprivate var hour: Int = 0
    fileprivate var minute: Int = 0
    fileprivate var second: Int = 0
    fileprivate var dayset: [Int]?
    fileprivate var total: Int?
    fileprivate var masks = DateMask()

    init(frequency: RruleFrequency, dtstart: Date? = nil, until: Date? = nil, count: Int? = nil, interval: Int = 1, wkst: Int = 1, bysetpos: [Int] = [], bymonth: [Int] = [], bymonthday: [Int] = [], byyearday: [Int] = [], byweekno: [Int] = [], byweekday: [Int] = [], byhour: [Int] = [], byminute: [Int] = [], bysecond: [Int] = [], exclusionDates: [Date] = [], inclusionDates: [Date] = []) {
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
        self.inclusionDates = inclusionDates
        self.exclusionDates = exclusionDates

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
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: dtstart!)
            switch frequency {
            case .yearly:
                if bymonth.count == 0 {
                    if let month = components.month {
                        self.bymonth = [month]
                    }
                }
                if let day = components.day {
                    self.bymonthday = [day]
                }
            case .monthly:
                if let day = components.day {
                    self.bymonthday = [day]
                }
            case .weekly:
                if let weekday = components.weekday {
                    self.byweekday = [weekday]
                }
            default:
                break
            }
        }
    }

    func getOccurrences() -> [Date] {
        return getOccurrencesBetween()
    }

    // swiftlint:disable function_body_length
    func getOccurrencesBetween(beginDate: Date? = nil, endDate: Date? = nil) -> [Date] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: dtstart)
        year = components.year!
        month = components.month!
        day = components.day!
        hour = components.hour!
        minute = components.minute!
        second = components.second!
        var beginDateYear = 0
        var beginDateYearday = 0
        if let beginDate = beginDate {
            let (beginYear, beginMonth, beginDay) = getYearMonthDay(beginDate)
            beginDateYear = beginYear
            beginDateYearday = getYearday(year: beginYear, month: beginMonth, day: beginDay)
        }
        var endDateYear = 0
        var endDateYearday = 0
        if let endDate = endDate {
            let (endYear, endMonth, endDay) = getYearMonthDay(endDate)
            endDateYear = endYear
            endDateYearday = getYearday(year: endYear, month: endMonth, day: endDay)
        }
        var endFlag = false

        guard let max = MaxRepeatCycle[frequency] else {
            return []
        }

        var occurrences = [Date]()

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
                    var dateComponents = DateComponents()
                    dateComponents.year = year
                    dateComponents.month = 1
                    dateComponents.day = 1
                    let date = Calendar.current.date(from: dateComponents)!
                    let weekdayOf1stYearday = Calendar.current.component(.weekday, from: date)
                    let yeardayToWeekday = Array(WDAYMASK.suffix(from: weekdayOf1stYearday-1))
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

            let dayset = getDaySet(year, month: month, day: day, masks: masks)

            // 2. filter the dayset by mask
            var filterDayset = [Int]()
            for yeardayFromZero in dayset {
                if bymonth.count != 0 && !bymonth.contains(masks.yeardayToMonth[yeardayFromZero]) {
                    continue
                }
                if byweekno.count != 0 && masks.yeardayIsInWeekno[yeardayFromZero] == nil {
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
                if (bymonthday.count != 0 || bymonthdayNegative.count != 0) && !bymonthday.contains(masks.yeardayToMonthday[yeardayFromZero]) && !bymonthdayNegative.contains(masks.yeardayToMonthdayNegtive[yeardayFromZero]) {
                    continue
                }
                if byweekday.count != 0 && !byweekday.contains(masks.yeardayToWeekday[yeardayFromZero]) {
                    continue
                }
                if byweekdaynth.count != 0 && masks.yeardayIsNthWeekday[yeardayFromZero] == nil {
                    continue
                }
                let yearday = yeardayFromZero + 1
                filterDayset.append(yearday)
            }

            // setup BYSETPOS
            if bysetpos.count > 0 {
                for i in 0..<bysetpos.count {
                    if bysetpos[i] < 0 {
                        bysetpos[i] = filterDayset.count + 1 + bysetpos[i]
                    }
                }
            }

            // 3. filter the dayset by conditions
            for index in 0..<filterDayset.count {
                //yearday to month and day

                let yearday = filterDayset[index]
                if bysetpos.count > 0 && !bysetpos.contains(index+1) {
                    continue
                }

                if let _ = beginDate {
                    if beginDateYear > year || (beginDateYear == year && beginDateYearday > yearday) {
                        continue
                    }
//                    if beginDate.timeIntervalSinceDate(occurrence) > 0 {
//                        continue
//                    }
                }
                if let _ = endDate {
                    if endDateYear < year || (endDateYear == year && endDateYearday < yearday) {
                        continue
                    }
//                    if endDate.timeIntervalSinceDate(occurrence) < 0 {
//                        continue
//                    }
                }
                let occurrence = getDate(year: year, month: 1, day: yearday, hour: hour, minute: minute, second: second)
                if (self.count != nil && occurrences.count >= self.count!) || (self.until != nil && occurrence > self.until!) {
                    endFlag = true
                    break
                }
                occurrences.append(occurrence)
            }
            if endFlag {
                break
            }

            // 4. prepare for the next interval

            var daysIncrement = 0
            switch frequency {
            case .yearly:
                year = year + interval
            case .monthly:
                month = month + interval
                if month > 12 {
                    year = year + month / 12
                    month = month % 12
                    if month == 0 {
                        month = 12
                        year = year - 1
                    }
                }
            case .weekly:
                if dayset.count < 7 {
                    daysIncrement = 7 * (interval - 1) + dayset.count
                } else {
                    daysIncrement = 7 * interval
                }
            case .daily:
                daysIncrement = interval
            default:
                break
            }

            if daysIncrement > 0 {
                let yearday = getYearday(year: year, month: month, day: day)
                let newYearday = yearday + daysIncrement
                if newYearday > masks.yearLength {
                    let newDate = getDate(year: year, month: month, day: (day + daysIncrement), hour: hour, minute: minute, second: second)
                    (year, month, day) = getYearMonthDay(newDate)
                } else {
                    if masks.leapYear {
                        month = M366MASK[newYearday - 1]
                        day = newYearday - M366RANGE[month - 1]
                    } else {
                        month = M365MASK[newYearday - 1]
                        day = newYearday - M365RANGE[month - 1]
                    }
                }
            }
        }
        
        //include dates
        for rdate in inclusionDates {
            if let beginDate = beginDate {
                if beginDate.timeIntervalSince(rdate) > 0 {
                    continue
                }
            }
            if let endDate = endDate {
                if endDate.timeIntervalSince(rdate) < 0 {
                    continue
                }
            }
            occurrences.append(rdate)
        }
        
        //exclude dates
        for exdate in exclusionDates {
            for occurrence in occurrences {
                if occurrence.timeIntervalSince(exdate) == 0 {
                    let index = occurrences.index(of: occurrence)!
                    occurrences.remove(at: index)
                }
            }
        }
        
        return occurrences
    }

    fileprivate func getDaySet(_ year: Int, month: Int, day: Int, masks: DateMask) -> [Int] {
        //let date = getDate(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
        switch frequency {
        case .yearly:
            let yearLen = masks.yearLength
            var returnArray = [Int]()
            for i in 0..<yearLen {
                returnArray.append(i)
            }
            return returnArray
        case .monthly:
            let start = masks.lastdayOfMonth[month - 1]
            let end = masks.lastdayOfMonth[month]
            var returnArray = [Int]()
            for i in start..<end {
                returnArray.append(i)
            }
            return returnArray
        case .weekly:
            var returnArray = [Int]()
            var i = getYearday(year: year, month: month, day: day) - 1 //from zero
            for _ in 0..<7 {
                returnArray.append(i)
                i = i + 1
                if masks.yeardayToWeekday[i] == wkst {
                    break
                }
            }
            return returnArray
        case .daily:
            fallthrough
        case .hourly:
            fallthrough
        case .minutely:
            fallthrough
        case .secondly:
            let i = getYearday(year: year, month: month, day: day) - 1
            return [i]
        }
    }

    fileprivate func buildWeeknoMask(_ year: Int, month: Int, day: Int) {
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
                masks.yeardayIsInWeekno[i] = true
                i = i + 1
                if masks.yeardayToWeekday[i] == wkst {
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
                    masks.yeardayIsInWeekno[i] = true
                    i = i + 1
                    if masks.yeardayToWeekday[i] == wkst {
                        break
                    }
                }
            }
        }

        var weeksLastYear = -1
        if !byweekno.contains(-1) {
            var dateComponents = DateComponents()
            dateComponents.year = year-1
            dateComponents.month = 1
            dateComponents.day = 1
            let date = Calendar.current.date(from: dateComponents)!
            let weekdayOf1stYearday = Calendar.current.component(.weekday, from: date)
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
                masks.yeardayIsInWeekno[i] = true
            }
        }
    }

    fileprivate let M366MASK = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
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

    fileprivate let M365MASK = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
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

    fileprivate let MDAY366MASK = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
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

    fileprivate let MDAY365MASK = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,
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

    fileprivate let NMDAY366MASK = [-31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
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

    fileprivate let NMDAY365MASK = [-31,-30,-29,-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,
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

    fileprivate let WDAYMASK = [1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,
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

    fileprivate let M366RANGE = [0,31,60,91,121,152,182,213,244,274,305,335,366]

    fileprivate let M365RANGE = [0,31,59,90,120,151,181,212,243,273,304,334,365]

    fileprivate let MaxRepeatCycle: [RruleFrequency:Int] = [.yearly:10,
                                                       .monthly:120,
                                                       .weekly:520,
                                                       .daily:3650,
                                                       .hourly:24,
                                                       .minutely:1440,
                                                       .secondly:86400]

    fileprivate func isLeapYear(_ year: Int) -> Bool {
        if year % 4 == 0 {
            return true
        }
        if year % 100 == 0 {
            return false
        }
        if year % 400 == 0 {
            return true
        }
        return false
    }

    fileprivate func getDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> Date {
        dateComponent.year = year
        dateComponent.month = month
        dateComponent.day = day
        dateComponent.hour = hour
        dateComponent.minute = minute
        dateComponent.second = second
        return (calendar.date(from: dateComponent))!
    }
    
    fileprivate func getYearday(year:Int, month: Int, day: Int) -> Int {
        if isLeapYear(year) {
            return M366RANGE[month - 1] + day
        } else {
            return M365RANGE[month - 1] + day
        }
    }

    fileprivate func getYearMonthDay(_ date: Date) -> (Int, Int, Int) {
        let dateComponent = (calendar as NSCalendar?)?.components([.year, .month, .day], from: date)
        return ((dateComponent?.year)!, (dateComponent?.month)!, (dateComponent?.day)!)
    }
    
    fileprivate func getWeekday(_ date: Date) -> Int {
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let dateComponent = (calendar as NSCalendar?)?.components(.weekday, from: date)
        return (dateComponent?.weekday)!
    }
}

extension EKEvent {
    
    private var dtStart: Date {
        return self.occurrenceDate
    }
    
    private func byweekday(rule: EKRecurrenceRule) -> [Int] {
        var days = [Int]()
        
        if let daysOTW = rule.daysOfTheWeek {
            if daysOTW.isEmpty {
                return [Calendar.current.component(.weekday, from: dtStart)]
            } else {
                for d in daysOTW {
                    days.append(d.dayOfTheWeek.rawValue)
                }
                return days
            }
        }
        return [Calendar.current.component(.weekday, from: dtStart)]
    }
    
    var rrules: [rrule] {
        var rs = [rrule]()
        
        if let rss = recurrenceRules {
            for rule in rss {
                let rr = rrule(frequency: rule.freq,
                               dtstart: occurrenceDate,
                               until: rule.until,
                               count: rule.count,
                               interval: rule.interval,
                               wkst: rule.wkst,
                               bysetpos: rule.bysetpos,
                               bymonth: rule.bymonth,
                               bymonthday: rule.bymonthday,
                               byyearday: rule.byyearday,
                               byweekno: rule.byweekno,
                               byweekday: byweekday(rule: rule),
                               byhour: [], byminute: [], bysecond: [], exclusionDates: [], inclusionDates: [])
                                
                rs.append(rr)
            }
        }
        return rs
    }
    
    
}

private extension EKRecurrenceRule {
    
    var freq: RruleFrequency {
        switch frequency {
        case .daily:
            return .daily
        case .monthly:
            return .monthly
        case .weekly:
            return .weekly
        default:
            return .daily
        }
    }
    
    var until: Date? {
        return recurrenceEnd?.endDate
    }
    
    var count: Int? {
        return nil
    }
    
    var wkst: Int {
        return firstDayOfTheWeek
    }
    
    var bysetpos: [Int] {
        if let pos = setPositions {
            return pos as! [Int]
        }
        return [Int]()
    }
    
    var bymonth: [Int] {
        if let month = monthsOfTheYear {
            return month as! [Int]
        }
        return [Int]()
    }
    
    var bymonthday: [Int] {
        if let month = daysOfTheMonth {
            return month as! [Int]
        }
        return [Int]()
    }
    
    var byyearday: [Int] {
        if let year = daysOfTheYear {
            return year as! [Int]
        }
        return [Int]()
    }
    
    var byweekno: [Int] {
        if let week = weeksOfTheYear {
            return week as! [Int]
        }
        return [Int]()
    }
    
}
