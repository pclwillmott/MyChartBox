//
//  ArtistViewVC.swift
//  MyChartBox
//
//  Created by Paul Willmott on 11/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa

@available(OSX 10.14, *)
class ArtistViewVC: NSViewController, NSTextFieldDelegate, NSWindowDelegate {
  
  func queueTrackAndIntro()
  {
    
    var done = false
    
    var nextMessage = ""
     
    while !done && playIndex < artistChartListing.count {
          
      let listing = artistChartListing[playIndex]
        
      playIndex += 1
      
      if let track = listing.bestTrack {
        
        var doneAlready = false
        
        var idx = 0
        while !doneAlready && idx < playIndex - 2 {
          let x = artistChartListing[idx]
          if let otherTrack = x.bestTrack {
            if track.mediaItem.persistentID == otherTrack.mediaItem.persistentID {
              doneAlready = true
              break
            }
          }
          idx += 1
        }
        
        if !doneAlready {
          let chartEntry : ChartEntry = ChartEntry()
          chartEntry.ChartDate = listing.chartEntryDate
          chartEntry.ChartEntryId = -1
          chartEntry.ChartListingId = listing.chartListing.ChartListingId
          chartEntry.HighestPosition = listing.peakPosition
          chartEntry.Index = listing.index
          dj.addItem(announcement: "", chartEntry: chartEntry, index: playIndex - 1)
          done = true
          nextMessage = ""
        }
        
      }
        
    }

    if playerState != .Stop && !done {
      dj.addItem(announcement: nextMessage, chartEntry: nil, index: -1)
      playerState = .Stop
    }
     
  }
  
  // Total running time of tracks in milliseconds of completed tracks
   public func runningTime(nowPlayingIndex:Int) -> Int {
     
     var time : Int = 0

     var index = 0
     
     while index < nowPlayingIndex {
       let entry = artistChartListing[index]
       if let track = entry.bestTrack {
         time += track.mediaItem.totalTime
       }
       index += 1
     }
     
     return time
   }

  
  func djQueueNextItem(sender: DJ) {
    queueTrackAndIntro()
  }

  func djDidFinishShow(sender: DJ) {
    playerState = .Start
  }
  
  private var nowPlayingIndex : Int = -1
  private var completedRunningTime : Int = 0
  
  func djNowPlaying(sender: DJ, message: String, index: Int) {
    view.window?.title = message
    nowPlayingIndex = index
    if index == -1 {
    }
    else {
    }
  }
  
  private var totTime : Int = 0
  private var totDone : Int = 0


  
  
  //private var chartEntries : [ChartEntry] = []
  
  private var dj = DJ()

  private var playerState = PlayerState.Start
  
  private var playIndex : Int = 0
  
  private var lastSong = ""

  var collectionDS = ComboBoxDataSource(tableName: TABLE.COLLECTION, codeColumn: COLLECTION.COLLECTION_ID, displayColumn: COLLECTION.COLLECTION_NAME, sortColumn: COLLECTION.SORT_NAME)
  
  var collection : ArtistCollection?
  var sourceDS = ChartArtistTableViewDS()
  var destDS = ChartArtistTableViewDS()
  var collectionTableViewDS = CollectionTableViewDS(chartType: .Singles)
  
  private var sources : [Artist] = []
  private var dests   : [Artist] = []
  
  @IBOutlet weak var tabView: NSTabView!
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
    
    cboArtist.dataSource = collectionDS
    cboArtist.delegate   = collectionDS
    
    sourceDS.artists = sources
    destDS.artists = dests
    
    
    collectionTableView.dataSource = collectionTableViewDS
    collectionTableView.delegate = collectionTableViewDS

//    txtSelection.delegate = self
    
 //   tabView.delegate = self
    
 //   removeCollection.isEnabled = false
    
    
 //   dj.delegate = self
    dj.windowTitle = "Artists"
    
  }
  
  @IBAction func trackDoubleClick(_ sender: NSTableView) {
    let index = sender.selectedRow
    if index != -1 {
      dj.stop()
      playerState = .PlayingShow
      playIndex = index
      lastSong = ""
      queueTrackAndIntro()
    }
  }
  
  func playChart() {
      
    playIndex = 0
    
    playerState = .PlayingShow
          
    let message = ""
          
    dj.addItem(announcement: message, chartEntry: nil, index: -1)
    
  }

  public func djPlay() {
    if playerState == .Start && dj.queueEmpty {
       playChart()
    }
    else if !dj.isPaused {
      dj.pause()
    }
    else {
      dj.play()
    }
  }
  
  public func djVolumeUp() {
    dj.volumeUp()
  }
  
  public func djVolumeDown() {
    dj.volumeDown()
  }
  
  public func djVolumeReset() {
    dj.volumeReset()
  }
  
  public func djRewind() {
    dj.rewind()
  }
  
  @IBAction func btnRewindClick(_ sender: NSButton) {
    djRewind()
  }
  
  public func djStop() {
    dj.stop()
  }
  
  @IBAction func btnStopClick(_ sender: NSButton) {
    djStop()
  }
  
  @IBAction func btnPlayClick(_ sender: NSButton) {
    djPlay()
  }
  
  public func djFastForward() {
    dj.fastForward()
  }
  
  @IBAction func btnFastForwardClick(_ sender: NSButton) {
    djFastForward()
  }
  
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    stopModal()
    return true
  }
  
  override func viewDidAppear() {
    self.view.window!.delegate = self
  }
  
  func tabView(_ tabView: NSTabView,
               willSelect tabViewItem: NSTabViewItem?) {
    if tabViewItem!.label == "Chart Entries" {
      if changesMade {
        reloadMainList()
      }
    }
    
  }
  
  var changesMade = false
  
  @IBOutlet weak var cboArtist: NSComboBox!
  
  @IBAction func cboArtistAction(_ sender: NSComboBox) {
    djStop()
    if !sender.stringValue.isEmpty {
      let code = collectionDS.codeOfItemWithStringValue(string: sender.stringValue)
      if code != -1 {
        collection = ArtistCollection(collectionid: code)
      }
      else {
        collection = ArtistCollection()
        collection?.collectionName = sender.stringValue
        collection?.Save()
        collectionDS.reloadData()
        cboArtist.reloadData()
      }
      reloadMainList()
    }
//    txtSelection.stringValue = sender.stringValue
//    refreshSources(artist: sender.stringValue)
//    refreshDests()
  }
  
  
  func controlTextDidChange(_ obj: Notification) {
//    let x: NSTextField = obj.object! as! NSTextField
//    refreshSources(artist: txtSelection.stringValue)
  }
  
  @IBOutlet weak var collectionTableView: NSTableView!
  
  
  @IBAction func btnOverrideClick(_ sender: NSButton) {
    let chartListing = artistChartListing[sender.tag]
    selectOverride(chartListing: chartListing.chartListing, sideIndex: chartListing.index)
//    reloadMainList()
    collectionTableView.reloadData()

  }
  
  
  var artistChartListing : [ArtistCollectionChartListing] = []
  
  func reloadMainList() {
    artistChartListing = collection!.ArtistChartListings(chartType: .Singles)
    collectionTableViewDS.chartEntries = artistChartListing
    collectionTableView.reloadData()
    changesMade = false
  }
  
  
  // Outlets
  
  @IBOutlet weak var playerControl: PlayerControl!
  
  // Actions
  
}

