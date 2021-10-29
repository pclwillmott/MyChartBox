//
//  PlayCount.swift
//  MyChartBox
//
//  Created by Paul Willmott on 22/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation

class PlayCount : NSObject {
  
  public var year      : Int = 0
  public var playCount : Int = 0
  public var chartId   : Int
  
  init(year:Int, chartId:Int = 1) {
    
    self.chartId = chartId
    
    super.init()
    
    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
    
    var newRow = true
    
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT [\(PLAY_COUNT.YEAR_NUMBER)], [\(PLAY_COUNT.PLAY_COUNT)] FROM [\(TABLE.PLAY_COUNT)] WHERE [\(PLAY_COUNT.YEAR_NUMBER)] = @\(PLAY_COUNT.YEAR_NUMBER) AND [\(PLAY_COUNT.CHART_ID)] = @\(PLAY_COUNT.CHART_ID)"
    
    cmd.parameters.addWithValue(key: "@\(PLAY_COUNT.YEAR_NUMBER)", value: year)
    cmd.parameters.addWithValue(key: "@\(PLAY_COUNT.CHART_ID)", value: chartId)

    if let reader = cmd.executeReader() {
         
      if reader.read() {
        if !reader.isDBNull(index: 1) {
          self.playCount = reader.getInt(index: 1)!
          newRow = false
        }
      }
         
      reader.close()
         
    }
    
    if newRow {
      
      cmd.commandText = "INSERT INTO [\(TABLE.PLAY_COUNT)] (" +
        "[\(PLAY_COUNT.YEAR_NUMBER)], [\(PLAY_COUNT.PLAY_COUNT)], [\(PLAY_COUNT.CHART_ID)]" +
      ") VALUES (" +
        "@\(PLAY_COUNT.YEAR_NUMBER), @\(PLAY_COUNT.PLAY_COUNT), @\(PLAY_COUNT.CHART_ID)" +
      ")"
      
      cmd.parameters.addWithValue(key: "@\(PLAY_COUNT.YEAR_NUMBER)", value: year)
      cmd.parameters.addWithValue(key: "@\(PLAY_COUNT.PLAY_COUNT)", value: 0)
      cmd.parameters.addWithValue(key: "@\(PLAY_COUNT.CHART_ID)", value: chartId)

      let _ = cmd.executeNonQuery()
      
    }
    
    if shouldClose {
      conn.close()
    }
    
    self.year = year

  }
  
  public static func resetPlayCounts(chartId:Int = 1) {

    let commands = [
      "UPDATE [\(TABLE.PLAY_COUNT)] SET [\(PLAY_COUNT.PLAY_COUNT)] = 0 WHERE [\(PLAY_COUNT.CHART_ID)] = \(chartId)"
    ]
    
    Database.execute(commands: commands)
  }
  
  public func incrementPlayCount() {
    
    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
    
    let cmd = conn.createCommand()
     
    cmd.commandText = "UPDATE [\(TABLE.PLAY_COUNT)] SET " +
      "[\(PLAY_COUNT.PLAY_COUNT)] = @\(PLAY_COUNT.PLAY_COUNT) " +
      "WHERE [\(PLAY_COUNT.YEAR_NUMBER)] = @\(PLAY_COUNT.YEAR_NUMBER) AND " +
      "[\(PLAY_COUNT.CHART_ID)] = @\(PLAY_COUNT.CHART_ID)"
    
    self.playCount += 1
      
    cmd.parameters.addWithValue(key: "@\(PLAY_COUNT.YEAR_NUMBER)", value: self.year)
    cmd.parameters.addWithValue(key: "@\(PLAY_COUNT.PLAY_COUNT)", value: self.playCount)
    cmd.parameters.addWithValue(key: "@\(PLAY_COUNT.CHART_ID)", value: self.chartId)

    let _ = cmd.executeNonQuery()
      
    if shouldClose {
      conn.close()
    }

  }
  
  public static func minimumPlayCount(fromYear:Int, toYear:Int, chartId:Int = 1) -> Int {
    
    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
    
    var minValue = 0
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT MIN([\(PLAY_COUNT.PLAY_COUNT)]) AS MIN_PLAY_COUNT FROM [\(TABLE.PLAY_COUNT)] WHERE [\(PLAY_COUNT.YEAR_NUMBER)] >= @FROM_YEAR AND [\(PLAY_COUNT.YEAR_NUMBER)] <= @TO_YEAR AND [\(PLAY_COUNT.CHART_ID)] = @CHART_ID"
    
    cmd.parameters.addWithValue(key: "@FROM_YEAR", value: fromYear)
    cmd.parameters.addWithValue(key: "@TO_YEAR", value: toYear)
    cmd.parameters.addWithValue(key: "@CHART_ID", value: chartId)

    if let reader = cmd.executeReader() {
         
      if reader.read() {
        if !reader.isDBNull(index: 0) {
          minValue = reader.getInt(index: 0)!
        }
      }
         
      reader.close()
         
    }
    
    if shouldClose {
      conn.close()
    }
    
    return minValue
  }
  
  public static var ColumnNames : String {
    get {
      return "[\(PLAY_COUNT.YEAR_NUMBER)], [\(PLAY_COUNT.PLAY_COUNT)], [\(PLAY_COUNT.CHART_ID)]"
    }
  }
  
  public static func lowestRandomYear(fromYear:Int, toYear:Int, chartId:Int = 1) -> PlayCount {
    
    if toYear <= fromYear {
      return PlayCount(year: fromYear, chartId: chartId)
    }
    
    for year in fromYear ... toYear {
      let _ = PlayCount(year: year, chartId: chartId)
    }
    
    let min = minimumPlayCount(fromYear: fromYear, toYear: toYear, chartId: chartId)
    
    repeat {
      let year = Int.random(in: fromYear ... toYear)
      let playCount = PlayCount(year: year, chartId: chartId)
      if  playCount.playCount == min {
        return playCount
      }
    } while true
    
  }
  
}
