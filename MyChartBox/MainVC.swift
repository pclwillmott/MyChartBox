//
//  MainVC.swift
//  MyChartBox
//
//  Created by Paul Willmott on 05/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Cocoa
import AVFoundation

enum PlayerState {
  case Start
  case PlayingShow
  case Stop
}

public var musicLibrary = Music()!

@available(OSX 10.14, *)
class MainVC: NSViewController, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate, DJDelegate, DJController, AlbumPlayerDelegate {
  func updateState(sender: PlayerControlPlus) {
    
  }
  
  func previousAlbum(sender: PlayerControlPlus) {
    
  }
  
  func nextAlbum(sender: PlayerControlPlus) {
    
  }
  
  func stop(sender: PlayerControlPlus) {
    
  }
  
  func previousAlbum(sender: PlayList) {
    
  }
  
  func nextAlbum(sender: PlayList) {
    
  }
  
  func stop(sender: PlayList) {
    
  }
  
  func updateMeters(player: PlayList) {
    
  }
  
  func updateProgressIndicators(player: PlayList, durationOfCompletedTracks: Int, durationOfPlaylist: Int) {
    
  }
  
  func previousAlbum(sender: AlbumPlayerVC) {
    
  }
  
  func nextAlbum(sender: AlbumPlayerVC) {
    
  }
  
  func stop(sender: AlbumPlayerVC) {
    
  }
  
  func updateMeters(player: AVAudioPlayer) {
    
  }
  
  func updateProgressIndicators(player: AVAudioPlayer, durationOfCompletedTracks: Int, durationOfPlaylist: Int) {
  }
  
  

  private var dj = DJ()

  private var playList : Programme?
  
  private var playerState = PlayerState.Start
  
  private var playIndex : Int = 0
  
  private var lastSong = ""
  
  private var tableViewDS = MainTableViewDS()
  
  override func viewWillAppear() {
  }
  override func viewDidLoad() {
      
    super.viewDidLoad()

    // Do any additional setup after loading the view.
      
    // let isoDate = "1982-08-01T00:00:00Z"
    // let dateFormatter = ISO8601DateFormatter()
    // let date = dateFormatter.date(from:isoDate)!
    
    let jd = jdFromDate(date: Date())
    let dt = dateFromJd(jd: jd)
    
    datePickerOutlet.maxDate = dt
    datePickerOutlet.dateValue = dt

    cboMode.stringValue = UserDefaults.standard.string(forKey: DEFAULT.MODE) ?? "Singles"

    setupView()
    
    dj.delegate = self
    dj.announcer = UserDefaults.standard.bool(forKey: DEFAULT.ANNOUNCER)
    chkAnnounceSongs.state = (dj.announcer) ? .on : .off
    
    lblChartDates.stringValue = ""
    
    progressIndicator.doubleValue = 0.0
    progressTotalIndicator.doubleValue = 0.0
    
    lblTimeToDo.stringValue = ""
    lblTimeDone.stringValue = ""
    lblTotalTimeDone.stringValue = ""
    lblTotalTimeToDo.stringValue = ""
    progressIndicator.isHidden = true
    progressTotalIndicator.isHidden = true
    
    mainVC = self
    /*
    var result : [MusicArtist] = []
    
    for x in musicLibrary.allArtists {
      result.append(x.value)
    }
    result.sort {
      $0.name < $1.name
    }
    
    for x in result {
      for y in x.iTunesAlbums {
        if x.name == "John Lennon" {
          print("\(x.name) \(y.value.persistentID) \(y.value.title)")
          for z in y.value.iTunesTracksSorted {
            print("  \(z.mediaItem.album.discNumber) \(z.mediaItem.trackNumber) \(z.mediaItem.title)")
          }
        }
      }
    }
 */


  }
  
  var isSinglesMode : Bool {
    get {
      return cboMode.stringValue == "Singles"
    }
  }
  
  func setupView() {
  
    let singlesMode = isSinglesMode

    cboTop.removeAllItems()
    
    if singlesMode {
      cboTop.addItem(withObjectValue: "Number Ones")
      cboTop.addItem(withObjectValue: "Top 5")
      cboTop.addItem(withObjectValue: "Top 10")
      cboTop.addItem(withObjectValue: "Top 40")
      cboTop.addItem(withObjectValue: "Top 50")
      cboTop.addItem(withObjectValue: "Top 75")
      cboTop.addItem(withObjectValue: "Top 100")
      cboTop.addItem(withObjectValue: "Max Runtime")
      cboTop.addItem(withObjectValue: "Target Time")

      cboTop.stringValue = UserDefaults.standard.string(forKey: DEFAULT.TOP_LIMIT) ?? "Top 40"
    }
    else {
      cboTop.addItem(withObjectValue: "Highest to Lowest")
      cboTop.addItem(withObjectValue: "Lowest to Highest")

      cboTop.stringValue = UserDefaults.standard.string(forKey: DEFAULT.TOP_LIMIT_ALBUMS) ?? "Lowest to Highest"
    }

    colSong.headerCell.title = singlesMode ? "Song" : "Album"
    chkAnnounceSongs.isHidden = !singlesMode

    tableView.reloadData()
    
  }
  
  var minPlayCount : Int = Int.max
  
  func setupChart(date:Date) {
    
    playerState = .Start

    let limits = ["Number Ones": 1, "Top 5":5, "Top 10":10, "Top 40":40, "Top 50":50, "Top 75":75, "Top 100":100, "Max Runtime":-1, "Target Time":-2]
    
    playList = Programme(isSinglesMode:isSinglesMode, date: date, minPosition: limits[cboTop.stringValue] ?? 100)

    tableViewDS.chartEntries = playList!.chartEntries
    tableView.dataSource = tableViewDS
    tableView.delegate = tableViewDS
    tableView.reloadData()

    lblChartDates.stringValue = playList!.chartDates
    
    if !isSinglesMode {
      minPlayCount = Int.max
      for entry in playList!.chartEntries {
        if let album = entry.bestAlbum {
          minPlayCount = min(minPlayCount, album.playCount)
  //        print("\(album.title) \(album.playCount)")
        }
      }
    }

  }
    
  func playChart(date:Date) {
      
    setupChart(date: date)

    playerState = .PlayingShow
    
    playIndex = 0

    if isSinglesMode {
      
 //     playIndex = playList!.startIndex

      let message = " . Welcome to the Chart Show! Here is The UK chart for \(playList!.dateString)."
          
      dj.addItem(announcement: message, chartEntry: nil, index: -1)
    }
    else {
      
      playIndex = cboTop.stringValue == "Highest to Lowest" ? 0 : playList!.chartEntries.count - 1
      
      var found = false
      
      if let album = playList?.chartEntries[playIndex].bestAlbum {
        if !skipRecentlyPlayed || album.playCount == minPlayCount {
          albumPlayer(album: album, delegate: self, startAtBeginning: true)
          found = true
        }
      }
      
      if !found {
        playNextAlbum()
      }
      
    }
  }
  
  var skipRecentlyPlayed : Bool {
    get {
      return UserDefaults.standard.bool(forKey: DEFAULT.SKIP_RECENTLY_PLAYED)
    }
  }
  
  func playNextAlbum() {
    
    let highestToLowest = cboTop.stringValue == "Highest to Lowest"
    
    playIndex += highestToLowest ? +1 : -1
    
    var atEnd = (highestToLowest && playIndex == playList!.chartEntries.count) ||
    (!highestToLowest && playIndex == 0)
    
    while !atEnd {
      if let album = playList!.chartEntries[playIndex].bestAlbum {
        if !skipRecentlyPlayed || album.playCount == minPlayCount {
          albumPlayer(album: album, delegate: self, startAtBeginning: true)
          break
        }
      }
      playIndex += highestToLowest ? +1 : -1
      atEnd = (highestToLowest && playIndex == playList!.chartEntries.count) ||
      (!highestToLowest && playIndex == 0)
    }
    
  }
    
  func queueTrackAndIntro()
  {

    var done = false
    
    var nextMessage = ""

    if let plist = playList {

      if isSinglesMode {
        
        while !done && playIndex >= 0 {
            
          let entry = plist.chartEntries[playIndex]

          if entry.chartListing.UKChartTitle + entry.chartListing.ArtistObj.UKChartName != lastSong {

            lastSong = entry.chartListing.UKChartTitle  + entry.chartListing.ArtistObj.UKChartName
            
            if Int(entry.Position)! == 1 {
              
              if entry.LastPosition == "New" {
                nextMessage += "Straight in at number one is "
              }
              else {
                nextMessage += "And this weeks' number one is "
              }
              
              nextMessage += "\(entry.chartListing.ArtistObj.ArtistNameClean) with \(entry.chartListing.UKChartTitleClean)! "
              
            }
            else if entry.LastPosition == "Re" {
              nextMessage += "Re-entry at number \(Int(entry.Position)!) for \(entry.chartListing.ArtistObj.ArtistNameClean), with \(entry.chartListing.UKChartTitleClean). "
            }
            else if entry.LastPosition == "New" {
              nextMessage += "New entry at number \(Int(entry.Position)!) for \(entry.chartListing.ArtistObj.ArtistNameClean) with \(entry.chartListing.UKChartTitleClean). "
            }
            else if Int(entry.LastPosition)! > Int(entry.Position)! {
              nextMessage += "Up from \(Int(entry.LastPosition)!) to \(Int(entry.Position)!) for \(entry.chartListing.ArtistObj.ArtistNameClean) with \(entry.chartListing.UKChartTitleClean). "
            }
            else if Int(entry.LastPosition)! < Int(entry.Position)! {
              nextMessage += "Down from \(Int(entry.LastPosition)!) to \(Int(entry.Position)!) for \(entry.chartListing.ArtistObj.ArtistNameClean), with \(entry.chartListing.UKChartTitleClean). "
            }
            else {
              nextMessage += "Non-Mover at number \(Int(entry.Position)!) for \(entry.chartListing.ArtistObj.ArtistNameClean), with \(entry.chartListing.UKChartTitleClean). "
            }
   
          }
            
          playIndex -= 1
          
          if let _ = entry.bestTrack {
            dj.addItem(announcement: nextMessage, chartEntry: entry, index: playIndex + 1)
            done = true
            nextMessage = ""
          }
          
        }
      }
      else {
        
        while !done && playIndex >= 0 {
            
          let entry = plist.chartEntries[playIndex]
            
          playIndex -= 1
          
          if let album = entry.bestAlbum {
            albumPlayer(album: album, delegate: self, startAtBeginning: true)
            done = true
          }
          
        }
 
      }
    }

    if isSinglesMode && playerState != .Stop && !done {
      nextMessage += "And that was the chart for \(playList!.dateString). Thank You for listening!"
      dj.addItem(announcement: nextMessage, chartEntry: nil, index: -1)
      playerState = .Stop
    }

  }
  
  func djQueueNextItem(sender: DJ) {
    queueTrackAndIntro()
  }
  
  private var repeatCount = 0
  
  func djDidFinishShow(sender: DJ) {
    
    if playerState == .Stop {
      let repeatMode = RepeatMode(rawValue:UserDefaults.standard.integer(forKey: DEFAULT.REPEAT))
      let shuffle = UserDefaults.standard.bool(forKey: DEFAULT.SHUFFLE)
      if shuffle {
        if repeatMode! == .All {
          playerState = .Start
          djPlay()
        }
        else if repeatMode! == .One && repeatCount == 0 {
          repeatCount += 1
          playerState = .Start
          djPlay()
        }
        else {
          repeatCount = 0
        }
      }
      else if repeatMode! == .All {
        playerState = .Start
        djPlay()
      }
      else if repeatMode! == .One && repeatCount == 0 {
        repeatCount += 1
        playerState = .Start
        djPlay()
      }
      else {
        repeatCount = 0
      }
    }
    
    playerState = .Start
    
  }

  private var nowPlayingIndex : Int = -1
  private var completedRunningTime : Int = 0
  
  func djNowPlaying(sender: DJ, message: String, index: Int) {
    view.window?.title = message
    nowPlayingIndex = index
    if index == -1 {
      tableView.deselectAll(self)
      lblTimeToDo.stringValue = ""
      lblTimeDone.stringValue = ""
      lblTotalTimeDone.stringValue = ""
      lblTotalTimeToDo.stringValue = ""
      progressIndicator.isHidden = true
      progressTotalIndicator.isHidden = true
    }
    else {
      progressIndicator.isHidden = false
      progressTotalIndicator.isHidden = false
      tableView.selectRowIndexes(.init(integer: index), byExtendingSelection: false)
      completedRunningTime = playList!.runningTime(nowPlayingIndex: index)
      totTime = playList!.runningTime(nowPlayingIndex: -1)
      totDone = playList!.runningTime(nowPlayingIndex: nowPlayingIndex)
    }
  }

  func djPauseChanged(sender: DJ, value: Bool) {
    if value {
      btnPlay.image = NSImage(named: "NSTouchBarPlayTemplate")
    }
    else {
      btnPlay.image = NSImage(named: "NSTouchBarPauseTemplate")
    }
  }
  
  func djUpdateMeters(sender: DJ, leftValue: Float, rightValue: Float) {
    levelLeft.floatValue = leftValue
    levelRight.floatValue = rightValue
  }
  
  func albumPlayerPlayNextItem(sender: AlbumPlayerVC) {
    playNextAlbum()
  }
  
  func albumPlayerStop(sender: AlbumPlayerVC) {
    playerState = .Start
  }
  
  func albumPlayerUpdateMeters(sender: AlbumPlayerVC, leftValue: Float, rightValue: Float) {
    levelLeft.floatValue = leftValue
    levelRight.floatValue = rightValue
  }
  
  func albumPlayerUpdateProgress(sender: AlbumPlayerVC, progress: Double, totalTime: Int) {
    
  }
  


  private var totTime : Int = 0
  private var totDone : Int = 0
  
  func djUpdateProgress(sender: DJ, progress: Double, totalTime: Int) {
    progressIndicator.doubleValue = progress
    let timeDone = Int(Double(totalTime) * progress / 100.0)
    let timeToDo = totalTime - timeDone
    lblTimeDone.stringValue = timeString(milliseconds: timeDone)
    lblTimeToDo.stringValue = timeString(milliseconds: timeToDo)
    let totD = totDone + timeDone
    let totToDo = totTime - totD
    lblTotalTimeDone.stringValue = timeString(milliseconds: totD)
    lblTotalTimeToDo.stringValue = timeString(milliseconds: totToDo)
    let totalProgress = Double(totD) / Double(totTime) * 100.0
    progressTotalIndicator.doubleValue = totalProgress
  }
  
  @IBOutlet weak var tableView: NSTableView!
  
  @IBAction func btnSelect(_ sender: NSButton) {
    setupChart(date: getDate())
  }
  
  @IBOutlet weak var datePickerOutlet: NSDatePickerCell!
  
  @IBAction func datePicker(_ sender: NSDatePickerCell) {
  }

  @IBAction func selectClick(_ sender: NSButton) {
    selectOverride(chartListing: playList!.chartEntries[sender.tag].chartListing, sideIndex: playList!.chartEntries[sender.tag].Index)
    tableView.reloadData()
  }
  
  func getDate() -> Date {
    
    var date = datePickerOutlet.dateValue
    
    let shuffle = UserDefaults.standard.bool(forKey: DEFAULT.SHUFFLE)
    
    if shuffle {

      var minYear = 1953
      
      let shuffleFrom = UserDefaults.standard.string(forKey: DEFAULT.SHUFFLE_FROM) ?? "1953"

      if let f = Int(shuffleFrom) {
        minYear = f
      }
      
      var calendar = Calendar.current
      calendar.timeZone = TimeZone(secondsFromGMT: 0)!
      
      var maxYear  = max(1953, calendar.component(.year, from: date))
      
      let shuffleTo = UserDefaults.standard.string(forKey: DEFAULT.SHUFFLE_TO) ?? "TODAY"

      if shuffleTo != "TODAY" {
        if let t = Int(shuffleTo) {
          maxYear = t
        }
      }
      
      if !isSinglesMode {
        minYear = max(minYear, 1957)
        maxYear = max(maxYear, 1957)
      }
      
      let playCount = PlayCount.lowestRandomYear(fromYear: minYear, toYear: maxYear)

      playCount.incrementPlayCount()
      
      let month = calendar.component(.month, from: date)
      let day   = calendar.component(.day,   from: date)
      let isoDate = String(format: "%04d-%02d-%02dT00:00:00Z", playCount.year, month, day)
      let dateFormatter = ISO8601DateFormatter()
      
      date = dateFormatter.date(from:isoDate)!
    }
    
    return date
  }
  
  public func djPlay() {
    if playerState == .Start && dj.queueEmpty {
       playChart(date: getDate())
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
  
  @IBAction func btnPlayClick(_ sender: NSButton) {
    djPlay()
  }
  
  @IBOutlet weak var btnPlay: NSButton!
  
  public func djRewind() {
    dj.rewind()
  }
  
  @IBAction func btnRewindClick(_ sender: NSButton) {
    djRewind()
  }
  
  @IBOutlet weak var btnRewind: NSButton!
  
  public func djFastForward() {
    dj.fastForward()
  }
  
  @IBAction func btnFastForwardClick(_ sender: Any) {
    djFastForward()
  }
  
  @IBOutlet weak var btnFastForward: NSButton!
  
  @IBAction func cboTopAction(_ sender: NSComboBox) {
    if isSinglesMode {
      UserDefaults.standard.set(cboTop.stringValue, forKey: DEFAULT.TOP_LIMIT)
    }
    else {
      UserDefaults.standard.set(cboTop.stringValue, forKey: DEFAULT.TOP_LIMIT_ALBUMS)
    }
  }
  
  @IBOutlet weak var cboTop: NSComboBox!
  
  @IBOutlet weak var btnStop: NSButton!
  
  public func djStop() {
    dj.stop()
  }
  
  @IBAction func btnStopClick(_ sender: Any) {
    djStop()
  }
  
  @IBOutlet weak var chkAnnounceSongs: NSButton!
  
  @IBAction func chkAnnounceSongsClick(_ sender: NSButton) {
    dj.announcer = sender.state == .on
    UserDefaults.standard.set(dj.announcer, forKey: DEFAULT.ANNOUNCER)
}
  
  @IBAction func tableViewDoubleClick(_ sender: NSTableView) {
    let index = sender.selectedRow
    if index != -1 {
      dj.stop()
      playerState = .PlayingShow
      playIndex = index
      lastSong = ""
      queueTrackAndIntro()
    }
  }
  
  @IBOutlet weak var lblChartDates: NSTextField!
  
  @IBOutlet weak var levelLeft: NSLevelIndicator!
  
  @IBOutlet weak var levelRight: NSLevelIndicator!
  
  @IBOutlet weak var progressIndicator: NSProgressIndicator!
  
  @IBOutlet weak var progressTotalIndicator: NSProgressIndicator!
  
  @IBOutlet weak var lblTimeDone: NSTextField!
  
  @IBOutlet weak var lblTimeToDo: NSTextField!
  
  @IBOutlet weak var lblTotalTimeDone: NSTextField!
  @IBOutlet weak var lblTotalTimeToDo: NSTextFieldCell!
  @IBOutlet weak var cboMode: NSComboBox!
  
  @IBAction func cboModeAction(_ sender: NSComboBox) {
    UserDefaults.standard.set(cboMode.stringValue, forKey: DEFAULT.MODE)
    setupView()
  }
  
  @IBOutlet weak var colSong: NSTableColumn!
  
}

