//
//  TrackTableViewDS.swift
//  MyChartBox
//
//  Created by Paul Willmott on 04/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa
import iTunesLibrary

public class TrackTableViewDS : NSObject, NSTableViewDataSource, NSTableViewDelegate {

  public func getRowIndex(trackId:Int) -> Int {
    var index = 0
    for track in tracks {
      if track.persistentID == trackId {
        return index
      }
      index += 1
    }
    return -1
  }

  public func getRowIndex(albumId:Int) -> Int {
    var index = 0
    for album in albums {
      if album.persistentID == albumId {
        return index
      }
      index += 1
    }
    return -1
  }

  fileprivate enum CellIdentifiers {
    static let TrackCell    = "TrackCellID"
    static let TimeCell     = "TimeCellID"
  }

  public var tracks : [MusicTrack] = []

  public var albums : [MusicAlbum] = []
  
  // Returns the number of records managed for aTableView by the data source object.
   public func numberOfRows(in tableView: NSTableView) -> Int {
    if tracks.count > 0 {
      return tracks.count
    }
    return albums.count
   }
  
  // Sets the data object for an item in the specified row and column.
  public func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
  }
  
  public func tableView(_ tableView: NSTableView,
                        viewFor tableColumn: NSTableColumn?,row: Int) -> NSView? {
    
    if tracks.count > 0 {
      
      let item = tracks[row]
      
      if tableColumn == tableView.tableColumns[0] {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TrackCellID"), owner: nil) as? NSTableCellView {
            
          cell.textField!.stringValue = item.mediaItem.title.uppercased()
          cell.textField?.font = NSFont(name: "Menlo", size: 11)

          return cell
        }
      }
      else if tableColumn == tableView.tableColumns[1] {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TimeCellID"), owner: nil) as? NSTableCellView {
            
          cell.textField?.stringValue = "\(item.timeAsString)"
          cell.textField?.font = NSFont(name: "Menlo", size: 11)

          return cell
        }
      }
      else if tableColumn == tableView.tableColumns[2] {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileTypeCellID"), owner: nil) as? NSTableCellView {
          
          cell.textField?.stringValue = "\(item.fileType)"
          cell.textField?.font = NSFont(name: "Menlo", size: 11)

          return cell
        }
      }
    }
    else {
      
      let item = albums[row]
      
      if tableColumn == tableView.tableColumns[0] {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TrackCellID"), owner: nil) as? NSTableCellView {
            
          cell.textField!.stringValue = item.title.uppercased()
          cell.textField?.font = NSFont(name: "Menlo", size: 11)

          return cell
        }
      }
      else if tableColumn == tableView.tableColumns[1] {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TimeCellID"), owner: nil) as? NSTableCellView {
            
          cell.textField?.stringValue = "\(item.timeAsString)"
          cell.textField?.font = NSFont(name: "Menlo", size: 11)

          return cell
        }
      }
      else if tableColumn == tableView.tableColumns[2] {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileTypeCellID"), owner: nil) as? NSTableCellView {
          
          cell.textField?.stringValue = "\(item.fileType)"
          cell.textField?.font = NSFont(name: "Menlo", size: 11)

          return cell
        }
      }
    }
    return nil
    
  }

}
