//
//  Chart.swift
//  MyChartBox
//
//  Created by Paul Willmott on 12/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation

class Chart : NSObject {

  override init() {
    super.init()
  }

  init(chartId:Int) {
    
    super.init()

    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT " + Chart.ColumnNames + " FROM [\(TABLE.CHART)] " +
    "WHERE [\(CHART.CHART_ID)] = @\(CHART.CHART_ID)"
    
    cmd.parameters.addWithValue(key: "@\(CHART.CHART_ID)", value: chartId)

    if let reader = cmd.executeReader() {
         
      if reader.read() {
        decode(sqliteDataReader: reader)
      }
         
      reader.close()
         
    }
    
    if shouldClose {
      conn.close()
    }

  }

  // Private Properties
  
  private var _chartId     : Int = -1
  private var _ukChartId   : String = ""
  private var _chartName   : String = ""
  private var _modified    : Bool = false
  
  // Public Properties
  
  public var chartId : Int {
    get {
      return _chartId
    }
    set(value) {
      if value != _chartId {
        _chartId = value
        modified = true
      }
    }
  }
  
  public var ukChartId : String {
    get {
      return _ukChartId
    }
    set(value) {
      if value != _ukChartId {
        _ukChartId = value
        modified = true
      }
    }
  }
  
  public var chartName : String {
    get {
      return _chartName
    }
    set(value) {
      if value != _chartName {
        _chartName = value
        modified = true
      }
    }
  }
  
  public var modified : Bool {
    get {
      return _modified
    }
    set(value) {
      if value != _modified {
        _modified = value
      }
    }
  }
  
  // Database Methods
  
  public func save() {
    
    if modified {
      
      var sql = ""
      
      if chartId == -1 {
        sql = "INSERT INTO [\(TABLE.CHART)] (" +
        "[\(CHART.CHART_ID)], " +
        "[\(CHART.UKCHART_ID)], " +
        "[\(CHART.CHART_NAME)] " +
        ") VALUES (" +
        "@\(CHART.CHART_ID), " +
        "@\(CHART.UKCHART_ID), " +
        "@\(CHART.CHART_NAME) " +
        ")"
        chartId = Database.nextCode(tableName: TABLE.CHART, primaryKey: CHART.CHART_ID)!
      }
      else {
        sql = "UPDATE [\(TABLE.CHART)] SET " +
        "[\(CHART.UKCHART_ID)] = @\(CHART.UKCHART_ID), " +
        "[\(CHART.CHART_NAME)] = @\(CHART.CHART_NAME) " +
        "WHERE [\(CHART.CHART_ID)] = @\(CHART.CHART_ID)"
      }

      let conn = Database.getConnection()
      
      let shouldClose = conn.state != .Open
       
      if shouldClose {
         _ = conn.open()
      }
       
      let cmd = conn.createCommand()
       
      cmd.commandText = sql
      
      cmd.parameters.addWithValue(key: "@\(CHART.CHART_ID)", value: chartId)
      cmd.parameters.addWithValue(key: "@\(CHART.UKCHART_ID)", value: ukChartId)
      cmd.parameters.addWithValue(key: "@\(CHART.CHART_NAME)", value: chartName)

      _ = cmd.executeNonQuery()

      if shouldClose {
        conn.close()
      }
      
      modified = false

    }

  }
  
  public static var ColumnNames : String {
    get {
      return
        "[\(CHART.CHART_ID)], " +
        "[\(CHART.UKCHART_ID)], " +
        "[\(CHART.CHART_NAME)] "
    }
  }
  
  private func decode(sqliteDataReader:SqliteDataReader?) {
    
    if let reader = sqliteDataReader {
      
      chartId = reader.getInt(index: 0)!
      
      if !reader.isDBNull(index: 1) {
        ukChartId = reader.getString(index: 1)!
      }
      
      if !reader.isDBNull(index: 2) {
        chartName = reader.getString(index: 2)!
      }
      
    }
    
    modified = false
    
  }

}

public enum ChartType : Int {
  case Singles = 1
  case Albums = 2
}
