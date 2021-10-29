//
//  TableCellViewChartListing.swift
//  MyChartBox
//
//  Created by Paul Willmott on 02/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Cocoa

class TableCellViewChartListing: NSTableCellView {

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    // Drawing code here.
  }
  
//  override func prepareForReuse() {
//    super.prepareForReuse()
//  }
    
  @IBOutlet weak var songTitle: NSTextField!
  @IBOutlet weak var artistName: NSTextField!
}
