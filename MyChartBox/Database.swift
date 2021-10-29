//
//  Database.swift
//  MyChartBox
//
//  Created by Paul Willmott on 11/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation

class Database {
  
  public static var __number : Int = 0
  
  public static var Version : Int = 0
  
  private static var connection : SqliteConnection? = nil
  
  public static func getConnection() -> SqliteConnection {
    
    if (connection == nil) {

      /*
       * Create MyChartBox directory.
       */
      
      if let databasePath = UserDefaults.standard.string(forKey: DEFAULT.DATABASE_PATH) {
      
        var url = URL(fileURLWithPath: databasePath)
        
        let fm = FileManager()
        
        do{
          try fm.createDirectory(at: url, withIntermediateDirectories:true, attributes:nil)
        }
        catch{
          print("create directory failed")
        }
        
        /*
         * Create database connection.
         */
        
        url.appendPathComponent("MyChartBox.db3")
        
        let newfile = !fm.fileExists(atPath: url.path)
        
        connection = SqliteConnection(connectionString: url.absoluteString)
        
        if newfile {
          
          let commands = [
            
            "CREATE TABLE [\(TABLE.VERSION)] (" +
              "[\(VERSION.VERSION_ID)]     INTEGER PRIMARY KEY," +
              "[\(VERSION.VERSION_NUMBER)] INT" +
            ")",
            
            "INSERT INTO [\(TABLE.VERSION)] ([\(VERSION.VERSION_ID)], [\(VERSION.VERSION_NUMBER)]) VALUES " +
            "(1, 1)",
 
            "CREATE TABLE [\(TABLE.ARTIST)] (" +
              "[\(ARTIST.ARTIST_ID)]    INT PRIMARY KEY," +
              "[\(ARTIST.UKCHART_NAME)] TEXT," +
              "[\(ARTIST.ARTIST_NAME)]  TEXT," +
              "[\(ARTIST.SORT_NAME)]    TEXT" +
            ")",
 
            "CREATE INDEX IDX_ARTIST_UKCHART_NAME ON [\(TABLE.ARTIST)] ([\(ARTIST.UKCHART_NAME)])",
            
            "CREATE TABLE [\(TABLE.LABEL)] (" +
              "[\(LABEL.LABEL_ID)]        INT PRIMARY KEY," +
              "[\(LABEL.UKCHART_NAME)]    TEXT NOT NULL" +
            ")",
            
            "CREATE INDEX IDX_LABEL_UKCHART_NAME ON [\(TABLE.LABEL)] ([\(LABEL.UKCHART_NAME)])",
            
            "CREATE TABLE [\(TABLE.CHART)] (" +
              "[\(CHART.CHART_ID)]        INT PRIMARY KEY," +
              "[\(CHART.UKCHART_ID)]      TEXT," +
              "[\(CHART.CHART_NAME)]      TEXT" +
            ")",
            
            "INSERT INTO [\(TABLE.CHART)] ([\(CHART.CHART_ID)], [\(CHART.CHART_NAME)], [\(CHART.UKCHART_ID)]) VALUES " +
                       "(1, 'UK Singles Chart', '7501')",
            
            "INSERT INTO [\(TABLE.CHART)] ([\(CHART.CHART_ID)], [\(CHART.CHART_NAME)], [\(CHART.UKCHART_ID)]) VALUES " +
                       "(2, 'UK Albums Chart', '7502')",
            
            "CREATE TABLE [\(TABLE.CHART_LISTING)] (" +
              "[\(CHART_LISTING.CHART_LISTING_ID)] INT PRIMARY KEY," +
              "[\(CHART_LISTING.ARTIST_ID)]        INT," +
              "[\(CHART_LISTING.CHART_ID)]         INT," +
              "[\(CHART_LISTING.CATALOGUE_NUMBER)] TEXT," +
              "[\(CHART_LISTING.UKCHART_TITLE)]    TEXT," +
              "[\(CHART_LISTING.LABEL_ID)]         INT," +
              "[\(CHART_LISTING.PRODUCT_TYPE)]     TEXT" +
            ")",

            "CREATE TABLE [\(TABLE.CHART_ENTRY)] (" +
              "[\(CHART_ENTRY.CHART_ENTRY_ID)]   INT PRIMARY KEY," +
              "[\(CHART_ENTRY.CHART_DATE)]       TEXT," +
              "[\(CHART_ENTRY.CHART_LISTING_ID)] INT," +
              "[\(CHART_ENTRY.POSITION)]         TEXT," +
              "[\(CHART_ENTRY.LAST_POSITION)]    TEXT," +
              "[\(CHART_ENTRY.HIGHEST_POSITION)] TEXT," +
              "[\(CHART_ENTRY.WEEKS_ON_CHART)]   TEXT" +
            ")",
            
          ]
          
          execute(commands: commands)
          
        }
        
        /*
         * Get version information.
         */

        if connection!.open() == .Open {
          
          let cmd = connection!.createCommand()
          
          cmd.commandText =
          "SELECT [\(VERSION.VERSION_NUMBER)] FROM [\(TABLE.VERSION)] WHERE [\(VERSION.VERSION_ID)] = 1"
          
          if let reader = cmd.executeReader() {
            
            if reader.read() {
              Version = reader.getInt(index: 0)!
            }
            
            reader.close()
            
            connection!.close()
            
          }
          
          if Version == 1 {
            Version = 2
          }
          
          print("Version: \(Version)");
          
          if Version == 2 {
            
            let commands = [
              
         //     "DROP TABLE IF EXISTS [\(TABLE.ITUNES_ARTIST)] ",
               /*
              "CREATE TABLE [\(TABLE.ITUNES_ARTIST)] (" +
                "[\(ITUNES_ARTIST.ITUNES_ARTIST_ID)]   INTEGER PRIMARY KEY," +
                "[\(ITUNES_ARTIST.ITUNES_ARTIST_PID)]  TEXT," +
                "[\(ITUNES_ARTIST.ITUNES_ARTIST_NAME)] TEXT," +
                "[\(ITUNES_ARTIST.ITUNES_SORT_NAME)]   TEXT," +
                "[\(ITUNES_ARTIST.UPDATED)]            INT" +
              ")",
              */
       //       "DROP TABLE IF EXISTS [\(TABLE.ITUNES_TRACK)]",
/*
              "CREATE TABLE [\(TABLE.ITUNES_TRACK)] (" +
                "[\(ITUNES_TRACK.ITUNES_TRACK_ID)]   INTEGER PRIMARY KEY," +
                "[\(ITUNES_TRACK.ITUNES_TRACK_PID)]  TEXT," +
                "[\(ITUNES_TRACK.ITUNES_ARTIST_ID)]  INT," +
                "[\(ITUNES_TRACK.ITUNES_TITLE)]      TEXT," +
                "[\(ITUNES_TRACK.LOCATION)]          TEXT," +
                "[\(ITUNES_TRACK.TOTAL_TIME)]        INT," +
                "[\(ITUNES_TRACK.UPDATED)]           INT," +
                "[\(ITUNES_TRACK.VOLUME_ADJUSTMENT)] FLOAT" +
              ")",
*/
              "CREATE TABLE [\(TABLE.TRACK_OVERRIDE)] (" +
                "[\(TRACK_OVERRIDE.TRACK_OVERRIDE_ID)] INTEGER PRIMARY KEY," +
                "[\(TRACK_OVERRIDE.CHART_LISTING_ID)]  INT," +
                "[\(TRACK_OVERRIDE.SIDE_INDEX)]        INT," +
                "[\(TRACK_OVERRIDE.ITUNES_TRACK_ID)]   INT" +
              ")",
              
              "UPDATE [\(TABLE.VERSION)] " +
              "SET [\(VERSION.VERSION_NUMBER)] = 3 " +
              "WHERE [\(VERSION.VERSION_ID)] = 1",
                       
            ]
            
            execute(commands: commands)
            
            Version = 3
                     
          }
          
          if Version == 3 {
            
            let commands = [
              
              "DROP TABLE IF EXISTS [\(TABLE.COLLECTION)] ",
                       
              "CREATE TABLE [\(TABLE.COLLECTION)] (" +
                "[\(COLLECTION.COLLECTION_ID)]   INTEGER PRIMARY KEY," +
                "[\(COLLECTION.COLLECTION_NAME)] TEXT," +
                "[\(COLLECTION.SORT_NAME)]       TEXT," +
                "[\(COLLECTION.LINKS)]           TEXT" +
              ")",
              
              "UPDATE [\(TABLE.VERSION)] " +
              "SET [\(VERSION.VERSION_NUMBER)] = 4 " +
              "WHERE [\(VERSION.VERSION_ID)] = 1",
                       
            ]
            
            execute(commands: commands)
            
            Version = 4
                     
          }
          
          if Version == 4 {
            
            let commands = [
              
          //    "DROP TABLE IF EXISTS [\(TABLE.ITUNES_ALBUM)] ",
              /*
              "CREATE TABLE [\(TABLE.ITUNES_ALBUM)] (" +
                "[\(ITUNES_ALBUM.ITUNES_ALBUM_ID)]    INTEGER PRIMARY KEY," +
                "[\(ITUNES_ALBUM.ITUNES_ALBUM_PID)]   TEXT," +
                "[\(ITUNES_ALBUM.ITUNES_ALBUM_NAME)]  TEXT," +
                "[\(ITUNES_ALBUM.ITUNES_DISC_COUNT)]  INT," +
                "[\(ITUNES_ALBUM.ITUNES_DISC_NUMBER)] INT," +
                "[\(ITUNES_ALBUM.UPDATED)]            INT" +
              ")",
 */
   /*
              "ALTER TABLE [\(TABLE.ITUNES_TRACK)] " +
              "ADD COLUMN [\(ITUNES_TRACK.ITUNES_ALBUM_ID)] INT",
              
              "ALTER TABLE [\(TABLE.ITUNES_TRACK)] " +
              "ADD COLUMN [\(ITUNES_TRACK.ITUNES_TRACK_NUMBER)] INT",
    */
              "UPDATE [\(TABLE.VERSION)] " +
              "SET [\(VERSION.VERSION_NUMBER)] = 5 " +
              "WHERE [\(VERSION.VERSION_ID)] = 1",
                       
            ]
            
            execute(commands: commands)
            
            Version = 5
                     
          }
            
          if Version == 5 {
            
            let commands = [
                         
              "ALTER TABLE [\(TABLE.TRACK_OVERRIDE)] " +
              "ADD COLUMN [\(TRACK_OVERRIDE.NOT_THIS_TRACK)] INT",
                         
              "UPDATE [\(TABLE.VERSION)] " +
              "SET [\(VERSION.VERSION_NUMBER)] = 6 " +
              "WHERE [\(VERSION.VERSION_ID)] = 1",
                                  
            ]
                       
            execute(commands: commands)
            
            Version = 6
            
          }
          
          if Version == 6 {
            
            let commands = [
              
              "DROP TABLE IF EXISTS [\(TABLE.PLAY_COUNT)] ",
                       
              "CREATE TABLE [\(TABLE.PLAY_COUNT)] (" +
                "[\(PLAY_COUNT.YEAR_NUMBER)] INTEGER PRIMARY KEY," +
                "[\(PLAY_COUNT.PLAY_COUNT)]  INT" +
              ")",
              
              "UPDATE [\(TABLE.VERSION)] " +
              "SET [\(VERSION.VERSION_NUMBER)] = 7 " +
              "WHERE [\(VERSION.VERSION_ID)] = 1",
                       
            ]
            
            execute(commands: commands)
            
            Version = 7
                     
          }

          if Version == 7 {
            
            let commands = [
          /*
              "ALTER TABLE [\(TABLE.ITUNES_TRACK)] " +
              "ADD COLUMN [\(ITUNES_TRACK.MUSIC_PID)] INT",
              
              "UPDATE [\(TABLE.ITUNES_TRACK)] " +
              "SET [\(ITUNES_TRACK.MUSIC_PID)] = CAST([\(ITUNES_TRACK.ITUNES_TRACK_PID)] AS INTEGER) " +
              "WHERE [\(ITUNES_TRACK.ITUNES_TRACK_PID)] IS NOT NULL",
*/
              "ALTER TABLE [\(TABLE.TRACK_OVERRIDE)] " +
              "ADD COLUMN [\(TRACK_OVERRIDE.MUSIC_PID)] INT",
              
              "UPDATE [\(TABLE.VERSION)] " +
              "SET [\(VERSION.VERSION_NUMBER)] = 8 " +
              "WHERE [\(VERSION.VERSION_ID)] = 1",
                       
            ]
            
            execute(commands: commands)
            
            Version = 8
                     
          }

          if Version == 8 {
            
            let commands = [
              /*
              "UPDATE [\(TABLE.TRACK_OVERRIDE)] AS T1 " +
              "SET [\(TRACK_OVERRIDE.MUSIC_PID)] = " +
              "(SELECT T2.[\(ITUNES_TRACK.MUSIC_PID)] FROM [\(TABLE.ITUNES_TRACK)] AS T2 " +
              "WHERE T2.[\(ITUNES_TRACK.ITUNES_TRACK_ID)] = T1.[\(TRACK_OVERRIDE.ITUNES_TRACK_ID)] AND " +
              "T2.[\(ITUNES_TRACK.ITUNES_TRACK_PID)] IS NOT NULL LIMIT 1)",
*/
              "DROP TABLE IF EXISTS [\(TABLE.MUSIC_TRACK)] ",
              
              "CREATE TABLE [\(TABLE.MUSIC_TRACK)] (" +
                "[\(MUSIC_TRACK.MUSIC_PID)] INTEGER PRIMARY KEY," +
                "[\(MUSIC_TRACK.VOLUME_ADJUSTMENT)] FLOAT" +
              ")",
              /*
              "INSERT INTO [\(TABLE.MUSIC_TRACK)] " +
              "SELECT [\(ITUNES_TRACK.MUSIC_PID)], [\(ITUNES_TRACK.VOLUME_ADJUSTMENT)] " +
              "FROM [\(TABLE.ITUNES_TRACK)]",
              */
              "UPDATE [\(TABLE.VERSION)] " +
              "SET [\(VERSION.VERSION_NUMBER)] = 9 " +
              "WHERE [\(VERSION.VERSION_ID)] = 1",

            ]
            
            execute(commands: commands)
            
            Version = 9
                     
          }

          if Version == 9 {
            
            let commands = [
              
         //     "DROP TABLE IF EXISTS [\(TABLE.ITUNES_TRACK)] ",
              
         //     "DROP TABLE IF EXISTS [\(TABLE.ITUNES_ARTIST)] ",
              
         //     "DROP TABLE IF EXISTS [\(TABLE.ITUNES_ALBUM)] ",

              "UPDATE [\(TABLE.VERSION)] " +
              "SET [\(VERSION.VERSION_NUMBER)] = 10 " +
              "WHERE [\(VERSION.VERSION_ID)] = 1",

            ]
            
            execute(commands: commands)
            
            Version = 10
                     
          }

          if Version == 10 {
            
            let commands = [
              
              "DROP TABLE IF EXISTS [\(TABLE.MUSIC_TRACK)] ",
              
              "CREATE TABLE [\(TABLE.MUSIC_TRACK)] (" +
                "[\(MUSIC_TRACK.MUSIC_PID)] INTEGER PRIMARY KEY," +
                "[\(MUSIC_TRACK.VOLUME_ADJUSTMENT)] FLOAT" +
              ")",
              
              "UPDATE [\(TABLE.VERSION)] " +
              "SET [\(VERSION.VERSION_NUMBER)] = 11 " +
              "WHERE [\(VERSION.VERSION_ID)] = 1",

            ]
            
            execute(commands: commands)
            
            Version = 11
                     
          }

          if Version == 11 {
            
            let commands = [
              
              "ALTER TABLE [\(TABLE.CHART_ENTRY)] " +
              "ADD COLUMN [\(CHART_ENTRY.CHART_ID)] INT",

              "UPDATE [\(TABLE.CHART_ENTRY)] " +
              "SET [\(CHART_ENTRY.CHART_ID)] = 1 " +
              "WHERE [\(CHART_ENTRY.CHART_ID)] IS NULL",

              "UPDATE [\(TABLE.VERSION)] " +
              "SET [\(VERSION.VERSION_NUMBER)] = 12 " +
              "WHERE [\(VERSION.VERSION_ID)] = 1",

            ]
            
            execute(commands: commands)
 
            Version = 12
            
          }
          
          if Version == 12 {
            
            let commands = [
              
              "DELETE FROM [\(TABLE.CHART_ENTRY)] " +
              "WHERE [\(CHART_ENTRY.CHART_ID)] = 2",

              "DELETE FROM [\(TABLE.CHART_LISTING)] " +
              "WHERE [\(CHART_LISTING.CHART_ID)] = 2",

              "UPDATE [\(TABLE.VERSION)] " +
              "SET [\(VERSION.VERSION_NUMBER)] = 13 " +
              "WHERE [\(VERSION.VERSION_ID)] = 1",

            ]
            
            execute(commands: commands)
 
            Version = 13
            
          }
          
          if Version == 13 {
            
            let commands = [
              
              "DROP TABLE IF EXISTS [\(TABLE.ALBUM_PLAY_COUNT)] ",
                       
              "CREATE TABLE [\(TABLE.ALBUM_PLAY_COUNT)] (" +
                "[\(ALBUM_PLAY_COUNT.ALBUM_ID)]   INTEGER PRIMARY KEY," +
                "[\(ALBUM_PLAY_COUNT.PLAY_COUNT)] INT" +
              ")",
              
              "UPDATE [\(TABLE.VERSION)] " +
              "SET [\(VERSION.VERSION_NUMBER)] = 14 " +
              "WHERE [\(VERSION.VERSION_ID)] = 1",
                       
            ]
            
            execute(commands: commands)
            
            Version = 14
                     
          }
          
          if Version == 14 {
            
            let commands = [
 
              "ALTER TABLE [\(TABLE.PLAY_COUNT)] " +
              "ADD COLUMN [\(PLAY_COUNT.CHART_ID)] INT",

              "UPDATE [\(TABLE.PLAY_COUNT)] " +
              "SET [\(PLAY_COUNT.CHART_ID)] = 1",
              
              "UPDATE [\(TABLE.VERSION)] " +
              "SET [\(VERSION.VERSION_NUMBER)] = 15 " +
              "WHERE [\(VERSION.VERSION_ID)] = 1",
                       
            ]
            
            execute(commands: commands)
            
            Version = 15
                     
          }

       //   AlbumPlayCount.resetPlayCounts()
        }
        
      }
      
    }
    
    return connection!
    
  }
  
  public static func nextCode(tableName:String, primaryKey:String) -> Int? {
    
    let conn = Database.getConnection()
    var shouldClose = false
    
    if conn.state != .Open {
      if conn.open() != .Open {
        return nil
      }
      shouldClose = true
    }
    
    var code : Int = 0
    
    var _cmd : SqliteCommand? = conn.createCommand()
    
    if let cmd = _cmd {
      
      cmd.commandText = "SELECT MAX([\(primaryKey)]) AS MAX_KEY FROM [\(tableName)] "
      
      if let reader = cmd.executeReader() {
        
        if reader.read() {
          if let maxKey = reader.getInt(index: 0) {
            code = maxKey
          }
        }
        
        code += 1
        
        reader.close()
        
      }
      
      if code == 0 {
        code = 1
      }

    }
    
    _cmd = nil
    
    if shouldClose {
      conn.close()
    }
    
    return code

  }
  
  public static func execute(commands:[String]) {
    
    let conn = getConnection()
        
    let shouldClose = conn.state != .Open
         
    if shouldClose {
      _ = conn.open()
    }

    let cmd = conn.createCommand()
                    
    for sql in commands {
      cmd.commandText = sql
      let _ = cmd.executeNonQuery()
    }
                    
    if shouldClose {
      conn.close()
    }

  }
  
}
