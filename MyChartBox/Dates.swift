//
//  Dates.swift
//  MyChartBox
//
//  Created by Paul Willmott on 12/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation

public func jdFromDate(date : Date) -> Double {
    let JD_JAN_1_1970_0000GMT = 2440587.5
    return JD_JAN_1_1970_0000GMT + date.timeIntervalSince1970 / 86400
}

public func dateFromJd(jd : Double) -> Date {
    let JD_JAN_1_1970_0000GMT = 2440587.5
    return  Date(timeIntervalSince1970: (jd - JD_JAN_1_1970_0000GMT) * 86400)
}

public func weekFromDate(chartId:Int, date: Date) -> Int {
  if chartId == 1 {
    let JD_NOV_18_1952 = 2434334.5
    return 1 + Int(jdFromDate(date: date) - JD_NOV_18_1952) / 7
  }
  let JD_JUL_24_1956 = 2435678.5
  return 1 + Int(jdFromDate(date: date) - JD_JUL_24_1956) / 7
}

public func dateFromWeek(chartId:Int, week: Int) -> Date {
  if chartId == 1 {
    let JD_NOV_18_1952 = 2434334.5
    let jd = Double((week - 1) * 7) + JD_NOV_18_1952
    return dateFromJd(jd: jd)
  }
  let JD_JUL_24_1956 = 2435678.5
  let jd = Double((week) * 7) + JD_JUL_24_1956
  return dateFromJd(jd: jd)
}

public enum DayOfWeek : Int {
  case Sunday = 1
  case Monday = 2
  case Tuesday = 3
  case Wednesday = 4
  case Thursday = 5
  case Friday = 6
  case Saturday = 7
}

public func chartDate(chartId:Int, week: Int) -> Date {

  if chartId == 1 {

    let node : [(String, DayOfWeek)] = [
      ("1952-11-14T00:00:00Z", DayOfWeek.Friday),
      ("1960-03-10T00:00:00Z", DayOfWeek.Thursday),
      ("1967-07-05T00:00:00Z", DayOfWeek.Wednesday),
      ("1969-08-03T00:00:00Z", DayOfWeek.Sunday),
      ("2015-07-10T00:00:00Z", DayOfWeek.Friday),
    ]
    
    let td = dateFromWeek(chartId:chartId, week: week)
    
    let dateFormatter = ISO8601DateFormatter()
    var dayOfWeek : DayOfWeek = DayOfWeek.Friday
    for n in node {
      let nd = dateFormatter.date(from:n.0)!
      if (nd > td) {
        break
      }
      dayOfWeek = n.1
    }
    let jd = jdFromDate(date: td) - Double(7 + DayOfWeek.Tuesday.rawValue - dayOfWeek.rawValue)
    return dateFromJd(jd: jd)

  }
  else {

    let node : [(String, DayOfWeek)] = [
      ("1956-07-22T00:00:00Z", DayOfWeek.Sunday),
      ("2015-07-10T00:00:00Z", DayOfWeek.Friday),
    ]
    
    let td = dateFromWeek(chartId:chartId, week: week)
    
    let dateFormatter = ISO8601DateFormatter()
    var dayOfWeek : DayOfWeek = DayOfWeek.Friday
    for n in node {
      let nd = dateFormatter.date(from:n.0)!
      if (nd > td) {
        break
      }
      dayOfWeek = n.1
    }
    let jd = jdFromDate(date: td) - Double(7 + DayOfWeek.Tuesday.rawValue - dayOfWeek.rawValue)
    return dateFromJd(jd: jd)

  }
}

public func entryCount(chartId:Int, date:Date) -> Int {
  
  let conn = Database.getConnection()

  let shouldClose = conn.state != .Open
  if shouldClose {
    if conn.open() != .Open {
      return 0
    }
  }
  
  var count : Int = 0
  
  let cmd = conn.createCommand()
    
  cmd.commandText = "SELECT COUNT([\(CHART_ENTRY.CHART_ENTRY_ID)]) AS NUM FROM [\(TABLE.CHART_ENTRY)] WHERE [\(CHART_ENTRY.CHART_DATE)] = @\(CHART_ENTRY.CHART_DATE)  AND [\(CHART_ENTRY.CHART_ID)] = @\(CHART_ENTRY.CHART_ID)"
  
  cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.CHART_DATE)", value: date)
  cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.CHART_ID)", value: chartId)

  if let reader = cmd.executeReader() {
    
    if reader.read() {
      if let num = reader.getInt(index: 0) {
        count = num
      }
    }
    
    reader.close()
    
  }
  
  if shouldClose {
    conn.close()
  }
  
  return count

}

public func doneCount(chartId:Int) -> Int {
  
  let conn = Database.getConnection()

  let shouldClose = conn.state != .Open
  if shouldClose {
    if conn.open() != .Open {
      return 0
    }
  }
  
  var count : Int = 0
  
  let cmd = conn.createCommand()
    
  cmd.commandText = "SELECT COUNT([\(CHART_ENTRY.CHART_DATE)]) AS NUM FROM [\(TABLE.CHART_ENTRY)] WHERE [\(CHART_ENTRY.CHART_ID)] = @\(CHART_ENTRY.CHART_ID) GROUP BY [\(CHART_ENTRY.CHART_DATE)] ORDER BY [\(CHART_ENTRY.CHART_DATE)]"

  cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.CHART_ID)", value: chartId)

  if let reader = cmd.executeReader() {
    
    while reader.read() {
      if reader.getInt(index: 0) != nil {
        count += 1
      }
    }
    
    reader.close()
    
  }
  
  if shouldClose {
    conn.close()
  }
  
  return count

}

public func timeString(milliseconds:Int) -> String {
  let rawHours = Double(milliseconds / 1000) / (60.0 * 60.0)
  let intHours = Int(rawHours)
  let rawMinutes = (rawHours - Double(intHours)) * 60.0
  let intMinutes = Int(rawMinutes)
  let rawSeconds = (rawMinutes - Double(intMinutes)) * 60.0
  let intSeconds = Int(rawSeconds)
  if intHours == 0 {
    return String(format: "%d:%02d", intMinutes, intSeconds)
  }
  return String(format: "%d:%02d:%02d", intHours, intMinutes, intSeconds)
}


