//
//  CollectionTableViewDS.swift
//  MyChartBox
//
//  Created by Paul Willmott on 12/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa

public class CollectionTableViewDS : NSObject, NSTableViewDataSource, NSTableViewDelegate {
  
  public init(chartType:ChartType) {
    self.chartType = chartType
    super.init()
  }
  
  private var chartType : ChartType
  
  public var chartEntries = [ArtistCollectionChartListing]()

  fileprivate enum CellIdentifiers {
    static let ChartEntryDateCell  = "ChartEntryDateCellID"
    static let PositionFlagCell    = "PositionFlagCellID"
    static let SongTitleCell       = "SongTitleCellID"
    static let LabelCell           = "LabelCellID"
    static let CatalogueNumberCell = "CatalogueNumberCellID"
    static let PeakPositionCell    = "PeakPositionCellID"
    static let WeeksOnChartCell    = "WeeksOnChartCellID"
    static let OverrideCell        = "OverrideCellID"
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


    if tableColumn == tableView.tableColumns[0] {
      
      var calendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
      calendar.timeZone = TimeZone(abbreviation: "UTC")!
      
      let df = DateFormatter()
      df.calendar = calendar
      df.dateStyle = .medium
      df.timeStyle = .none
      df.timeZone = TimeZone(abbreviation: "UTC")!

      text = "\(df.string(from: item.chartEntryDate))"
      cellIdentifier = CellIdentifiers.ChartEntryDateCell
      
    }
    else if tableColumn == tableView.tableColumns[1] {
      switch item.positionFlag {
      case .NumberOne:
        text = "\u{2B50}"
      case .Top10:
        text = "\u{25CF}"
      default:
        text = ""
      }
      cellIdentifier = CellIdentifiers.PositionFlagCell
    }
    else if tableColumn == tableView.tableColumns[2] {
      text = item.chartListing.sides[item.index].UKChartTitleClean
      cellIdentifier = CellIdentifiers.SongTitleCell
    }
    else if tableColumn == tableView.tableColumns[3] {
      text = item.chartListing.LabelObj!.UKChartName
      cellIdentifier = CellIdentifiers.LabelCell
    }
    else if tableColumn == tableView.tableColumns[4] {
      text = item.chartListing.CatalogueNumber
      cellIdentifier = CellIdentifiers.CatalogueNumberCell
      tableColumn?.width = 100
    }
    else if tableColumn == tableView.tableColumns[5] {
      text = item.peakPosition
      cellIdentifier = CellIdentifiers.PeakPositionCell
    }
    else if tableColumn == tableView.tableColumns[6] {
      text = item.weeksOnChart
      cellIdentifier = CellIdentifiers.WeeksOnChartCell
    }
    else if tableColumn == tableView.tableColumns[7] {
      cellIdentifier = CellIdentifiers.OverrideCell
    }

    if cellIdentifier == CellIdentifiers.OverrideCell {
      if let cell = tableView.makeView(withIdentifier:
      NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSButton {
       
        let exists = chartType == .Singles ? item.chartListing.bestTrack(index: item.index) != nil : item.chartListing.bestAlbum() != nil
        if !exists {
          cell.title = "Find"
        }
        else {
          cell.title = "Change"
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

