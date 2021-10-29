//
//  ArtistSinglesPlayerVC.swift
//  MyChartBox
//
//  Created by Paul Willmott on 10/01/2021.
//  Copyright © 2021 Paul Willmott. All rights reserved.
//

import Cocoa

class ArtistSinglesPlayerVC: NSViewController, PlayerViewDelegate {

  // View Control Functions
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
    
    cboArtist.dataSource = collectionDS
    cboArtist.delegate   = collectionDS
    tableView.dataSource = collectionTableViewDS
    tableView.delegate = collectionTableViewDS

    playerControl.tableView = tableView
    playerControl.isAlbumMode = false
 
  }
  
  // Private Properties
  
  private var collectionDS = ComboBoxDataSource(tableName: TABLE.COLLECTION, codeColumn: COLLECTION.COLLECTION_ID, displayColumn: COLLECTION.COLLECTION_NAME, sortColumn: COLLECTION.SORT_NAME)

  private var collection : ArtistCollection?

  private var artistChartListing : [ArtistCollectionChartListing] = []
  
  private var collectionTableViewDS = CollectionTableViewDS(chartType: .Singles)
  
  // Public Properties
  
  // Private Methods
  
  private func reloadMainList() {
    
    artistChartListing = collection!.ArtistChartListings(chartType: .Singles)
    collectionTableViewDS.chartEntries = artistChartListing
    tableView.reloadData()
    
    // Make play list, skip duplicates
    
    playerControl.removeAll()
    
    var index = 0
    for chartListing in artistChartListing {
      if let bestTrack = chartListing.bestTrack {
        playerControl.add(track: bestTrack, at: index)
      }
      index += 1
    }
    
    var name = cboArtist.stringValue
    name = name + (name.suffix(1) == "s" ? "\'" : "'s")
    self.view.window?.title = "\(name) Chart Singles"
    
  }

  // Public Methods
  
  // Outlets
  
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var playerControl: PlayerControlPlus!
  @IBOutlet weak var cboArtist: NSComboBox!
  
  // Actions
    
  @IBAction func tableViewDoubleAction(_ sender: NSTableView) {
    playerControl.play(at: tableView.selectedRow)
  }
  
  @IBAction func cboArtistAction(_ sender: NSComboBox) {
    if !sender.stringValue.isEmpty {
      playerControl.stopPlaylist()
      let code = collectionDS.codeOfItemWithStringValue(string: sender.stringValue)
      if code == -1 {
        collection = nil
        self.view.window?.title = "Artist\'s Chart Singles"
      }
      else {
        collection = ArtistCollection(collectionid: code)
        reloadMainList()
      }
      playerControl.btnStopAction(nil)
    }
  }
  
  @IBAction func btnFindAction(_ sender: NSButton) {
    
    let itemIndex = sender.tag
    
    let chartListing = artistChartListing[itemIndex]
    
    let isInPlaylist = chartListing.bestTrack != nil
    
    let pid = chartListing.bestTrack?.persistentID ?? 0
    
    selectOverride(chartListing: chartListing.chartListing, sideIndex: chartListing.index)
    
    if isInPlaylist && chartListing.bestTrack == nil {
      playerControl.remove(at: itemIndex)
    }
    else if !isInPlaylist && chartListing.bestTrack != nil {
      playerControl.add(track: chartListing.bestTrack!, at: itemIndex)
    }
    else if chartListing.bestTrack != nil && pid != chartListing.bestTrack!.persistentID {
      playerControl.replace(track: chartListing.bestTrack!, at: itemIndex)
    }
    
    tableView.reloadData()    
 
  }
  
  // Player View Delegate Functions
  
  func playerControlInstance() -> PlayerControl {
    return playerControl
  }
  


  
}
