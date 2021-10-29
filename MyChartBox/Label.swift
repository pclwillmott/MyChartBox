//
//  Label.swift
//  MyChartBox
//
//  Created by Paul Willmott on 12/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation

public class Label : NSObject {
  
  private var _labelId    : Int = -1
  private var _ukChartName : String = ""
  private var _modified    : Bool = false
  
  @objc dynamic public var LabelId : Int {
    get {
      return _labelId
    }
    set(value) {
      if value != _labelId {
        willChangeValue(forKey: "labelId")
        _labelId = value
        didChangeValue(forKey: "labelId")
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
  
  init?(labelid:Int) {
    
    super.init()

    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT " + Label.ColumnNames + " FROM [\(TABLE.LABEL)] " +
    "WHERE [\(LABEL.LABEL_ID)] = @\(LABEL.LABEL_ID)"
    
    cmd.parameters.addWithValue(key: "@\(LABEL.LABEL_ID)", value: labelid)

    if let reader = cmd.executeReader() {
         
      if reader.read() {
        decode(sqliteDataReader: reader)
      }
         
      reader.close()
         
    }
    
    if shouldClose {
      conn.close()
    }

    if LabelId == -1 {
      return nil
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
     
    cmd.commandText = "SELECT " + Label.ColumnNames + " FROM [\(TABLE.LABEL)] " +
    "WHERE [\(LABEL.UKCHART_NAME)] = @\(LABEL.UKCHART_NAME)"
    
    cmd.parameters.addWithValue(key: "@\(LABEL.UKCHART_NAME)", value: ukChartName)

    if let reader = cmd.executeReader() {
         
      if reader.read() {
        decode(sqliteDataReader: reader)
      }
         
      reader.close()
         
    }
    
    if LabelId == -1 {
      UKChartName = ukChartName
      Save()
    }
       
    if shouldClose {
      conn.close()
    }

  }
  
  public func Save() {
    
    if Modified {
      
      var sql = ""
      
      if LabelId == -1 {
        sql = "INSERT INTO [\(TABLE.LABEL)] (" +
        "[\(LABEL.LABEL_ID)], " +
        "[\(LABEL.UKCHART_NAME)] " +
        ") VALUES (" +
        "@\(LABEL.LABEL_ID), " +
        "@\(LABEL.UKCHART_NAME) " +
        ")"
        LabelId = Database.nextCode(tableName: TABLE.LABEL, primaryKey: LABEL.LABEL_ID)!
      }
      else {
        sql = "UPDATE [\(TABLE.LABEL)] SET " +
        "[\(LABEL.UKCHART_NAME)] = @\(LABEL.UKCHART_NAME) " +
        "WHERE [\(LABEL.LABEL_ID)] = @\(LABEL.LABEL_ID)"
      }

      let conn = Database.getConnection()
      
      let shouldClose = conn.state != .Open
       
      if shouldClose {
         _ = conn.open()
      }
       
      let cmd = conn.createCommand()
       
      cmd.commandText = sql
      
      cmd.parameters.addWithValue(key: "@\(LABEL.LABEL_ID)", value: LabelId)
      cmd.parameters.addWithValue(key: "@\(LABEL.UKCHART_NAME)", value: UKChartName)
      
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
        "[\(LABEL.LABEL_ID)], " +
        "[\(LABEL.UKCHART_NAME)] "
    }
  }
  
  private func decode(sqliteDataReader:SqliteDataReader?) {
    
    if let reader = sqliteDataReader {
      
      LabelId = reader.getInt(index: 0)!
      
      if !reader.isDBNull(index: 1) {
        UKChartName = reader.getString(index: 1)!
      }

 //     print("Label.decode: \(LabelId), \(UKChartName)")

    }
    
    Modified = false
    
  }

}
