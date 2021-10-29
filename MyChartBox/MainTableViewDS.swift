//
//  MainTableViewDS.swift
//  MyChartBox
//
//  Created by Paul Willmott on 02/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa

public class MainTableViewDS : NSObject, NSTableViewDataSource, NSTableViewDelegate {
  
  public var chartEntries = [ChartEntry]()

  fileprivate enum CellIdentifiers {
    static let PositionCell = "PositionCellID"
    static let PreviousCell = "PreviousCellID"
    static let ArtistCell   = "ArtistCellID"
    static let SongCell     = "SongCellID"
    static let PeakPosCell  = "PeakPosCellID"
    static let WOCCell      = "WOCCellID"
    static let OverrideCell = "OverrideCellID"
  }
  
  // Returns the number of records managed for aTableView by the data source object.
   public func numberOfRows(in tableView: NSTableView) -> Int {
     return chartEntries.count
   }
  
  // Sets the data object for an item in the specified row and column.
  public func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
  }
  
  public func tableView(_ tableView: NSTableView,
                        viewFor tableColumn: NSTableColumn?,row: Int) -> NSView? {
    
    var text: String = ""
    var cellIdentifier: String = ""

    let item = chartEntries[row]

    let isSinglesMode = item.chartListing.ProductType == "SINGLE"
    
    if tableColumn == tableView.tableColumns[0] {
      text = item.Position
      cellIdentifier = CellIdentifiers.PositionCell
      tableColumn?.width = 60
    }
    else if tableColumn == tableView.tableColumns[1] {
      text = item.LastPosition
      cellIdentifier = CellIdentifiers.PreviousCell
      tableColumn?.width = 80
    }
    else if tableColumn == tableView.tableColumns[2] {
      text = item.chartListing.ArtistObj.ArtistName
      cellIdentifier = CellIdentifiers.ArtistCell
      tableColumn?.width = 300
    }
    else if tableColumn == tableView.tableColumns[3] {
      if isSinglesMode {
        text = item.chartListing.sides[item.Index].UKChartTitle
      }
      else {
        text = item.chartListing.UKChartTitle
      }
      cellIdentifier = CellIdentifiers.SongCell
      tableColumn?.width = 300
    }
    else if tableColumn == tableView.tableColumns[4] {
      text = item.HighestPosition
      cellIdentifier = CellIdentifiers.PeakPosCell
      tableColumn?.width = 60
    }
    else if tableColumn == tableView.tableColumns[5] {
      text = item.WeeksOnChart
      cellIdentifier = CellIdentifiers.WOCCell
      tableColumn?.width = 80
    }
    else if tableColumn == tableView.tableColumns[6] {
      text = item.WeeksOnChart
      cellIdentifier = CellIdentifiers.OverrideCell
      tableColumn?.width = 100
    }

    if cellIdentifier == CellIdentifiers.OverrideCell {
      if let cell = tableView.makeView(withIdentifier:
      NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSButton {
       
        if isSinglesMode {
          if item.bestTrack == nil {
            cell.title = "Find"
          }
          else {
            cell.title = "Change"
          }
        }
        else {
          if item.bestAlbum == nil {
            cell.title = "Find"
          }
          else {
            cell.title = "Change"
          }
        }
        cell.tag = row
      //  cell.textField?.font = NSFont(name: "Menlo", size: 11)
       
       return cell
      }
    }
    else if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
      
      cell.textField?.stringValue = text
  //    cell.textField?.font = NSFont(name: "Menlo", size: 11)
      
      return cell
      
    }
  
    return nil
    
  }

}

