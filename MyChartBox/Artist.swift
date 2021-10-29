//
//  Artist.swift
//  MyChartBox
//
//  Created by Paul Willmott on 11/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation

public class Artist : NSObject {
  
  private var _artistId    : Int = -1
  private var _ukChartName : String = ""
  private var _artistName  : String = ""
  private var _sortName    : String = ""
  private var _modified    : Bool = false
  
  @objc dynamic public var ArtistId : Int {
    get {
      return _artistId
    }
    set(value) {
      if value != _artistId {
        willChangeValue(forKey: "artistId")
        _artistId = value
        didChangeValue(forKey: "artistId")
        Modified = true
      }
    }
  }
  
  @objc dynamic public var UKChartName : String {
    get {
      return _ukChartName
    }
    set(value) {
      if value != _ukChartName {
        willChangeValue(forKey: "ukChartName")
        _ukChartName = value
        didChangeValue(forKey: "ukChartName")
        Modified = true
      }
    }
  }
  
  @objc dynamic public var ArtistName : String {
    get {
      return _artistName
    }
    set(value) {
      if value != _artistName {
        willChangeValue(forKey: "artistName")
        _artistName = value
        didChangeValue(forKey: "artistName")
        Modified = true
      }
    }
  }
  
  public var ArtistNameClean : String {
    get {
      let bits = _artistName.replacingOccurrences(of: " FT ", with: " featuring ").capitalized.split(separator: "/")
      var temp = ""
      for i in 0...bits.count-1 {
        if i > 0 {
          if i == bits.count - 1 {
            temp += " and "
          }
          else {
            temp += ", "
          }
        }
        temp += bits[i]
      }

      return temp
    }
    }
  
  @objc dynamic public var SortName : String {
    get {
      return _sortName
    }
    set(value) {
      if value != _sortName {
        willChangeValue(forKey: "sortName")
        _sortName = value
        didChangeValue(forKey: "sortName")
        Modified = true
      }
    }
  }
  
  @objc dynamic public var Modified : Bool {
    get {
      return _modified
    }
    set(value) {
      if value != _modified {
        willChangeValue(forKey: "modified")
        _modified = value
        didChangeValue(forKey: "modified")
      }
    }
  }
  
  override init() {
    super.init()
  }
  
  init(reader:SqliteDataReader) {
    super.init()
    decode(sqliteDataReader: reader)
  }
  
  init(artistId:Int) {
    
    super.init()

    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT " + Artist.ColumnNames + " FROM [\(TABLE.ARTIST)] " +
    "WHERE [\(ARTIST.ARTIST_ID)] = @\(ARTIST.ARTIST_ID)"

    cmd.parameters.addWithValue(key: "@\(ARTIST.ARTIST_ID)", value: artistId)
    
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


  init(ukChartName:String) {
    
    super.init()

    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT " + Artist.ColumnNames + " FROM [\(TABLE.ARTIST)] " +
    "WHERE [\(ARTIST.UKCHART_NAME)] = @\(ARTIST.UKCHART_NAME)"

    cmd.parameters.addWithValue(key: "@\(ARTIST.UKCHART_NAME)", value: ukChartName)
    
    if let reader = cmd.executeReader() {
         
      if reader.read() {
        decode(sqliteDataReader: reader)
      }
         
      reader.close()
         
    }
    
    if ArtistId == -1 {
      UKChartName = ukChartName
      ArtistName = ukChartName
      SortName = ukChartName
      Save()
    }
       
    if shouldClose {
      conn.close()
    }

  }
  
  public func Save() {
    
    if Modified {
      
      var sql = ""
      
      if ArtistId == -1 {
        sql = "INSERT INTO [\(TABLE.ARTIST)] (" +
        "[\(ARTIST.ARTIST_ID)], " +
        "[\(ARTIST.UKCHART_NAME)], " +
        "[\(ARTIST.ARTIST_NAME)], " +
        "[\(ARTIST.SORT_NAME)]" +
        ") VALUES (" +
        "@\(ARTIST.ARTIST_ID), " +
        "@\(ARTIST.UKCHART_NAME), " +
        "@\(ARTIST.ARTIST_NAME), " +
        "@\(ARTIST.SORT_NAME)" +
        ")"
        ArtistId = Database.nextCode(tableName: TABLE.ARTIST, primaryKey: ARTIST.ARTIST_ID)!
      }
      else {
        sql = "UPDATE [\(TABLE.ARTIST)] SET " +
        "[\(ARTIST.UKCHART_NAME)] = @\(ARTIST.UKCHART_NAME), " +
        "[\(ARTIST.ARTIST_NAME)] = @\(ARTIST.ARTIST_NAME), " +
        "[\(ARTIST.SORT_NAME)] = @\(ARTIST.SORT_NAME) " +
        "WHERE [\(ARTIST.ARTIST_ID)] = @\(ARTIST.ARTIST_ID)"
      }

      let conn = Database.getConnection()
      
      let shouldClose = conn.state != .Open
       
      if shouldClose {
         _ = conn.open()
      }
       
      let cmd = conn.createCommand()
       
      cmd.commandText = sql
      
      cmd.parameters.addWithValue(key: "@\(ARTIST.ARTIST_ID)", value: ArtistId)
      cmd.parameters.addWithValue(key: "@\(ARTIST.UKCHART_NAME)", value: UKChartName)
      cmd.parameters.addWithValue(key: "@\(ARTIST.ARTIST_NAME)", value: ArtistName)
      cmd.parameters.addWithValue(key: "@\(ARTIST.SORT_NAME)", value: SortName)
      
      _ = cmd.executeNonQuery()

      if shouldClose {
        conn.close()
      }
      
      Modified = false
      
 //     print("Artist.Save: \(ArtistId), \(UKChartName), \(ArtistName), \(SortName)")

    }

  }
  
  public static var ColumnNames : String {
    get {
      return
        "[\(ARTIST.ARTIST_ID)], " +
        "[\(ARTIST.UKCHART_NAME)], " +
        "[\(ARTIST.ARTIST_NAME)], " +
        "[\(ARTIST.SORT_NAME)]"
    }
  }
  
  private func decode(sqliteDataReader:SqliteDataReader?) {
    
    if let reader = sqliteDataReader {
      
      ArtistId = reader.getInt(index: 0)!
      
      if !reader.isDBNull(index: 1) {
        UKChartName = reader.getString(index: 1)!
      }
      
      if !reader.isDBNull(index: 2) {
        ArtistName = reader.getString(index: 2)!
      }
      
      if !reader.isDBNull(index: 3) {
        SortName = reader.getString(index: 3)!
      }
      
//      print("Artist.decode: \(ArtistId), \(UKChartName), \(ArtistName), \(SortName)")
      
    }
    
    Modified = false
    
  }

}
