//
//  Sqlite.swift
//  MyChartBox
//
//  Created by Paul Willmott on 05/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import SQLite3

/*
 * Errors
 */

enum SqliteError : Error {
  case OpenFailed
}

enum SqliteConnectionState : Int {
  case Open
  case Closed
}

enum SqliteType : Int {
  case Integer
  case Float
  case Text
  case Blob
  case Null
}

/*
 * SqliteConnection
 */

class SqliteConnection {
  
  public var errorMessage : String = ""
  
  public var errorCode = SQLITE_OK
  
  public var connectionString : String
  
  var db: OpaquePointer? = nil
  
  public var state : SqliteConnectionState = .Closed
  
  init?(connectionString:String) {
    self.connectionString = connectionString;
    if self.connectionString.isEmpty {
      return nil
    }
  }
  
  public func close(){
    if (self.state == .Open) {
      sqlite3_close_v2(db)
      db = nil
      self.state = .Closed
    }
  }
  
  public func open() -> SqliteConnectionState {
    self.close()
    errorCode = sqlite3_open(connectionString.cString(using: String.Encoding.utf8), &db)
    errorMessage = String(cString: sqlite3_errmsg(db)!)
    if errorCode == SQLITE_OK {
      self.state = .Open
    }
    else {
      db = nil
    }
    return self.state
  }
  
  public func createCommand() -> SqliteCommand {
    return SqliteCommand(connection: self)
  }
  
}

class SqliteParameters {
  
  var parameters = [String:String]()
  
  public func addWithValue(key:String,value:Int?) {
    if !key.isEmpty && key.hasPrefix("@") {
      if let ivalue = value {
        self.parameters[key] = " \(ivalue) "
      }
      else {
        addWithNull(key: key)
      }
    }
  }
  
  public func addWithValue(key:String,value:String?) {
    if !key.isEmpty && key.hasPrefix("@") {
      if let svalue : String = value {
        var str = svalue
        str = String(str.prefix(str.count)).replacingOccurrences(of: "'", with: "''")
        self.parameters[key] = " '\(str)' "
      }
      else {
        addWithNull(key: key)
      }
    }
  }
  
  public func addWithValue(key:String, value:Double?) {
    if !key.isEmpty && key.hasPrefix("@") {
      if let dvalue = value {
        self.parameters[key] = " \(dvalue) "
      }
      else {
        addWithNull(key: key)
      }
    }
  }
  
  public func addWithNull(key:String) {
    if !key.isEmpty && key.hasPrefix("@") {
      self.parameters[key] = " NULL "
    }
  }
  
  func replaceParameters(target:String) -> String {
    var output : String = target
    for (key, value) in self.parameters {
      output = output.replacingOccurrences(of: key, with: value)
    }
    return output
  }
}

class SqliteCommand {
  
  public var errorMessage : String = ""
  
  public var errorCode = SQLITE_OK
  
  public var connection : SqliteConnection
  
  public var commandText : String = ""
  
  public var sqlText = ""
  
  public var parameters : SqliteParameters = SqliteParameters()
  
  init(connection:SqliteConnection) {
    self.connection = connection
  }
  
  public func executeNonQuery() -> Bool {
    sqlText = self.parameters.replaceParameters(target: commandText)
    errorCode = sqlite3_exec(connection.db, sqlText.cString(using: String.Encoding.utf8), nil, nil, nil)
    errorMessage = String(cString: sqlite3_errmsg(connection.db)!)
    if errorCode != SQLITE_OK {
      print(errorCode, errorMessage)
    }
    return errorCode == SQLITE_OK
  }
  
  public func executeReader() -> SqliteDataReader? {
    let reader = SqliteDataReader(command:self)
    sqlText = self.parameters.replaceParameters(target: commandText)
    errorCode = sqlite3_prepare_v2(connection.db, sqlText.cString(using: String.Encoding.utf8), -1, &reader.statement, nil)
    errorMessage = String(cString: sqlite3_errmsg(connection.db)!)
    if errorCode == SQLITE_OK {
      return reader
    }
    return nil
  }
  
}

class SqliteDataReader {
  
  public var errorMessage : String = ""
  
  public var errorCode = SQLITE_OK
  
  private var command : SqliteCommand
  
  var statement: OpaquePointer? = nil;
  
  init(command:SqliteCommand){
    self.command = command
  }
  
  public func close(){
    if self.statement != nil {
      sqlite3_finalize(self.statement)
      self.statement = nil
    }
  }
  
  public func fieldCount() -> Int {
    return (Int) (sqlite3_column_count(statement))
  }
  
  public func isClosed() -> Bool {
    return statement == nil
  }
  
  public func read() -> Bool {
    errorCode = sqlite3_step(statement)
    errorMessage = String(cString: sqlite3_errmsg(command.connection.db)!)
    if errorCode == SQLITE_ROW {
      return true
    }
    else if errorCode == SQLITE_DONE {
      return false
    }
    return false
  }
  
  public func isDBNull(index:Int) -> Bool {
    return getFieldType(index: index) == .Null
  }
  
  public func getInt(index:Int) -> Int? {
    if isDBNull(index: index){
      return nil;
    }
    return (Int) (sqlite3_column_int64(statement, (Int32)(index)))
  }
  
  public func getDouble(index:Int) -> Double? {
    if isDBNull(index: index){
      return nil;
    }
    return sqlite3_column_double(statement, (Int32)(index))
  }
  
  public func getString(index:Int) -> String? {
    if isDBNull(index: index){
      return nil;
    }
    let cString = sqlite3_column_text(statement, (Int32)(index))
    return String(cString: cString!)
  }
  
  public func getFieldName(index:Int) -> String {
    var s : String = ""
    if let alias = sqlite3_column_name(statement, (Int32)(index)) {
      s = String(cString:alias)
    }
    return s
  }
  
  public func getFieldType(index:Int) -> SqliteType {
    switch sqlite3_column_type(statement, (Int32)(index)) {
    case SQLITE_INTEGER:
      return .Integer
    case SQLITE_FLOAT:
      return .Float
    case SQLITE_TEXT:
      return .Text
    case SQLITE_BLOB:
      return .Blob
    default:
      return .Null
    }
  }
  
}

