# rrule.swift
recurrence rules in **swift4**  (No other dependencies)

Demo
Download the App [here](https://github.com/sdq/rrule.swift/blob/master/app/rruledemo.app).
------
![demo](https://github.com/sdq/rrule.swift/blob/master/rruledemo.jpg)

How to use
------

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