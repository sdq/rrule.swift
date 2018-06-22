# rrule.swift
**rrule.swift** supports recurrence rules in Swift 4  (No other 3rd-party dependencies).

It is a partial port of the rrule module from the excellent [python-dateutil](http://labix.org/python-dateutil/) library.

Demo
------
![demo](https://github.com/sdq/rrule.swift/blob/master/rruledemo.jpg)

How to use
------
Drag **rrule.swift** into your project. 

	let rule = rule(frequency, dtstart: dtstart, until: until, count: count, interval: interval, wkst: wkst, bysetpos: bysetpos, bymonth: bymonth, bymonthday: bymonthday, byyearday: byyearday, byweekno: byweekno, byweekday: byweekday)
	let occurrences = rule.getOccurrences()

To do
------
* Hourly
* Minutely
* Secondly

Author
------
[sdq](http://shidanqing.net)


License
-------
[MIT](https://opensource.org/licenses/MIT)
