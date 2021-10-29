//
//  Programme.swift
//  MyChartBox
//
//  Created by Paul Willmott on 25/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation

public class Programme : NSObject {
  
  public var chartEntries = [ChartEntry]()
  
  public var dateOfChart : Date
  
  private var programmeMode : ProgrammeMode = .All
  
  public var dateString : String {
    get {
      
      var calendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
      calendar.timeZone = TimeZone(abbreviation: "UTC")!
      
      let df = DateFormatter()
      df.calendar = calendar
      df.timeZone = TimeZone(abbreviation: "UTC")!

      return
        "\(calendar.component(Calendar.Component.day, from: dateOfChart))  \(df.monthSymbols[calendar.component(Calendar.Component.month, from: dateOfChart)-1]) \(calendar.component(Calendar.Component.year, from: dateOfChart))"
    }
  }
  
  // Total running time of tracks in milliseconds of completed tracks
  public func runningTime(nowPlayingIndex:Int) -> Int {
    
    var time : Int = 0

    var index = chartEntries.count - 1
    
    while index > nowPlayingIndex {
      let entry = chartEntries[index]
      if let track = entry.bestTrack {
        time += track.mediaItem.totalTime
      }
      index -= 1
    }
    
    return time
  }
  

  public var isDecember : Bool {
    get {
      
      var calendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
      
      calendar.timeZone = TimeZone(abbreviation: "UTC")!
      
      let month = calendar.component(Calendar.Component.month, from: Date())
      
      return month == 12
      
    }
  }

  public var chartDates : String {
    get {
      
      var calendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
      calendar.timeZone = TimeZone(abbreviation: "UTC")!
      
      let df = DateFormatter()
      df.calendar = calendar
      df.dateStyle = .medium
      df.timeStyle = .none
      df.timeZone = TimeZone(abbreviation: "UTC")!

      return ("\(df.string(from: dateOfChart)) - \(df.string(from: dateOfChart.addingTimeInterval(86400 * 6)))").uppercased()
    }
  }

  init(isSinglesMode:Bool, date:Date, minPosition:Int) {
    
    let chartId = isSinglesMode ? 1 : 2
    
    let y = date.timeIntervalSince1970 / 86400
    
    let dx = Date(timeIntervalSince1970: y * 86400)
    
    var week = weekFromDate(chartId:chartId, date: dx)

    dateOfChart = chartDate(chartId:chartId, week: week )

    while dx.timeIntervalSince1970 > dateOfChart.timeIntervalSince1970 + 86400 * 7 {
      week += 1
      dateOfChart = chartDate(chartId:chartId, week: week )
    }
    
    super.init()
    
    // Download chart if not already cached. Charts are cached to avoid
    // unnecessary downloads, and to allow offline operation.
    
    if entryCount(chartId:chartId, date: dateOfChart) == 0 {
      getChart(chartId: chartId, date: dateOfChart)
    }

    if entryCount(chartId:chartId, date: dateOfChart) == 0 {
      print("no chart found")
      return
    }

    let conn = Database.getConnection()
     
    let shouldClose = conn.state != .Open
      
    if shouldClose {
      _ = conn.open()
    }
      
    let cmd = conn.createCommand()
    
    let minimumPosition = minPosition < 0 ? 100 : minPosition
    
    if minPosition == -1 {
      programmeMode = .MaxRuntime
    }
    else if minPosition == -2 {
      programmeMode = .TargetTime
    }
    else {
      programmeMode = .All
    }
    
    cmd.commandText =
      "SELECT " + ChartEntry.ColumnNames + " " +
      "FROM [\(TABLE.CHART_ENTRY)] " +
      "WHERE [\(CHART_ENTRY.CHART_DATE)] = @\(CHART_ENTRY.CHART_DATE) AND " +
      "[\(CHART_ENTRY.CHART_ID)] = @\(CHART_ENTRY.CHART_ID) AND " +
      "CAST([\(CHART_ENTRY.POSITION)] AS INTEGER) <= \(minimumPosition) " +
      "ORDER BY CAST(\(CHART_ENTRY.POSITION) AS INTEGER)"

    cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.CHART_DATE)", value: dateOfChart)
    cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.CHART_ID)", value: chartId)

    if let reader = cmd.executeReader() {
      
      if isSinglesMode {
        while reader.read() {
         let masterEntry = ChartEntry(reader:reader)
         var index = 0
         for _ in masterEntry.chartListing.sides {
           let entry = ChartEntry(reader:reader)
           entry.Index = index
           chartEntries.append(entry)
           index += 1
         }
        }
      }
      else {
        while reader.read() {
          let masterEntry = ChartEntry(reader:reader)
          chartEntries.append(masterEntry)
        }
      }
      reader.close()
          
    }
     
    if shouldClose {
      conn.close()
    }

  }
  
}

public enum ProgrammeMode {
  case All
  case MaxRuntime
  case TargetTime
}
