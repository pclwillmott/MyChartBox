//
//  iTunesTrack.swift
//  MyChartBox
//
//  Created by Paul Willmott on 25/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import iTunesLibrary

public class iTunesTrackX : NSObject {

  private var _trackId     : Int = -1
  private var _trackPid    : String = ""
  private var _trackTitle  : String = ""
  private var _artistId    : Int = -1
  private var _location    : String = ""
  private var _totalTime   : Int = 0
  private var _updated     : Int?
  private var _modified    : Bool = false
  private var _volume      : Double = baseVolume
  private var _albumId     : Int = -1
  private var _trackNumber : Int = -1
  public var  _newRow      : Bool = true
  private var _musicPid    : Int = 0;
  
  public var updated : Int? {
    get {
      return _updated
    }
    set(value) {
      _updated = value
      Modified = true
    }
  }
  
  public var volume : Float {
    get {
      return Float(_volume)
    }
    set(value) {
      let d = Double(value)
      if _volume != d {
        _volume = d
        Modified = true
      }
    }
  }
  
  public var albumId : Int {
    get {
      return _albumId
    }
    set(value) {
      if _albumId != value {
        _albumId = value
        Modified = true
      }
    }
  }
  
  public var musicPid : Int {
    get {
      return _musicPid
    }
    set(value) {
      if _musicPid != value {
        _musicPid = value
        Modified = true
      }
    }
  }
  
  public var trackNumber : Int {
    get {
      return _trackNumber
    }
    set(value) {
      if _trackNumber != value {
        _trackNumber = value
        Modified = true
      }
    }
  }

  @objc dynamic public var trackId : Int {
    get {
      return _trackId
    }
    set(value) {
      if value != _trackId {
        willChangeValue(forKey: "trackId")
        _trackId = value
        didChangeValue(forKey: "trackId")
        Modified = true
      }
    }
  }
  
  public var fileType : String {
    get {
      return location.fileExtension()
    }
  }
  
  public var timeAsString : String {
    get {
      return timeString(milliseconds:totalTime)
    }
  }
  
  @objc dynamic public var trackPid : String {
    get {
      return _trackPid
    }
    set(value) {
      if value != _trackPid {
        willChangeValue(forKey: "trackPid")
        _trackPid = value
        didChangeValue(forKey: "trackPid")
        Modified = true
      }
    }
  }
  @objc dynamic public var trackTitle : String {
    get {
      return _trackTitle
    }
    set(value) {
      if value != _trackTitle {
        willChangeValue(forKey: "trackTitle")
        _trackTitle = value
        didChangeValue(forKey: "trackTitle")
        Modified = true
      }
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
  
  @objc dynamic public var location : String {
    get {
      return _location
    }
    set(value) {
      if value != _location {
        willChangeValue(forKey: "location")
        _location = value
        didChangeValue(forKey: "location")
        Modified = true
      }
    }
  }
  
  @objc dynamic public var totalTime : Int {
    get {
      return _totalTime
    }
    set(value) {
      if value != _totalTime {
        willChangeValue(forKey: "totalTime")
        _totalTime = value
        didChangeValue(forKey: "totalTime")
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
  
  init?(trackTitle:String, artistId:Int) {
    
    super.init()
    
    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT " + iTunesTrackX.ColumnNames + " FROM [\(TABLE.ITUNES_TRACK)] " +
    "WHERE UPPER([\(ITUNES_TRACK.ITUNES_TITLE)]) = @\(ITUNES_TRACK.ITUNES_TITLE) AND " +
    "[\(ITUNES_TRACK.ITUNES_ARTIST_ID)] = @\(ITUNES_TRACK.ITUNES_ARTIST_ID)"
    
    cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.ITUNES_TITLE)", value: trackTitle)
    cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.ITUNES_ARTIST_ID)", value: artistId)

    if let reader = cmd.executeReader() {
         
      if reader.read() {
        decode(sqliteDataReader: reader)
      }
         
      reader.close()
         
    }
    
    if shouldClose {
      conn.close()
    }
    
    if (trackId == -1) {
      return nil
    }

  }

  init(item:ITLibMediaItem) {
    super.init()
    trackPid = "\(item.persistentID)"
    musicPid = Int(truncating: item.persistentID)
    if !load(pid: trackPid) {
      updated = 1
    }
    if let artist = item.artist {
      let artistObj = iTunesArtistX(artist: artist)
      artistId = artistObj.artistId
    }
    trackTitle = item.title
    if let loc = item.location {
      location = loc.absoluteString
    }
    totalTime = item.totalTime
    trackNumber = item.trackNumber
    let albumObj = iTunesAlbum(album: item.album)
    albumId = albumObj.albumId
    Save()
  }
  
  public var albumInfo : String {
    get {
      if let album = iTunesAlbum(albumID: albumId) {
        var discInfo = ""
        if album.discCount > 1 {
          discInfo = " Disc \(album.discNumber) of \(album.discCount) "
        }
        return "\(album.albumName) -\(discInfo) Track \(trackNumber)"
      }
      return ""
    }
  }
  
  init?(trackid:Int) {
    
    super.init()
    
    let conn = Database.getConnection()
     
     let shouldClose = conn.state != .Open
      
     if shouldClose {
        _ = conn.open()
     }
      
     let cmd = conn.createCommand()
      
     cmd.commandText = "SELECT " + iTunesTrackX.ColumnNames + " FROM [\(TABLE.ITUNES_TRACK)] " +
    "WHERE [\(ITUNES_TRACK.ITUNES_TRACK_ID)] = @\(ITUNES_TRACK.ITUNES_TRACK_ID)"
     
     cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.ITUNES_TRACK_ID)", value: trackid)

     if let reader = cmd.executeReader() {
          
       if reader.read() {
         decode(sqliteDataReader: reader)
       }
          
       reader.close()
          
     }
     
     if shouldClose {
       conn.close()
     }
    
    if trackId == -1 {
      return nil
    }

  }

  private func load(pid:String) -> Bool {
    
    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT " + iTunesTrackX.ColumnNames + " FROM [\(TABLE.ITUNES_TRACK)] " +
    "WHERE [\(ITUNES_TRACK.ITUNES_TRACK_PID)] = @\(ITUNES_TRACK.ITUNES_TRACK_PID)"
    
    cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.ITUNES_TRACK_PID)", value: pid)

    if let reader = cmd.executeReader() {
         
      if reader.read() {
        decode(sqliteDataReader: reader)
      }
         
      reader.close()
         
    }
    
    if shouldClose {
      conn.close()
    }
    
    return !_newRow

  }
  
  public func Save() {
    
    if Modified {
      
      var sql = ""
      
      if _newRow {
        sql = "INSERT INTO [\(TABLE.ITUNES_TRACK)] (" +
          "[\(ITUNES_TRACK.ITUNES_TRACK_ID)], " +
          "[\(ITUNES_TRACK.ITUNES_TRACK_PID)], " +
          "[\(ITUNES_TRACK.ITUNES_ARTIST_ID)], " +
          "[\(ITUNES_TRACK.ITUNES_TITLE)], " +
          "[\(ITUNES_TRACK.LOCATION)], " +
          "[\(ITUNES_TRACK.TOTAL_TIME)], " +
          "[\(ITUNES_TRACK.UPDATED)], " +
          "[\(ITUNES_TRACK.VOLUME_ADJUSTMENT)], " +
          "[\(ITUNES_TRACK.ITUNES_ALBUM_ID)], " +
          "[\(ITUNES_TRACK.ITUNES_TRACK_NUMBER)], " +
          "[\(ITUNES_TRACK.MUSIC_PID)] " +
        ") VALUES (" +
          "@\(ITUNES_TRACK.ITUNES_TRACK_ID), " +
          "@\(ITUNES_TRACK.ITUNES_TRACK_PID), " +
          "@\(ITUNES_TRACK.ITUNES_ARTIST_ID), " +
          "@\(ITUNES_TRACK.ITUNES_TITLE), " +
          "@\(ITUNES_TRACK.LOCATION), " +
          "@\(ITUNES_TRACK.TOTAL_TIME), " +
          "@\(ITUNES_TRACK.UPDATED), " +
          "@\(ITUNES_TRACK.VOLUME_ADJUSTMENT), " +
          "@\(ITUNES_TRACK.ITUNES_ALBUM_ID), " +
          "@\(ITUNES_TRACK.ITUNES_TRACK_NUMBER), " +
          "@\(ITUNES_TRACK.MUSIC_PID) " +
        ")"
        trackId = Database.nextCode(tableName: TABLE.ITUNES_TRACK, primaryKey: ITUNES_TRACK.ITUNES_TRACK_ID)!
      }
      else {
        sql = "UPDATE [\(TABLE.ITUNES_TRACK)] SET " +
          "[\(ITUNES_TRACK.ITUNES_TRACK_PID)] = @\(ITUNES_TRACK.ITUNES_TRACK_PID), " +
          "[\(ITUNES_TRACK.ITUNES_ARTIST_ID)] = @\(ITUNES_TRACK.ITUNES_ARTIST_ID), " +
          "[\(ITUNES_TRACK.ITUNES_TITLE)] = @\(ITUNES_TRACK.ITUNES_TITLE), " +
          "[\(ITUNES_TRACK.LOCATION)] = @\(ITUNES_TRACK.LOCATION), " +
          "[\(ITUNES_TRACK.TOTAL_TIME)] = @\(ITUNES_TRACK.TOTAL_TIME), " +
          "[\(ITUNES_TRACK.UPDATED)] = @\(ITUNES_TRACK.UPDATED), " +
          "[\(ITUNES_TRACK.VOLUME_ADJUSTMENT)] = @\(ITUNES_TRACK.VOLUME_ADJUSTMENT), " +
          "[\(ITUNES_TRACK.ITUNES_ALBUM_ID)] = @\(ITUNES_TRACK.ITUNES_ALBUM_ID), " +
          "[\(ITUNES_TRACK.ITUNES_TRACK_NUMBER)] = @\(ITUNES_TRACK.ITUNES_TRACK_NUMBER), " +
          "[\(ITUNES_TRACK.MUSIC_PID)] = @\(ITUNES_TRACK.MUSIC_PID) " +
        "WHERE [\(ITUNES_TRACK.ITUNES_TRACK_ID)] = @\(ITUNES_TRACK.ITUNES_TRACK_ID)"
      }

      let conn = Database.getConnection()
      
      let shouldClose = conn.state != .Open
       
      if shouldClose {
         _ = conn.open()
      }
       
      let cmd = conn.createCommand()
       
      cmd.commandText = sql
      
      cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.ITUNES_TRACK_ID)", value: trackId)
      cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.ITUNES_TRACK_PID)", value: trackPid)
      cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.ITUNES_ARTIST_ID)", value: artistId)
      cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.ITUNES_TITLE)", value: trackTitle)
      cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.LOCATION)", value: location)
      cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.TOTAL_TIME)", value: totalTime)
      cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.UPDATED)", value: updated)
      cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.VOLUME_ADJUSTMENT)", value: _volume)
      cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.ITUNES_ALBUM_ID)", value: albumId)
      cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.ITUNES_TRACK_NUMBER)", value: trackNumber)
      cmd.parameters.addWithValue(key: "@\(ITUNES_TRACK.MUSIC_PID)", value: musicPid)

      _ = cmd.executeNonQuery()

      if shouldClose {
        conn.close()
      }
      
      Modified = false
      
      _newRow = false;

    }

  }

  public static var ColumnNames : String {
    get {
      return
        "[\(ITUNES_TRACK.ITUNES_TRACK_ID)], " +
        "[\(ITUNES_TRACK.ITUNES_TRACK_PID)], " +
        "[\(ITUNES_TRACK.ITUNES_ARTIST_ID)], " +
        "[\(ITUNES_TRACK.ITUNES_TITLE)], " +
        "[\(ITUNES_TRACK.LOCATION)], " +
        "[\(ITUNES_TRACK.TOTAL_TIME)], " +
        "[\(ITUNES_TRACK.UPDATED)], " +
        "[\(ITUNES_TRACK.VOLUME_ADJUSTMENT)], " +
        "[\(ITUNES_TRACK.ITUNES_ALBUM_ID)], " +
        "[\(ITUNES_TRACK.ITUNES_TRACK_NUMBER)], " +
        "[\(ITUNES_TRACK.MUSIC_PID)]"
    }
  }
  
  private func decode(sqliteDataReader:SqliteDataReader?) {
    
    if let reader = sqliteDataReader {
      
      trackId = reader.getInt(index: 0)!
      
      if !reader.isDBNull(index: 1) {
        trackPid = reader.getString(index: 1)!
      }
      if !reader.isDBNull(index: 2) {
        artistId = reader.getInt(index: 2)!
      }
      
      if !reader.isDBNull(index: 3) {
        trackTitle = reader.getString(index: 3)!
      }
      
      if !reader.isDBNull(index: 4) {
        location = reader.getString(index: 4)!
      }
      
      if !reader.isDBNull(index: 5) {
        totalTime = reader.getInt(index: 5)!
      }
      
      if !reader.isDBNull(index: 6) {
        updated = reader.getInt(index: 6)!
      }
      
      if !reader.isDBNull(index: 7) {
        _volume = reader.getDouble(index: 7)!
      }
      
      if !reader.isDBNull(index: 8) {
        albumId = reader.getInt(index: 8)!
      }
      
      if !reader.isDBNull(index: 9) {
        trackNumber = reader.getInt(index: 9)!
      }
      
      if !reader.isDBNull(index: 10) {
        musicPid = reader.getInt(index: 10)!
      }
      
      _newRow = false;
    }
    
    Modified = false
    
  }
  
}
