//
//  ChartEntry.swift
//  MyChartBox
//
//  Created by Paul Willmott on 12/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation

public class ChartEntry : NSObject {
 
  private var _chartEntryId    : Int = -1
  private var _chartDate       : Date = Date()
  private var _chartListingId  : Int = -1
  private var _ukChartTitle    : String = ""
  private var _position        : String = ""
  private var _lastPosition    : String = ""
  private var _highestPosition : String = ""
  private var _weeksOnChart    : String = ""
  private var _modified        : Bool = false
  private var _chartListing    : ChartListing?
  private var _index           : Int = -1
  private var _bestTrack       : MusicTrack?
  private var _bestAlbum       : MusicAlbum?
  
  public var ChartEntryId : Int {
    get {
      return _chartEntryId
    }
    set(value) {
      if value != _chartEntryId {
        _chartEntryId = value
        Modified = true
      }
    }
  }
  
  public var ChartId : Int {
    get {
      return chartListing.ChartId
    }
  }
  
  public var Index : Int {
    get {
      return _index
    }
    set(value) {
      if value != _index {
        _index = value
        Modified = true
      }
    }
  }
  
  public var ChartDate : Date {
    get {
      return _chartDate
    }
    set(value) {
      if value != _chartDate {
        _chartDate = value
        Modified = true
      }
    }
  }
  
  public var ChartListingId : Int {
    get {
      return _chartListingId
    }
    set(value) {
      if value != _chartListingId {
        _chartListingId = value
        Modified = true
      }
    }
  }
  
  public var Position : String {
    get {
      return _position
    }
    set(value) {
      if value != _position {
        _position = value
        Modified = true
      }
    }
  }
  
  public var LastPosition : String {
    get {
      return _lastPosition
    }
    set(value) {
      if value != _lastPosition {
        _lastPosition = value
        Modified = true
      }
    }
  }
  
  public var HighestPosition : String {
    get {
      return _highestPosition
    }
    set(value) {
      if value != _highestPosition {
        _highestPosition = value
        Modified = true
      }
    }
  }
  
  public var WeeksOnChart : String {
    get {
      return _weeksOnChart
    }
    set(value) {
      if value != _weeksOnChart {
        _weeksOnChart = value
        Modified = true
      }
    }
  }
  
  public var Modified : Bool {
    get {
      return _modified
    }
    set(value) {
      _modified = value
    }
  }
  
  public var chartListing : ChartListing {
    get {
      if let listing = _chartListing {
        return listing
      }
      _chartListing = ChartListing(listingId: _chartListingId)
      return _chartListing!
    }
  }
  
  public var bestTrack : MusicTrack? {
    
//    set(value) {
//      _bestTrack = value
//    }
    get {
      _bestTrack = chartListing.bestTrack(index: Index)
      return _bestTrack
    }
  }
  
  public var bestAlbum : MusicAlbum? {
    get {
      return chartListing.bestAlbum()
    }
  }
  
  override init() {
    super.init()
  }
  
  init(reader:SqliteDataReader) {
    super.init()
    decode(sqliteDataReader: reader)
  }

  init(
    chartListingId:Int,
    chartDate:Date,
    position:String,
    lastPosition:String,
    highestPosition:String,
    weeksOnChart:String
  ) {
    
    super.init()

    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT " + ChartEntry.ColumnNames + " FROM [\(TABLE.CHART_ENTRY)] " +
      "WHERE [\(CHART_ENTRY.CHART_LISTING_ID)] = @\(CHART_ENTRY.CHART_LISTING_ID) AND " +
      "[\(CHART_ENTRY.CHART_DATE)] = @\(CHART_ENTRY.CHART_DATE)"

    cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.CHART_LISTING_ID)", value: chartListingId)
    cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.CHART_DATE)", value: chartDate)

    if let reader = cmd.executeReader() {
         
      if reader.read() {
        decode(sqliteDataReader: reader)
      }
         
      reader.close()
         
    }
    
    if ChartListingId == -1 {
      ChartListingId = chartListingId
      ChartDate = chartDate
      Position = position
      LastPosition = lastPosition
      HighestPosition = highestPosition
      WeeksOnChart = weeksOnChart
      Save()
    }
       
    if shouldClose {
      conn.close()
    }

  }
  
  public func Save() {
    
    if Modified {
      
      var sql = ""
      
      if ChartEntryId == -1 {
        sql = "INSERT INTO [\(TABLE.CHART_ENTRY)] (" +
        "[\(CHART_ENTRY.CHART_ENTRY_ID)], " +
        "[\(CHART_ENTRY.CHART_DATE)], " +
        "[\(CHART_ENTRY.CHART_LISTING_ID)], " +
        "[\(CHART_ENTRY.POSITION)], " +
        "[\(CHART_ENTRY.LAST_POSITION)], " +
        "[\(CHART_ENTRY.HIGHEST_POSITION)], " +
        "[\(CHART_ENTRY.WEEKS_ON_CHART)], " +
        "[\(CHART_ENTRY.CHART_ID)]" +
        ") VALUES (" +
        "@\(CHART_ENTRY.CHART_ENTRY_ID), " +
        "@\(CHART_ENTRY.CHART_DATE), " +
        "@\(CHART_ENTRY.CHART_LISTING_ID), " +
        "@\(CHART_ENTRY.POSITION), " +
        "@\(CHART_ENTRY.LAST_POSITION), " +
        "@\(CHART_ENTRY.HIGHEST_POSITION), " +
        "@\(CHART_ENTRY.WEEKS_ON_CHART), " +
        "@\(CHART_ENTRY.CHART_ID)" +
        ")"
        ChartEntryId = Database.nextCode(tableName: TABLE.CHART_ENTRY, primaryKey: CHART_ENTRY.CHART_ENTRY_ID)!
      }
      else {
        sql = "UPDATE [\(TABLE.CHART_ENTRY)] SET " +
        "[\(CHART_ENTRY.CHART_DATE)] = @\(CHART_ENTRY.CHART_DATE), " +
        "[\(CHART_ENTRY.CHART_LISTING_ID)] = @\(CHART_ENTRY.CHART_LISTING_ID), " +
        "[\(CHART_ENTRY.POSITION)] = @\(CHART_ENTRY.POSITION), " +
        "[\(CHART_ENTRY.LAST_POSITION)] = @\(CHART_ENTRY.LAST_POSITION), " +
        "[\(CHART_ENTRY.HIGHEST_POSITION)] = @\(CHART_ENTRY.HIGHEST_POSITION), " +
        "[\(CHART_ENTRY.WEEKS_ON_CHART)] = @\(CHART_ENTRY.WEEKS_ON_CHART), " +
        "[\(CHART_ENTRY.CHART_ID)] = @\(CHART_ENTRY.CHART_ID) " +
        "WHERE [\(CHART_ENTRY.CHART_ENTRY_ID)] = @\(CHART_ENTRY.CHART_ENTRY_ID)"
      }

      let conn = Database.getConnection()
      
      let shouldClose = conn.state != .Open
       
      if shouldClose {
         _ = conn.open()
      }
       
      let cmd = conn.createCommand()
       
      cmd.commandText = sql
      
      cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.CHART_ENTRY_ID)", value: ChartEntryId)
      cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.CHART_DATE)", value: ChartDate)
      cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.CHART_LISTING_ID)", value: ChartListingId)
      cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.POSITION)", value: Position)
      cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.LAST_POSITION)", value: LastPosition)
      cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.HIGHEST_POSITION)", value: HighestPosition)
      cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.WEEKS_ON_CHART)", value: WeeksOnChart)
      cmd.parameters.addWithValue(key: "@\(CHART_ENTRY.CHART_ID)", value: ChartId)

      _ = cmd.executeNonQuery()

      if shouldClose {
        conn.close()
      }
      
      Modified = false

    }

  }

  public static var ColumnNames : String {
    get {
      return
        "[\(CHART_ENTRY.CHART_ENTRY_ID)], " +
        "[\(CHART_ENTRY.CHART_DATE)], " +
        "[\(CHART_ENTRY.CHART_LISTING_ID)], " +
        "[\(CHART_ENTRY.POSITION)], " +
        "[\(CHART_ENTRY.LAST_POSITION)], " +
        "[\(CHART_ENTRY.HIGHEST_POSITION)], " +
        "[\(CHART_ENTRY.WEEKS_ON_CHART)], " +
        "[\(CHART_ENTRY.CHART_ID)]"
    }
  }
  
  private func decode(sqliteDataReader:SqliteDataReader?) {
    
    if let reader = sqliteDataReader {
      
      ChartEntryId = reader.getInt(index: 0)!
      
      if !reader.isDBNull(index: 1) {
        ChartDate = reader.getDate(index: 1)!
      }
      
      if !reader.isDBNull(index: 2) {
        ChartListingId = reader.getInt(index: 2)!
      }
      
      if !reader.isDBNull(index: 3) {
        Position = reader.getString(index: 3)!
      }
      
      if !reader.isDBNull(index: 4) {
        LastPosition = reader.getString(index: 4)!
      }
      
      if !reader.isDBNull(index: 5) {
        HighestPosition = reader.getString(index: 5)!
      }
      
      if !reader.isDBNull(index: 6) {
        WeeksOnChart = reader.getString(index: 6)!
      }

      if !reader.isDBNull(index: 7) {
        //ChartId = reader.getInt(index: 7)!
        // print("chartId: \(reader.getInt(index: 7)!)")
      }
    }
    
    Modified = false
    
  }

}
