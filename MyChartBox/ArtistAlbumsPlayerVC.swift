//
//  ArtistAlbumsPlayerVC.swift
//  MyChartBox
//
//  Created by Paul Willmott on 05/01/2021.
//  Copyright © 2021 Paul Willmott. All rights reserved.
//

import Cocoa
import AVFoundation

class ArtistAlbumsPlayerVC: NSViewController, PlayerViewDelegate, AlbumPlayerDelegate, PlayerControlDelegate {
  
  // Private Properties
  
  private var collectionDS = ComboBoxDataSource(tableName: TABLE.COLLECTION, codeColumn: COLLECTION.COLLECTION_ID, displayColumn: COLLECTION.COLLECTION_NAME, sortColumn: COLLECTION.SORT_NAME)

  private var collection : ArtistCollection?

  private var artistChartListing : [ArtistCollectionChartListing] = []
  
  private var collectionTableViewDS = CollectionTableViewDS(chartType: .Albums)
  
  private var playList : [MusicAlbum] = []
  
  private var indexList : [Int] = []
  
  private var playIndex : Int = 0
  
  private var durationOfCompletedTracks : Int = 0
  
  private var durationOfPlaylist : Int = 0

  private var albumPlayerVC : AlbumPlayerVC?
  
  // Private Methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    cboArtist.dataSource = collectionDS
    cboArtist.delegate   = collectionDS
    collectionTableView.dataSource = collectionTableViewDS
    collectionTableView.delegate = collectionTableViewDS
    playerControl.delegate = self
  }
  
  // Outlets and Actions
  
  @IBOutlet weak var cboArtist: NSComboBox!
  @IBOutlet weak var collectionTableView: NSTableView!
  @IBOutlet weak var playerControl: PlayerControl!
  
  @IBAction func cboArtistAction(_ sender: NSComboBox) {
    if !sender.stringValue.isEmpty {
      let code = collectionDS.codeOfItemWithStringValue(string: sender.stringValue)
      if code == -1 {
        collection = nil
        self.view.window?.title = "Artist\'s Chart Albums"
      }
      else {
        collection = ArtistCollection(collectionid: code)
        playerControl.playlistFinished()
        reloadMainList()
      }
    }
  }
  
  @IBAction func btnFindAction(_ sender: NSButton) {
    
    let itemIndex = sender.tag
    
    let chartListing = artistChartListing[itemIndex]
    
    let isInPlayList = chartListing.bestAlbum != nil
    
    selectOverride(chartListing: chartListing.chartListing, sideIndex: chartListing.index)
    
    collectionTableView.reloadData()
    
    if isInPlayList && chartListing.bestAlbum == nil {
      var index = 0
      while index < indexList.count && indexList[index] < itemIndex {
        index += 1
      }
      playList.remove(at: index)
      indexList.remove(at: index)
      if playIndex >= index {
        playIndex -= 1
      }
    }
    else if !isInPlayList && chartListing.bestAlbum != nil {
      var index = 0
      while index < indexList.count && indexList[index] < itemIndex {
        index += 1
      }
      playList.insert(chartListing.bestAlbum!, at: index)
      indexList.insert(itemIndex, at: index)
      if playIndex >= index {
        playIndex += 1
      }
    }
    
  }
  
  @IBAction func collectionTableViewDoubleAction(_ sender: Any) {

    albumPlayerVC?.playerControl.stopPlaylist()
    playerControl.playlistFinished()
    
    let selected = collectionTableView.selectedRow
    
    durationOfCompletedTracks = 0
    
    playIndex = playList.count
    
    for index in 0..<playList.count {
      let j = indexList[index]
      if j < selected {
        durationOfCompletedTracks += playList[index].albumDuration
      }
      else {
        playIndex = index
        break
      }
    }
    
    playerControl.btnPlayAction(nil)
    
  }
  
  // Private Methods
  
  private func reloadMainList() {
    
    artistChartListing = collection!.ArtistChartListings(chartType: .Albums)
    collectionTableViewDS.chartEntries = artistChartListing
    collectionTableView.reloadData()
    
    // Make play list, skip duplicates
    
    playList.removeAll()
    durationOfCompletedTracks = 0
    durationOfPlaylist = 0
    var index = 0
    for chartListing in artistChartListing {
      if let bestAlbum = chartListing.bestAlbum {
        var duplicate = false
        for album in playList {
          if album.persistentID == bestAlbum.persistentID {
            duplicate = true
            break
          }
        }
        if !duplicate {
          playList.append(bestAlbum)
          indexList.append(index)
          durationOfPlaylist += bestAlbum.albumDuration
        }
      }
      index += 1
    }
    
    var name = cboArtist.stringValue
    name = name + (name.suffix(1) == "s" ? "\'" : "'s")
    self.view.window?.title = "\(name) Chart Albums"
    playIndex = 0
    
  }
  
  private func previousAlbum(startAtBeginning:Bool) {
    albumPlayerVC?.view.window?.close()
    playIndex = max(0, playIndex - 1)
    durationOfCompletedTracks = 0
    for index in 0..<playIndex {
      durationOfCompletedTracks += playList[index].albumDuration
    }
    collectionTableView.selectRowIndexes(.init(integer: indexList[playIndex]), byExtendingSelection: false)
    albumPlayerVC = albumPlayer(album: playList[playIndex], delegate: self, startAtBeginning: startAtBeginning)
    albumPlayerVC?.playerControl.slave = playerControl
  }
  
  private func nextAlbum() {
    albumPlayerVC?.view.window?.close()
    durationOfCompletedTracks += playList[playIndex].albumDuration
    playIndex += 1
    if playIndex < playList.count {
      collectionTableView.selectRowIndexes(.init(integer: indexList[playIndex]), byExtendingSelection: false)
      albumPlayerVC = albumPlayer(album: playList[playIndex], delegate: self, startAtBeginning: true)
      albumPlayerVC?.playerControl.slave = playerControl
    }
    else {
      playerControl.playlistFinished()
      playIndex = 0
    }
  }
  
  // Player Control Delegate Functions
  
  @objc func play(playerControl:PlayerControl) {
    if playIndex < playList.count {
      collectionTableView.selectRowIndexes(.init(integer: indexList[playIndex]), byExtendingSelection: false)
      albumPlayerVC = albumPlayer(album: playList[playIndex], delegate: self, startAtBeginning: true)
      albumPlayerVC?.playerControl.slave = playerControl
     }
  }
  
  @objc func pause(playerControl:PlayerControl) {
    albumPlayerVC?.playerControl.btnPlayAction(playerControl)
    albumPlayerVC?.playerControl.btnPlay.state = playerControl.btnPlay.state
  }
  
  @objc func resume(playerControl:PlayerControl) {
    albumPlayerVC?.playerControl.btnPlayAction(playerControl)
    albumPlayerVC?.playerControl.btnPlay.state = playerControl.btnPlay.state
  }
  
  @objc func backward(playerControl:PlayerControl) {
    albumPlayerVC?.playerControl.stopPlaylist()
    previousAlbum(startAtBeginning: true)
  }
  
  @objc func forward(playerControl:PlayerControl) {
    albumPlayerVC?.playerControl.stopPlaylist()
    nextAlbum()
  }
  
  @objc func stop(playerControl:PlayerControl) {
    albumPlayerVC?.playerControl.stopPlaylist()
    playerControl.playlistFinished()
    albumPlayerVC = nil
  }
  
  // Album Player Delegate Functions
  
  func previousAlbum(sender: PlayerControlPlus) {
    previousAlbum(startAtBeginning: playIndex == 0)
  }
  
  func nextAlbum(sender: PlayerControlPlus) {
    nextAlbum()
  }
  
  func stop(sender: PlayerControlPlus) {
    collectionTableView.deselectAll(nil)
    playerControl.playlistFinished()
    playIndex = 0
    durationOfCompletedTracks = 0
  }
  
  func updateMeters(player: AVAudioPlayer) {
    playerControl.updateMeters(player: player)
  }
  
  func updateProgressIndicators(player: AVAudioPlayer, durationOfCompletedTracks: Int, durationOfPlaylist: Int) {
    let totalDurationOfCompletedTracks = self.durationOfCompletedTracks + durationOfCompletedTracks
    playerControl.updateProgressIndicators(player: player, durationOfCompletedTracks: totalDurationOfCompletedTracks, durationOfPlaylist: self.durationOfPlaylist)
  }
  
  func updateState(sender: PlayerControlPlus) {
    playerControl.playerState = sender.playerState
  }
  
  // Player View Delegate Functions
  
  func playerControlInstance() -> PlayerControl {
    return playerControl
  }
  

  
}
