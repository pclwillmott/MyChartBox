//
//  iTunesArtist.swift
//  MyChartBox
//
//  Created by Paul Willmott on 25/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import iTunesLibrary

public class iTunesArtistX : NSObject {

  private var _artistId   : Int = -1
  private var _artistPid  : String = ""
  private var _artistName : String = ""
  private var _sortName   : String = ""
  private var _updated    : Int?
  private var _modified   : Bool = false
  
  public  var newRow     : Bool = true
  
  public var updated : Int? {
    get {
      return _updated
    }
    set(value) {
      _updated = value
      Modified = true
    }
  }
  
  @objc dynamic public var artistId : Int {
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
    @objc dynamic public var artistPid : String {
    get {
      return _artistPid
    }
    set(value) {
      if value != _artistPid {
        willChangeValue(forKey: "artistPid")
        _artistPid = value
        didChangeValue(forKey: "artistPid")
        Modified = true
      }
    }
  }
  
  @objc dynamic public var artistName : String {
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
  
  @objc dynamic public var sortName : String {
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
  
  public static func possibleMatches(artistName:String) -> String {
    
    var codes = ""
    
    for optionA in 0...1 {
      
      var tryNameA = artistName
      
      if optionA == 1 {
        if artistName.prefix(4) == "THE " {
          tryNameA = artistName.suffix(artistName.count-4).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        else {
          tryNameA = "THE \(artistName)"
        }
      }
      
      for optionB in 0...2 {
        
        var tryNameB = tryNameA
        
        if optionB == 1 {
          tryNameB = tryNameA.replacingOccurrences(of: " AND ", with: " & ")
        }
        else if optionB == 2 {
          tryNameB = tryNameA.replacingOccurrences(of: " & ", with: " AND ")
        }
        
        if optionB == 0 || tryNameB != tryNameA {
          if let artist = iTunesArtistX(exactArtistName: tryNameB) {
            if !codes.isEmpty {
              codes += ", "
            }
            codes += "\(artist.artistId)"
          }
        }
        
        let options = [" FEATURING ", " FEAT. ", " FT. ", " FEAT ", " FT "]

        for optionC in options {
          
          if let index = tryNameB.index(of: optionC) {
            let tryNameE = String(tryNameB[..<index]).trimmingCharacters(in: .whitespacesAndNewlines)
            if tryNameE != tryNameB {
              if let artist = iTunesArtistX(exactArtistName: tryNameE) {
                if !codes.isEmpty {
                  codes += ", "
                }
                codes += "\(artist.artistId)"
              }
            }
          }
          
          for optionD in options {
            
            var tryNameD = tryNameB
            
            if optionC != optionD {
              tryNameD = tryNameB.replacingOccurrences(of: optionC, with: optionD)
              if tryNameD != tryNameB {
                if let artist = iTunesArtistX(exactArtistName: tryNameD) {
                  if !codes.isEmpty {
                    codes += ", "
                  }
                  codes += "\(artist.artistId)"
                }
              }
            }
            
          }
          
        }
      }
      
    }
    
    return codes
    
  }
  
  init?(exactArtistName:String) {
    
    super.init()
    
    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText =
      "SELECT " + iTunesArtistX.ColumnNames + " FROM [\(TABLE.ITUNES_ARTIST)] " +
      "WHERE UPPER([\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)]) = @\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)"
    
    cmd.parameters.addWithValue(key: "@\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)", value: "\(exactArtistName)")

    if let reader = cmd.executeReader() {
         
      if reader.read() {
        decode(sqliteDataReader: reader)
      }
         
      reader.close()
         
    }
    
    if shouldClose {
      conn.close()
    }
    
    if artistId == -1 {
      return nil
    }
    
  }
  
  init?(artistname:String) {
    
    super.init()
    
    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT " + iTunesArtistX.ColumnNames + " FROM [\(TABLE.ITUNES_ARTIST)] " +
    "WHERE UPPER([\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)]) = @\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)"
    
    cmd.parameters.addWithValue(key: "@\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)", value: "\(artistname)")

    if let reader = cmd.executeReader() {
         
      if reader.read() {
        decode(sqliteDataReader: reader)
      }
         
      reader.close()
         
    }
    
    if shouldClose {
      conn.close()
    }
    
    if (_artistId == -1) {
        
      let options = [" FEAT. ", " FEAT ", " FT. ", " AND ", " & ", "X", "NO THE", "THE"]
        
      for option in options {
          
        let conn = Database.getConnection()
           
        let shouldClose = conn.state != .Open
            
        if shouldClose {
          _ = conn.open()
        }
          
        var aname = ""
        if option == "X" {
          if let index = artistname.index(of: " FT ") {
            aname = String(artistname[..<index]).trimmingCharacters(in: .whitespacesAndNewlines)
          }
        }
        else if option == "NO THE" {
          if artistname.prefix(4) == "THE " {
            aname = artistname.suffix(artistname.count-4).trimmingCharacters(in: .whitespacesAndNewlines)
          }
        }
        else if option == "THE" {
          aname = "THE \(artistname)"
        }
        else if option == " AND "{
          aname = artistname.replacingOccurrences(of: " AND ", with: " & ")
        }
        else if option == " & "{
          aname = artistname.replacingOccurrences(of: " & ", with: " AND ")
        }
        else {
          aname = artistname.replacingOccurrences(of: " FT ", with: option)
        }
        
        let cmd = conn.createCommand()
            
        cmd.commandText = "SELECT " + iTunesArtistX.ColumnNames + " FROM [\(TABLE.ITUNES_ARTIST)] " +
          "WHERE UPPER([\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)]) = @\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)"
           
        cmd.parameters.addWithValue(key: "@\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)", value: "\(aname)")

        if let reader = cmd.executeReader() {
                
          if reader.read() {
            decode(sqliteDataReader: reader)
          }
                
          reader.close()
                
        }
           
        if shouldClose {
          conn.close()
        }

        if _artistId != -1 {
          break
        }
      }
    }
  
    
    if _artistId == -1 {
      return nil
    }

  }
  
  init(artist:ITLibArtist) {
    super.init()
    artistPid = "\(artist.persistentID)"
    if !load(artistPID: artistPid) {
      updated = 1
    }
    if let name = artist.name {
      artistName = name
    }
    if let sort = artist.sortName {
      sortName = sort
    }
    Save()
  }
  
  init(reader:SqliteDataReader) {
    super.init()
    decode(sqliteDataReader: reader)
  }
  
  init?(artistid:Int) {
    
    super.init()
    
    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT " + iTunesArtistX.ColumnNames + " FROM [\(TABLE.ITUNES_ARTIST)] " +
    "WHERE [\(ITUNES_ARTIST.ITUNES_ARTIST_ID)] = @\(ITUNES_ARTIST.ITUNES_ARTIST_ID)"
    
    cmd.parameters.addWithValue(key: "@\(ITUNES_ARTIST.ITUNES_ARTIST_ID)", value: artistid)

    if let reader = cmd.executeReader() {
         
      if reader.read() {
        decode(sqliteDataReader: reader)
      }
         
      reader.close()
         
    }
    
    if shouldClose {
      conn.close()
    }
    
    if artistId == -1 {
      return nil
    }
    
  }

  private func load(artistPID:String) -> Bool {
    
    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT " + iTunesArtistX.ColumnNames + " FROM [\(TABLE.ITUNES_ARTIST)] " +
    "WHERE [\(ITUNES_ARTIST.ITUNES_ARTIST_PID)] = @\(ITUNES_ARTIST.ITUNES_ARTIST_PID)"
    
    cmd.parameters.addWithValue(key: "@\(ITUNES_ARTIST.ITUNES_ARTIST_PID)", value: artistPID)

    if let reader = cmd.executeReader() {
         
      if reader.read() {
        decode(sqliteDataReader: reader)
      }
         
      reader.close()
         
    }
    
    if shouldClose {
      conn.close()
    }
    
    return !newRow

  }
  
  public func Save() {
    
    if Modified {
      
      var sql = ""
      
      if newRow {
        sql = "INSERT INTO [\(TABLE.ITUNES_ARTIST)] (" +
          "[\(ITUNES_ARTIST.ITUNES_ARTIST_ID)], " +
          "[\(ITUNES_ARTIST.ITUNES_ARTIST_PID)], " +
          "[\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)], " +
          "[\(ITUNES_ARTIST.ITUNES_SORT_NAME)], " +
          "[\(ITUNES_ARTIST.UPDATED)] " +
        ") VALUES (" +
          "@\(ITUNES_ARTIST.ITUNES_ARTIST_ID), " +
          "@\(ITUNES_ARTIST.ITUNES_ARTIST_PID), " +
          "@\(ITUNES_ARTIST.ITUNES_ARTIST_NAME), " +
          "@\(ITUNES_ARTIST.ITUNES_SORT_NAME), " +
          "@\(ITUNES_ARTIST.UPDATED) " +
        ")"
        artistId = Database.nextCode(tableName: TABLE.ITUNES_ARTIST, primaryKey: ITUNES_ARTIST.ITUNES_ARTIST_ID)!
      }
      else {
        sql = "UPDATE [\(TABLE.ITUNES_ARTIST)] SET " +
          "[\(ITUNES_ARTIST.ITUNES_ARTIST_PID)] = @\(ITUNES_ARTIST.ITUNES_ARTIST_PID), " +
          "[\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)] = @\(ITUNES_ARTIST.ITUNES_ARTIST_NAME), " +
          "[\(ITUNES_ARTIST.ITUNES_SORT_NAME)] = @\(ITUNES_ARTIST.ITUNES_SORT_NAME), " +
          "[\(ITUNES_ARTIST.UPDATED)] = @\(ITUNES_ARTIST.UPDATED) " +
          "WHERE [\(ITUNES_ARTIST.ITUNES_ARTIST_ID)] = @\(ITUNES_ARTIST.ITUNES_ARTIST_ID)"
      }

      let conn = Database.getConnection()
      
      let shouldClose = conn.state != .Open
       
      if shouldClose {
         _ = conn.open()
      }
       
      let cmd = conn.createCommand()
       
      cmd.commandText = sql
      
      cmd.parameters.addWithValue(key: "@\(ITUNES_ARTIST.ITUNES_ARTIST_ID)", value: artistId)
      cmd.parameters.addWithValue(key: "@\(ITUNES_ARTIST.ITUNES_ARTIST_PID)", value: artistPid)
      cmd.parameters.addWithValue(key: "@\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)", value: artistName)
      cmd.parameters.addWithValue(key: "@\(ITUNES_ARTIST.ITUNES_SORT_NAME)", value: sortName)
      cmd.parameters.addWithValue(key: "@\(ITUNES_ARTIST.UPDATED)", value: updated)

      _ = cmd.executeNonQuery()

      if shouldClose {
        conn.close()
      }
      
      Modified = false
      
      newRow = false

    }

  }

  public static var ColumnNames : String {
    get {
      return
        "[\(ITUNES_ARTIST.ITUNES_ARTIST_ID)], " +
        "[\(ITUNES_ARTIST.ITUNES_ARTIST_PID)], " +
        "[\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)], " +
        "[\(ITUNES_ARTIST.ITUNES_SORT_NAME)], " +
        "[\(ITUNES_ARTIST.UPDATED)] "
    }
  }
  
  private func decode(sqliteDataReader:SqliteDataReader?) {
    
    if let reader = sqliteDataReader {
      
      artistId = reader.getInt(index: 0)!
      
      if !reader.isDBNull(index: 1) {
        artistPid = reader.getString(index: 1)!
      }
      
      if !reader.isDBNull(index: 2) {
        artistName = reader.getString(index: 2)!
      }
      
      if !reader.isDBNull(index: 3) {
        sortName = reader.getString(index: 3)!
      }
      
      if !reader.isDBNull(index: 4) {
        updated = reader.getInt(index: 4)!
      }
      
      newRow = false;
    }
    
    Modified = false
    
  }

}
