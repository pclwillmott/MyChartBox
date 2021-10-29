//
//  AlbumPlayerTableViewDS.swift
//  MyChartBox
//
//  Created by Paul Willmott on 28/12/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa

public class AlbumPlayerTableViewDS : NSObject, NSTableViewDataSource, NSTableViewDelegate {

  /*
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
*/
  /*
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
*/
  fileprivate enum CellIdentifiers {
    static let TrackCell      = "TrackCellID"
    static let TitleCell      = "TitleCellID"
    static let TimeCell       = "TimeCellID"
    static let BonusTrackCell = "BonusTrackCellID"
    static let LiveTrackCell = "LiveTrackCellID"
    static let DemoTrackCell = "DemoTrackCellID"
  }

  public var tracks : [MusicTrack] = []

  // Returns the number of records managed for aTableView by the data source object.
   public func numberOfRows(in tableView: NSTableView) -> Int {
     return tracks.count
   }
  
  // Sets the data object for an item in the specified row and column.
  public func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
  }
  
  public func tableView(_ tableView: NSTableView,
                        viewFor tableColumn: NSTableColumn?,row: Int) -> NSView? {
    
    if tracks.count > 0 {
      
      let item = tracks[row]
      
      let colour : NSColor = item.isOKToPlayInAlbumMode ? .black : .gray
      
      if tableColumn == tableView.tableColumns[0] {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TrackCellID"), owner: nil) as? NSTableCellView {
            
          cell.textField!.stringValue = item.trackSequenceNumberAsString
          cell.textField?.textColor = colour
   //       cell.textField?.font = NSFont(name: "Menlo", size: 11)

          return cell
        }
      }
      else if tableColumn == tableView.tableColumns[1] {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TitleCellID"), owner: nil) as? NSTableCellView {
          
          cell.textField?.stringValue = "\(item.title.uppercased())"
          cell.textField?.textColor = colour
   //       cell.textField?.font = NSFont(name: "Menlo", size: 11)

          return cell
        }
      }
      else if tableColumn == tableView.tableColumns[2] {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TimeCellID"), owner: nil) as? NSTableCellView {
            
          cell.textField?.stringValue = "\(item.timeAsString)"
          cell.textField?.alignment = .center
          cell.textField?.textColor = colour
          cell.textField?.font = NSFont(name: "Menlo", size: 12)

          return cell
        }
      }
      else if tableColumn == tableView.tableColumns[3] {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "BonusTrackCellID"), owner: nil) as? NSTableCellView {
            
          cell.textField?.stringValue = item.isBonusTrack ? "✓" : ""
          cell.textField?.alignment = .center
          cell.textField?.textColor = colour
    //      cell.textField?.font = NSFont(name: "Menlo", size: 11)

          return cell
        }
      }
      else if tableColumn == tableView.tableColumns[4] {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LiveTrackCellID"), owner: nil) as? NSTableCellView {
            
          cell.textField?.stringValue = item.isLive ? "✓" : ""
          cell.textField?.alignment = .center
          cell.textField?.textColor = colour
    //      cell.textField?.font = NSFont(name: "Menlo", size: 11)

          return cell
        }
      }
      else if tableColumn == tableView.tableColumns[5] {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DemoTrackCellID"), owner: nil) as? NSTableCellView {
            
          cell.textField?.stringValue = item.isDemo ? "✓" : ""
          cell.textField?.alignment = .center
          cell.textField?.textColor = colour
    //      cell.textField?.font = NSFont(name: "Menlo", size: 11)

          return cell
        }
      }
    }
    return nil
    
  }

}
