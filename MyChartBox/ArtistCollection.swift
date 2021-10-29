//
//  ArtistCollection.swift
//  MyChartBox
//
//  Created by Paul Willmott on 10/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation

public class ArtistCollection : NSObject {
  
  override init() {
    super.init()
  }
   
  init(collectionid:Int) {
     
    super.init()

    let conn = Database.getConnection()
     
    let shouldClose = conn.state != .Open
      
    if shouldClose {
       _ = conn.open()
    }
      
    let cmd = conn.createCommand()
      
    cmd.commandText = "SELECT " + ArtistCollection.ColumnNames + " FROM [\(TABLE.COLLECTION)] " +
    "WHERE [\(COLLECTION.COLLECTION_ID)] = @\(COLLECTION.COLLECTION_ID)"
     
    cmd.parameters.addWithValue(key: "@\(COLLECTION.COLLECTION_ID)", value: collectionid)

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
  
  private var _collectionId     : Int = -1
  private var _collectionName   : String = ""
  private var _links            : String = ""
  private var _modified         : Bool = false
   
  // Public Properties

  public var collectionId : Int {
    get {
      return _collectionId
    }
    set(value) {
      if value != _collectionId {
        _collectionId = value
        modified = true
      }
    }
  }
   
  public var collectionName : String {
    get {
      return _collectionName
    }
    set(value) {
      if value != _collectionName {
        _collectionName = value
        modified = true
      }
    }
  }
   
  public var links : String {
    get {
      return _links
    }
    set(value) {
      if value != _links {
        _links = value
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
  
  public var sortName : String {
    get {
      if collectionName.prefix(4).uppercased() == "THE " {
        return "\(collectionName.suffix(collectionName.count - 4)), \(collectionName.prefix(3))"
      }
      return collectionName
    }
  }
  
  // Database Methods
  
  public func Save() {
     
    if modified {
       
      var sql = ""
       
      if collectionId == -1 {
        sql = "INSERT INTO [\(TABLE.COLLECTION)] (" +
          "[\(COLLECTION.COLLECTION_ID)], " +
          "[\(COLLECTION.COLLECTION_NAME)], " +
          "[\(COLLECTION.SORT_NAME)], " +
          "[\(COLLECTION.LINKS)] " +
        ") VALUES (" +
          "@\(COLLECTION.COLLECTION_ID), " +
          "@\(COLLECTION.COLLECTION_NAME), " +
          "@\(COLLECTION.SORT_NAME), " +
          "@\(COLLECTION.LINKS) " +
        ")"
        collectionId = Database.nextCode(tableName: TABLE.COLLECTION, primaryKey: COLLECTION.COLLECTION_ID)!
      }
      else {
        sql = "UPDATE [\(TABLE.COLLECTION)] SET " +
          "[\(COLLECTION.COLLECTION_NAME)] = @\(COLLECTION.COLLECTION_NAME), " +
          "[\(COLLECTION.SORT_NAME)] = @\(COLLECTION.SORT_NAME), " +
          "[\(COLLECTION.LINKS)] = @\(COLLECTION.LINKS) " +
        "WHERE [\(COLLECTION.COLLECTION_ID)] = @\(COLLECTION.COLLECTION_ID)"
      }

      let conn = Database.getConnection()
       
      let shouldClose = conn.state != .Open
        
      if shouldClose {
         _ = conn.open()
      }
        
      let cmd = conn.createCommand()
        
      cmd.commandText = sql
       
      cmd.parameters.addWithValue(key: "@\(COLLECTION.COLLECTION_ID)", value: collectionId)
      cmd.parameters.addWithValue(key: "@\(COLLECTION.COLLECTION_NAME)", value: collectionName)
      cmd.parameters.addWithValue(key: "@\(COLLECTION.SORT_NAME)", value: sortName)
      cmd.parameters.addWithValue(key: "@\(COLLECTION.LINKS)", value: links)

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
        "[\(COLLECTION.COLLECTION_ID)], " +
        "[\(COLLECTION.COLLECTION_NAME)], " +
        "[\(COLLECTION.SORT_NAME)], " +
        "[\(COLLECTION.LINKS)]"
    }
  }
   
  private func decode(sqliteDataReader:SqliteDataReader?) {
     
    if let reader = sqliteDataReader {
       
      collectionId = reader.getInt(index: 0)!
       
      if !reader.isDBNull(index: 1) {
        collectionName = reader.getString(index: 1)!
      }
       
      if !reader.isDBNull(index: 3) {
        links = reader.getString(index: 3)!
      }
       
    }
     
    modified = false
     
  }
  
  public func ArtistChartListings(chartType:ChartType) -> [ArtistCollectionChartListing] {
    
    let chartId : Int = chartType.rawValue
    
    var list : [ArtistCollectionChartListing] = []
    
    let conn = Database.getConnection()
     
    let shouldClose = conn.state != .Open
      
    if shouldClose {
       _ = conn.open()
    }
      
    let cmd = conn.createCommand()
      
    cmd.commandText = "SELECT " +
      "(SELECT MIN([\(CHART_ENTRY.CHART_DATE)]) FROM [\(TABLE.CHART_ENTRY)] AS T2 WHERE T2.[\(CHART_ENTRY.CHART_LISTING_ID)] = T1.[\(CHART_LISTING.CHART_LISTING_ID)] LIMIT 1) AS ENTRY_DATE, " +

      "(SELECT MIN(CAST([\(CHART_ENTRY.POSITION)] AS INTEGER)) FROM [\(TABLE.CHART_ENTRY)] AS T3 WHERE T3.[\(CHART_ENTRY.CHART_LISTING_ID)] = T1.[\(CHART_LISTING.CHART_LISTING_ID)] LIMIT 1) AS PEAK_POSITION, " +

      "(SELECT MAX(CAST([\(CHART_ENTRY.WEEKS_ON_CHART)] AS INTEGER)) FROM [\(TABLE.CHART_ENTRY)] AS T4 WHERE T4.[\(CHART_ENTRY.CHART_LISTING_ID)] = T1.[\(CHART_LISTING.CHART_LISTING_ID)] LIMIT 1) AS WEEKS_ON_CHART, " +
      
      "T1.[\(CHART_LISTING.CHART_LISTING_ID)]" +

    "FROM [\(TABLE.CHART_LISTING)] AS T1 " +
    "WHERE [\(CHART_LISTING.ARTIST_ID)] IN (\(links)) AND " +
    "[\(CHART_LISTING.CHART_ID)] = \(chartId) " +
    "ORDER BY ENTRY_DATE"
     
    if let reader = cmd.executeReader() {
          
      while reader.read() {
        let chartListing = ChartListing(listingId: reader.getInt(index: 3)!)
        for index in 0...chartListing.sides.count - 1 {
          list.append(ArtistCollectionChartListing(reader: reader, index: index))
        }
      }
          
      reader.close()
          
    }
     
    if shouldClose {
      conn.close()
    }
    
    return list

  }
  
}

public class ArtistCollectionChartListing : NSObject {
  
  public var chartEntryDate : Date
  public var positionFlag : PositionFlag
  public var peakPosition : String
  public var weeksOnChart : String
  public var chartListing : ChartListing
  public var index        : Int
  
  init(reader:SqliteDataReader, index:Int) {
    
    self.chartEntryDate = reader.getDate(index: 0)!
    let peakPosition = reader.getInt(index: 1)!
    self.peakPosition = "\(peakPosition)"
    let weeksOnChart = reader.getInt(index: 2)!
    self.weeksOnChart = "\(weeksOnChart)"
    self.chartListing = ChartListing(listingId: reader.getInt(index: 3)!)
    if peakPosition == 1 {
      positionFlag = .NumberOne
    }
    else if peakPosition <= 10 {
      positionFlag = .Top10
    }
    else {
      positionFlag = .None
    }
    self.index = index
  }
  
  public var bestTrack : MusicTrack? {
    get {
      return chartListing.bestTrack(index: index)
    }
  }
  
  public var bestAlbum : MusicAlbum? {
    get {
      return chartListing.bestAlbum()
    }
  }
  
}

public enum PositionFlag {
  case NumberOne
  case Top10
  case None
}
