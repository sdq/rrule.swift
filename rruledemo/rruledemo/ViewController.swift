//
//  ViewController.swift
//  rruledemo
//
//  Created by sdq on 7/20/16.
//  Copyright © 2016 sdq. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var frequency: NSPopUpButton!
    @IBOutlet weak var dtstart: NSDatePicker!
    @IBOutlet weak var until: NSDatePicker!
    @IBOutlet weak var count: NSTextField!
    @IBOutlet weak var interval: NSTextField!
    @IBOutlet weak var wkst: NSPopUpButton!
    @IBOutlet weak var monday: NSButton!
    @IBOutlet weak var tuesday: NSButton!
    @IBOutlet weak var wednesday: NSButton!
    @IBOutlet weak var thursday: NSButton!
    @IBOutlet weak var friday: NSButton!
    @IBOutlet weak var saturday: NSButton!
    @IBOutlet weak var sunday: NSButton!
    @IBOutlet weak var byweekno: NSTextField!
    @IBOutlet weak var Jan: NSButton!
    @IBOutlet weak var Feb: NSButton!
    @IBOutlet weak var Mar: NSButton!
    @IBOutlet weak var Apr: NSButton!
    @IBOutlet weak var May: NSButton!
    @IBOutlet weak var Jun: NSButton!
    @IBOutlet weak var Jul: NSButton!
    @IBOutlet weak var Aug: NSButton!
    @IBOutlet weak var Sep: NSButton!
    @IBOutlet weak var Oct: NSButton!
    @IBOutlet weak var Nov: NSButton!
    @IBOutlet weak var Dec: NSButton!
    @IBOutlet weak var bymonthday: NSTextField!
    @IBOutlet weak var byyearday: NSTextField!
    @IBOutlet weak var bysetpos: NSTextField!

    @IBOutlet weak var tableview: NSTableView!
    var occurenceArray: [NSDate] = []
    
    let frequencyArray = ["Yearly", "Monthly", "Weekly", "Daily"]
    let weekdayArray = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.setDataSource(self)
        tableview.setDelegate(self)
        frequency.removeAllItems()
        frequency.addItemsWithTitles(frequencyArray)
        wkst.removeAllItems()
        wkst.addItemsWithTitles(weekdayArray)
        frequency.indexOfSelectedItem
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

extension ViewController {

    @IBAction func convert(sender: NSButton) {
        //frequency
        var rrulefrequency: RruleFrequency = .Yearly
        switch frequency.indexOfSelectedItem {
        case 0:
            rrulefrequency = .Yearly
        case 1:
            rrulefrequency = .Monthly
        case 2:
            rrulefrequency = .Weekly
        case 3:
            rrulefrequency = .Daily
        default:
            rrulefrequency = .Yearly
        }
        
        //dtstart
        let rruledtstart = dtstart.dateValue
        
        //until
        let rruleuntil = until.dateValue
        
        //count
        var rrulecount: Int?
        if count.integerValue != 0 {
            rrulecount = count.integerValue
        }
        
        //interval
        var rruleinterval: Int = 1
        if interval.integerValue != 0 {
            rruleinterval = interval.integerValue
        }
        
        //wkst
        let rrulewkst = wkst.indexOfSelectedItem
        
        //byweekday
        var rrulebyweekday: [Int] = []
        if sunday.state == 1 {
            rrulebyweekday.append(1)
        }
        if monday.state == 1 {
            rrulebyweekday.append(2)
        }
        if tuesday.state == 1 {
            rrulebyweekday.append(3)
        }
        if wednesday.state == 1 {
            rrulebyweekday.append(4)
        }
        if thursday.state == 1 {
            rrulebyweekday.append(5)
        }
        if friday.state == 1 {
            rrulebyweekday.append(6)
        }
        if saturday.state == 1 {
            rrulebyweekday.append(7)
        }
        
        //byweekno
        var rrulebyweekno: [Int] = []
        let byweeknostring = byweekno.stringValue
        let stringArray = byweeknostring.componentsSeparatedByString(",")
        for x in stringArray {
            if let y = Int(x) {
                rrulebyweekno.append(y)
            }
        }
        
        //bymonth
        var rrulebymonth: [Int] = []
        if Jan.state == 1 {
            rrulebymonth.append(1)
        }
        if Feb.state == 1 {
            rrulebymonth.append(2)
        }
        if Mar.state == 1 {
            rrulebymonth.append(3)
        }
        if Apr.state == 1 {
            rrulebymonth.append(4)
        }
        if May.state == 1 {
            rrulebymonth.append(5)
        }
        if Jun.state == 1 {
            rrulebymonth.append(6)
        }
        if Jul.state == 1 {
            rrulebymonth.append(7)
        }
        if Aug.state == 1 {
            rrulebymonth.append(8)
        }
        if Sep.state == 1 {
            rrulebymonth.append(9)
        }
        if Oct.state == 1 {
            rrulebymonth.append(10)
        }
        if Nov.state == 1 {
            rrulebymonth.append(11)
        }
        if Dec.state == 1 {
            rrulebymonth.append(12)
        }
        
        //bymonthday
        var rrulebymonthday: [Int] = []
        let bymonthdaystring = bymonthday.stringValue
        let monthdayArray = bymonthdaystring.componentsSeparatedByString(",")
        for x in monthdayArray {
            if let y = Int(x) {
                rrulebymonthday.append(y)
            }
        }
        
        //byyearday
        var rrulebyyearday: [Int] = []
        let byyeardaystring = byyearday.stringValue
        let byyeardayArray = byyeardaystring.componentsSeparatedByString(",")
        for x in byyeardayArray {
            if let y = Int(x) {
                rrulebyyearday.append(y)
            }
        }
        
        //bysetpos
        var rrulebysetpos: [Int] = []
        let bysetposstring = bysetpos.stringValue
        let bysetposArray = bysetposstring.componentsSeparatedByString(",")
        for x in bysetposArray {
            if let y = Int(x) {
                rrulebysetpos.append(y)
            }
        }
        
        let rule = rrule(frequency: rrulefrequency, dtstart: rruledtstart, until: rruleuntil, count: rrulecount, interval: rruleinterval, wkst: rrulewkst, bysetpos: rrulebysetpos, bymonth: rrulebymonth, bymonthday: rrulebymonthday, byyearday: rrulebyyearday, byweekno: rrulebyweekno, byweekday: rrulebyweekday, byhour: [], byminute: [], bysecond: [])
        
        occurenceArray = rule.getOccurrences()
        tableview.reloadData()
    }
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return occurenceArray.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cellView: NSTableCellView = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as! NSTableCellView
        let item = occurenceArray[row]
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
        formatter.timeZone = NSTimeZone()
        let date = formatter.stringFromDate(item)
        cellView.textField!.stringValue = date
        return cellView
    }
}

