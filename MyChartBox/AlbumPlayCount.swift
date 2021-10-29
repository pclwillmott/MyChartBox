//
//  AlbumPlayCount.swift
//  MyChartBox
//
//  Created by Paul Willmott on 02/01/2021.
//  Copyright © 2021 Paul Willmott. All rights reserved.
//

import Foundation

class AlbumPlayCount : NSObject {
  
  public var albumId : Int = 0
  public var playCount : Int = 0
  
  init(albumId:Int) {
    
    super.init()
    
    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
    
    var newRow = true
    
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT [\(ALBUM_PLAY_COUNT.ALBUM_ID)], [\(ALBUM_PLAY_COUNT.PLAY_COUNT)] FROM [\(TABLE.ALBUM_PLAY_COUNT)] WHERE [\(ALBUM_PLAY_COUNT.ALBUM_ID)] = @\(ALBUM_PLAY_COUNT.ALBUM_ID)"
    
    cmd.parameters.addWithValue(key: "@\(ALBUM_PLAY_COUNT.ALBUM_ID)", value: albumId)
    
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
      
      cmd.commandText = "INSERT INTO [\(TABLE.ALBUM_PLAY_COUNT)] (" +
        "[\(ALBUM_PLAY_COUNT.ALBUM_ID)], [\(ALBUM_PLAY_COUNT.PLAY_COUNT)]" +
      ") VALUES (" +
        "@\(ALBUM_PLAY_COUNT.ALBUM_ID), @\(ALBUM_PLAY_COUNT.ALBUM_ID)" +
      ")"
      
      cmd.parameters.addWithValue(key: "@\(ALBUM_PLAY_COUNT.ALBUM_ID)", value: albumId)
      cmd.parameters.addWithValue(key: "@\(PLAY_COUNT.PLAY_COUNT)", value: 0)
      
      let _ = cmd.executeNonQuery()
      
    }
    
    if shouldClose {
      conn.close()
    }
    
    self.albumId = albumId

  }
  
  public static func resetPlayCounts() {

    let commands = [
      "UPDATE [\(TABLE.ALBUM_PLAY_COUNT)] SET [\(ALBUM_PLAY_COUNT.PLAY_COUNT)] = 0"
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
     
    cmd.commandText = "UPDATE [\(TABLE.ALBUM_PLAY_COUNT)] SET " +
      "[\(ALBUM_PLAY_COUNT.PLAY_COUNT)] = @\(ALBUM_PLAY_COUNT.PLAY_COUNT) " +
      "WHERE [\(ALBUM_PLAY_COUNT.ALBUM_ID)] = @\(ALBUM_PLAY_COUNT.ALBUM_ID)"
    
    self.playCount += 1
      
    cmd.parameters.addWithValue(key: "@\(ALBUM_PLAY_COUNT.ALBUM_ID)", value: self.albumId)
    cmd.parameters.addWithValue(key: "@\(ALBUM_PLAY_COUNT.PLAY_COUNT)", value: self.playCount)
      
    let _ = cmd.executeNonQuery()
      
    if shouldClose {
      conn.close()
    }

  }
  
  public static var ColumnNames : String {
    get {
      return "[\(ALBUM_PLAY_COUNT.ALBUM_ID)], [\(ALBUM_PLAY_COUNT.PLAY_COUNT)]"
    }
  }
    
}
