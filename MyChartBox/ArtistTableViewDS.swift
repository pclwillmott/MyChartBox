//
//  ArtistTableViewDS.swift
//  MyChartBox
//
//  Created by Paul Willmott on 04/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa
import iTunesLibrary

public class ArtistTableViewDS : NSObject, NSTableViewDataSource, NSTableViewDelegate {
  
  public var artists : [MusicArtist] = []
  
  public func getRowIndex(artistName:String) -> Int {
    var index = 0
    for artist in artists {
      if artist.normalizedName == artistName {
        return index
      }
      index += 1
    }
    return -1
  }

  // Returns the number of records managed for aTableView by the data source object.
  public func numberOfRows(in tableView: NSTableView) -> Int {
    return artists.count
  }
  
  // Sets the data object for an item in the specified row and column.
  public func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
  }
  
  public func tableView(_ tableView: NSTableView,
                        viewFor tableColumn: NSTableColumn?,row: Int) -> NSView? {
    
    let item = artists[row]

//    tableColumn?.width = 60
 
    if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ArtistCellID"), owner: nil) as? NSTableCellView {
      
      cell.textField?.stringValue = item.normalizedName
      cell.textField?.font = NSFont(name: "Menlo", size: 11)
      return cell
    }
  
    return nil
    
  }

}
