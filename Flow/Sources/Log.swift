//
//  Log.swift
//  Flow
//
//  Created by Piers Mainwaring on 1/27/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

struct Log {
    static let lock = dispatch_queue_create("com.playfair.logger-lock", DISPATCH_QUEUE_SERIAL)
    static var num: Int = 0

    static func event(fd: Int32, uuid: NSUUID, eventName: String) {
        event(fd, uuid: uuid, eventName: eventName, oldValue: "", newValue: "")
    }

    static func event(fd: Int32, uuid: NSUUID, eventName: String, oldValue: AnyObject, newValue: AnyObject) {
        dispatch_async(lock) {
            print(num, fd, uuid.UUIDString, eventName, oldValue, newValue, separator: ",", terminator: "\n")
            num += 1
        }
    }
}

class ISO8601DateFormatter: NSDateFormatter {
    override private init() {
        super.init()
        self.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        self.timeZone = NSTimeZone.defaultTimeZone()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func dateFromString(string: String) -> NSDate? {
        guard let date = super.dateFromString(string) else { return nil }

        let substringIndex = string.characters.startIndex.advancedBy(max(string.characters.count, 0))

        guard let microseconds = Int(string.substringToIndex(substringIndex)) else { return nil }

        let msec = Double(microseconds) / Double(USEC_PER_SEC)
        return date.dateByAddingTimeInterval(msec)
    }

    override func stringFromDate(date: NSDate) -> String {
        let originalDateString = super.stringFromDate(date)
        let originalParsedDate = super.dateFromString(originalDateString)!
        let originalDateWasRoundedUp = originalParsedDate.compare(date) == .OrderedAscending

        let adjustedDate = originalParsedDate.dateByAddingTimeInterval(originalDateWasRoundedUp ? -0.001 : 0)
        let adjustedDateString = super.stringFromDate(adjustedDate).substringToIndex(originalDateString.characters.endIndex.advancedBy(-3))

        let cal = NSCalendar.currentCalendar()
        let secondsDelta = cal.component(.Second, fromDate: adjustedDate) - cal.component(.Second, fromDate: date)

        let timeInterval = Int(secondsDelta) * Int(USEC_PER_SEC)

        return NSString(format: "%@%d", adjustedDateString, timeInterval) as String
    }
}