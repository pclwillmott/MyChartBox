//
//  ChartAlbumsPlayerVC.swift
//  MyChartBox
//
//  Created by Paul Willmott on 31/01/2021.
//  Copyright © 2021 Paul Willmott. All rights reserved.
//

import Cocoa
import AVFoundation

class ChartAlbumsPlayerVC: NSViewController, PlayerViewDelegate, AlbumPlayerDelegate, PlayerControlDelegate {
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
    
    playerControl.delegate = self
    
    cboTop.addItem(withObjectValue: "Number Ones")
    cboTop.addItem(withObjectValue: "Top 5")
    cboTop.addItem(withObjectValue: "Top 10")
    cboTop.addItem(withObjectValue: "Top 40")
    cboTop.addItem(withObjectValue: "Top 50")
    cboTop.addItem(withObjectValue: "Top 75")
    cboTop.addItem(withObjectValue: "Top 100")

    cboTop.stringValue = UserDefaults.standard.string(forKey: DEFAULT.TOP_LIMIT_ALBUMS) ?? "Top 40"

    let jd = jdFromDate(date: Date())
    let dt = dateFromJd(jd: jd)
    
    datePicker.maxDate = dt
    datePicker.dateValue = dt

    lblChartDates.stringValue = ""
    
  }
  
  // Private Properties
  
  typealias AlbumListItem = (album:MusicAlbum, index:Int)
  
  private var tableViewDS = MainTableViewDS()
  
  private var programme : Programme!
  
  private var repeatCount : Int = 0
  
  private var playList : [AlbumListItem] = []
  
  private var playIndex : Int = 0
  
  private var durationOfCompletedTracks : Int = 0
  
  private var durationOfPlaylist : Int = 0

  private var albumPlayerVC : AlbumPlayerVC?
  
  private var _sortOrder : SortOrder = .ascending
  
  private var sortOrder : SortOrder {
    get {
      return _sortOrder
    }
    set(value) {
      if value != _sortOrder {
        _sortOrder = value
        if playList.count > 0 {
          let index = playList[playIndex].index
          sortPlayList()
          playIndex = playListPosition(index: index)!
        }
      }
    }
  }
  
  // Public Properties
  
  // Private Methods
  
  private func setupChart(date:Date) {
    
    let limits = ["Number Ones": 1, "Top 5":5, "Top 10":10, "Top 40":40, "Top 50":50, "Top 75":75, "Top 100":100, "Max Runtime":-1, "Target Time":-2]
    
    let minPosition = limits[cboTop.stringValue] ?? 100
    
    let programmeMode : ProgrammeMode = minPosition == -1 ? .MaxRuntime : minPosition == -2 ? .TargetTime : .All
    
    programme = Programme(isSinglesMode:false, date: date, minPosition: minPosition)
    
    tableViewDS.chartEntries = programme.chartEntries
    tableView.dataSource = tableViewDS
    tableView.delegate = tableViewDS
    tableView.reloadData()

    lblChartDates.stringValue = programme.chartDates
    
    let skipRecentlyPlayed = UserDefaults.standard.bool(forKey: DEFAULT.SKIP_RECENTLY_PLAYED)
    
    var lowestPlayCount = Int.max
    
    for chartEntry in programme.chartEntries {
      if let album = chartEntry.bestAlbum {
        lowestPlayCount = min(lowestPlayCount, album.playCount)
      }
    }
    
    playList.removeAll()
    var index = 0
    for chartEntry in programme.chartEntries {
      if let album = chartEntry.bestAlbum {
        if album.playCount == lowestPlayCount || !skipRecentlyPlayed {
          add(album: album, at: index)
        }
      }
      index += 1
    }
    playIndex = 0

  }
  
  private func getDate() -> Date {
    
    var date = datePicker.dateValue
    
    let shuffle = UserDefaults.standard.bool(forKey: DEFAULT.SHUFFLE)
    
    if shuffle {

      var minYear = 1953
      
      let shuffleFrom = UserDefaults.standard.string(forKey: DEFAULT.SHUFFLE_FROM) ?? "1953"

      if let f = Int(shuffleFrom) {
        minYear = f
      }
      
      var calendar = Calendar.current
      calendar.timeZone = TimeZone(secondsFromGMT: 0)!
      
      var maxYear  = max(1957, calendar.component(.year, from: date))
      
      let shuffleTo = UserDefaults.standard.string(forKey: DEFAULT.SHUFFLE_TO) ?? "TODAY"

      if shuffleTo != "TODAY" {
        if let t = Int(shuffleTo) {
          maxYear = t
        }
      }
      
      let playCount = PlayCount.lowestRandomYear(fromYear: minYear, toYear: maxYear, chartId: 1)

      playCount.incrementPlayCount()
      
      let month = calendar.component(.month, from: date)
      let day   = calendar.component(.day,   from: date)
      let isoDate = String(format: "%04d-%02d-%02dT00:00:00Z", playCount.year, month, day)
      let dateFormatter = ISO8601DateFormatter()
      
      date = dateFormatter.date(from:isoDate)!
    }
    
    return date
  }
  
  private func previousAlbum(startAtBeginning:Bool) {
    albumPlayerVC?.view.window?.close()
    playIndex = max(0, playIndex - 1)
    durationOfCompletedTracks = 0
    for index in 0..<playIndex {
      durationOfCompletedTracks += playList[index].album.albumDuration
    }
    tableView.selectRowIndexes(.init(integer: playList[playIndex].index), byExtendingSelection: false)
    albumPlayerVC = albumPlayer(album: playList[playIndex].album, delegate: self, startAtBeginning: startAtBeginning)
    albumPlayerVC?.playerControl.slave = playerControl
  }
  
  private func nextAlbum() {
    albumPlayerVC?.view.window?.close()
    durationOfCompletedTracks += playList[playIndex].album.albumDuration
    playIndex += 1
    if playIndex < playList.count {
      tableView.selectRowIndexes(.init(integer: playList[playIndex].index), byExtendingSelection: false)
      albumPlayerVC = albumPlayer(album: playList[playIndex].album, delegate: self, startAtBeginning: true)
      albumPlayerVC?.playerControl.slave = playerControl
    }
    else {
      playerControl.playlistFinished()
      playIndex = 0
      
      var result = false
      
      let repeatMode = RepeatMode(rawValue:UserDefaults.standard.integer(forKey: DEFAULT.REPEAT))
      
      let shuffle = UserDefaults.standard.bool(forKey: DEFAULT.SHUFFLE)
      
      if shuffle {
        
        if repeatMode! == .All {
          result = true
        }
        else if repeatMode! == .One && repeatCount == 0 {
          repeatCount += 1
          result = true
        }
        else {
          repeatCount = 0
        }
        
        if result {
          setupChart(date: getDate())
        }
        
      }
      else if repeatMode! == .All {
        result = true
      }
      else if repeatMode! == .One && repeatCount == 0 {
        repeatCount += 1
        result = true
      }
      else {
        repeatCount = 0
      }

      if result {
        playerControl.btnPlayAction(nil)
      }
      
    }
  }

  private func sortPlayList() {
    if _sortOrder == .ascending {
      playList.sort {
        $0.index < $1.index
      }
    }
    else {
      playList.sort {
        $0.index > $1.index
      }
    }
  }

  private func playListPosition(index:Int) -> Int? {
    
    var pos = 0
    
    for temp in playList {
      if temp.index == index {
        break
      }
      pos += 1
    }
    
    return pos == playList.count ? nil : pos

  }

  public func add(album:MusicAlbum, at:Int) {

    playList.append((album:album, index:at))
        
    sortPlayList()
        
    let albumDuration = album.albumDuration
        
    if let pos = playListPosition(index: at) {
      if playIndex >= pos {
        playIndex += 1
      }
    }
        
    durationOfPlaylist += albumDuration
    
  }
  
  public func remove(at:Int) {
    
    if let pos = playListPosition(index: at) {
      
      let albumDuration = playList[pos].album.albumDuration
      
      durationOfPlaylist -= albumDuration
      
      if playIndex >= pos {
        playIndex -= 1
      }
      
      playList.remove(at: pos)
      
    }
    
  }
  
  public func replace(album:MusicAlbum, at:Int) {
    
    var restart = false
    
    let savePlayIndex = playIndex
    
//    if isPlaying && playList[playIndex].index == at {
//      stopPlayer()
//      restart = true
 //   }
    remove(at: at)
    add(album: album, at: at)
    
    if restart {
      playIndex = savePlayIndex
//      startPlayer()
    }
    
  }
  
  public func removeAll() {
//    stopPlayer()
    playList.removeAll()
    playIndex = 0
    durationOfPlaylist = 0
  }

  // Album Player Delegate Functions
  
  func previousAlbum(sender: PlayerControlPlus) {
    previousAlbum(startAtBeginning: playIndex == 0)
  }
  
  func nextAlbum(sender: PlayerControlPlus) {
    nextAlbum()
  }
  
  func stop(sender: PlayerControlPlus) {
    tableView.deselectAll(nil)
    playerControl.playlistFinished()
    playIndex = 0
    durationOfCompletedTracks = 0
    removeAll()
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
  
  // Player Control Delegate Functions
  
  @objc func play(playerControl:PlayerControl) {

    let shuffle = UserDefaults.standard.bool(forKey: DEFAULT.SHUFFLE)

    var done = false
    while !done && playList.count == 0 {
      setupChart(date: getDate())
      done = !shuffle
    }
    
    if playIndex < playList.count {
      tableView.selectRowIndexes(.init(integer: playList[playIndex].index), byExtendingSelection: false)
      albumPlayerVC = albumPlayer(album: playList[playIndex].album, delegate: self, startAtBeginning: true)
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
    removeAll()
  }

  // Outlets
  
  @IBOutlet weak var datePicker: NSDatePicker!
  @IBOutlet weak var cboTop: NSComboBox!
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var btnSelect: NSButton!
  @IBOutlet weak var lblChartDates: NSTextField!
  @IBOutlet weak var playerControl: PlayerControl!
  
  // Actions
  
  @IBAction func btnSelectAction(_ sender: NSButton) {
    setupChart(date: getDate())
  }
  
  @IBAction func btnFindAction(_ sender: NSButton) {
    let chartEntry = programme.chartEntries[sender.tag]
    var isInPlaylist = false
    for playListItem in playList {
      if sender.tag == playListItem.index {
        isInPlaylist = true
        break
      }
    }
    let pid = chartEntry.bestAlbum?.persistentID ?? -1
    selectOverride(chartListing: chartEntry.chartListing, sideIndex: chartEntry.Index)
    tableView.reloadData()
    if isInPlaylist && chartEntry.bestAlbum == nil {
      remove(at: sender.tag)
    }
    else if !isInPlaylist && chartEntry.bestAlbum != nil {
      add(album: chartEntry.bestAlbum!, at: sender.tag)
    }
    else if chartEntry.bestAlbum != nil && chartEntry.bestAlbum!.persistentID != pid {
      replace(album: chartEntry.bestAlbum!, at: sender.tag)
    }
  }
    
  @IBAction func cboTopAction(_ sender: NSComboBox) {
    UserDefaults.standard.set(cboTop.stringValue, forKey: DEFAULT.TOP_LIMIT_ALBUMS)
  }
  
  @IBAction func tableViewDoubleAction(_ sender: NSTableView) {
    
    albumPlayerVC?.playerControl.stopPlaylist()
    
    playerControl.playlistFinished()
    
    let selected = tableView.selectedRow
    
    durationOfCompletedTracks = 0
    
    playIndex = playList.count
    
    for index in 0..<playList.count {
      let j = playList[index].index
      if j < selected {
        durationOfCompletedTracks += playList[index].album.albumDuration
      }
      else {
        playIndex = index
        break
      }
    }
    
    playerControl.btnPlayAction(nil)
    
  }
  
}
