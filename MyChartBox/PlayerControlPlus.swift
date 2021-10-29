//
//  PlayerControlPlus.swift
//  MyChartBox
//
//  Created by Paul Willmott on 16/01/2021.
//  Copyright © 2021 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation

class PlayerControlPlus : PlayerControl, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate
{
  
  // Constructor
  
  override open func setup() {
    super.setup()
    setButtons()
    synthesizer.delegate = self
  }
  
  // Private Properties
  
  private var playIndex : Int = 0
  
  private let updateInterval = 0.05

  private var timer: Timer?
  
  private var _sortOrder : SortOrder = .ascending
  
  private var _startPosition : StartPosition = .first
  
  private var initPlayIndexDone : Bool = false
  
  private var albumVolume : Float = 1.0
  
  private var playList : [PlayListItem] = []
  
  private var _chartPlayerDelegate : ChartPlayerDelegate?
  
  private var synthesizer = AVSpeechSynthesizer()
  
  private var utterance = AVSpeechUtterance()
  
  private var voice = AVSpeechSynthesisVoice(language: "en-GB")
  
  private var restartPoint : Int = 0
  
  // Public Properties
  
  public var albumPlayerDelegate : AlbumPlayerDelegate?
  
  public var chartPlayerDelegate : ChartPlayerDelegate? {
    get {
      return _chartPlayerDelegate
    }
    set(value) {
      _chartPlayerDelegate = value
      setButtons()
    }
  }
  
  public var viewController : NSViewController?
  
  public var tableView: NSTableView?
  
  public var isAlbumMode : Bool = false
  
  public var announceSongs : Bool = false
  
  public var startAnnouncement : String = ""
  
  public var endAnnouncement : String = ""

  public var durationOfPlaylist : Int = 0
  
  public var allowDuplicates : Bool = false
  
  public var programmeMode : ProgrammeMode = .All

  public var sortOrder : SortOrder {
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
  
  public var durationOfCompletedTracks : Int {
    get {
      var duration : Int = 0
      for pos in 0..<playIndex {
        duration += playList[pos].track.mediaItem.totalTime
      }
      return duration
    }
  }
  
  // Private Methods
  
  private func setButtons() {
    
    btnBackward.isEnabled = isPlaying && (playIndex > 0 || isAlbumMode)
    btnStop.isEnabled = isPlaying || isAlbumMode
    btnPlay.isEnabled = playList.count > 0 || chartPlayerDelegate != nil
    btnForward.isEnabled = isPlaying && (playIndex < playList.count - 1 || isAlbumMode)

    albumPlayerDelegate?.updateState(sender: self)

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
  
  private func startMeters() {
    
    stopMeters()
    
    timer = Timer.scheduledTimer(timeInterval: updateInterval,
                                 target: self,
                                 selector: #selector(self.timerTick),
                                 userInfo: nil,
                                 repeats: true)
    RunLoop.current.add(timer!, forMode: .common)
    
  }

  private func stopMeters() {
    
    isProgressHidden = true

    guard timer != nil, timer!.isValid else {
      return
    }

    timer?.invalidate()
    
    timer = nil
    
    playlistFinished()
    
  }
  
  @objc private func timerTick() {
    
    let player = playList[playIndex].player
    let duration = durationOfCompletedTracks
    updateMeters(player: player)
    updateProgressIndicators(player: player, durationOfCompletedTracks: duration, durationOfPlaylist: durationOfPlaylist)
    albumPlayerDelegate?.updateMeters(player: player)
    albumPlayerDelegate?.updateProgressIndicators(player: player, durationOfCompletedTracks: duration, durationOfPlaylist: durationOfPlaylist)

  }

  private func speak(message:String) {
    utterance = AVSpeechUtterance(string: message)
    utterance.voice = voice
    utterance.volume = 0.5
    synthesizer.speak(utterance)
  }
  
  private func startPlayer() {

    if !initPlayIndexDone {
      playIndex = _startPosition == .first ? 0 : playList.count - 1
      initPlayIndexDone = true
    }

    let playListItem = playList[playIndex]

    if playerState == .stopped && announceSongs && playListItem.announcement.count > 0 {
      
      playerState = .speaking
      
      restartPoint = 0

      var message = playListItem.announcement
      if playIndex == 0 {
        message = startAnnouncement + " " + message
      }
      
      speak(message: message)
      
    }
    else {
      
      playerState = .playing

      chartPlayerDelegate?.nowPlaying(sender: self, index: playListItem.index)
      playListItem.player.volume = isAlbumMode ? albumVolume : playListItem.track.volume
      playListItem.player.currentTime = 0.0
      playListItem.player.play()
      
      startMeters()
      
      tableView?.selectRowIndexes(.init(integer: playListItem.index), byExtendingSelection: false)

      setButtons()
      
    }
    
  }
  
  private func stopPlayer() {
    
    if isPlaying {
      
      if playerState == .speaking {
        
        synthesizer.stopSpeaking(at: .word)
        
      }
      else {

        stopMeters()
    
        playList[playIndex].player.stop()
  
        chartPlayerDelegate?.nowPlaying(sender: self, index: -1)
    
      }
      
      playerState = .stopped
    
      setButtons()
      
    }
    
  }
  
  private func nextProgramme() {
    
    var playAgain = false
    
    albumPlayerDelegate?.nextAlbum(sender: self)

    if let delegate = chartPlayerDelegate {
      playAgain = delegate.endOfProgramme(sender: self)
      removeAll()
      if playAgain {
        delegate.nextChart(sender: self)
        setStartIndex()
        startPlayer()
      }
    }
    
    if !playAgain {
      stopMeters()
    }

  }
  
  // Open Methods
  
  // Public Methods
  
  override func playlistFinished() {
    super.playlistFinished()
    tableView?.deselectAll(self)
  }
  
  override public func backwards() {
    
    guard btnBackward.isEnabled else {
      return
    }
    
    stopPlayer()
      
    playIndex -= 1
    
    if playIndex < 0 {
      playIndex = 0
      playlistFinished()
      albumPlayerDelegate?.previousAlbum(sender: self)
    }
    else {
      startPlayer()
    }
    
  }
  
  override public func stop() {
 
    guard btnStop.isEnabled else {
      return
    }
    
    stopPlayer()
    
    playIndex = 0
    
    albumPlayerDelegate?.stop(sender: self)
    
    viewController?.view.window?.close()
    
    if chartPlayerDelegate != nil {
      removeAll()
    }
    
  }
  
  override public func play() {
    
    guard btnPlay.isEnabled else {
      return
    }
    
    if playList.count == 0 {
      chartPlayerDelegate?.nextChart(sender: self)
      setStartIndex()
    }
    
    switch playerState {
    case .playing:
      playerState = .playingPaused
      playList[playIndex].player.pause()
      break
    case .playingPaused:
      playerState = .playing
      playList[playIndex].player.play()
      break
    case .speaking:
      playerState = .speakingPaused
      synthesizer.stopSpeaking(at: .word)
      break
    case .speakingPaused:
      playerState = .speaking
      let announcement = playList[playIndex].announcement
      let message = String(announcement.suffix(announcement.count - restartPoint))
      speak(message: message)
      break
    default:
      startPlayer()
      break
    }
    
    albumPlayerDelegate?.updateState(sender: self)

  }
  
  override public func forwards() {

    guard btnForward.isEnabled else {
      return
    }
    
    stopPlayer()
    
    playIndex += 1
    
    if playIndex < playList.count {
      startPlayer()
    }
    else {
      playIndex = 0
      albumPlayerDelegate?.nextAlbum(sender: self)
    }
  
  }
  
  override public func volumeUp() {
    if isPlaying && !isAlbumMode {
      let playListItem = playList[playIndex]
      let track = playListItem.track
      playListItem.player.volume = min(1.0, track.volume + 0.05)
      track.volume = playListItem.player.volume
    }
  }
  
  override public func volumeDown() {
    if isPlaying && !isAlbumMode {
      let playListItem = playList[playIndex]
      let track = playListItem.track
      playListItem.player.volume = max(0.0, track.volume - 0.05)
      track.volume = playListItem.player.volume
    }
  }
  
  override public func volumeReset() {
    if isPlaying && !isAlbumMode {
      let playListItem = playList[playIndex]
      let track = playListItem.track
      playListItem.player.volume = track.baseVolume
      track.volume = playListItem.player.volume
    }
  }

  override public func play(at:Int) {
    
    var pos : Int = 0
    
    if sortOrder == .ascending {
      for item in playList {
        if item.index >= at {
          break
        }
        pos += 1
      }
    }
    else {
      for item in playList {
        if item.index <= at {
          break
        }
        pos += 1
      }
    }
    
    if pos < playList.count {
      stopPlayer()
      playIndex = pos
      initPlayIndexDone = true
      startPlayer()
    }
    
  }
  
  override public func stopPlaylist() {
    removeAll()
    viewController?.view.window?.close()
  }

  public func add(track:MusicTrack, at:Int, announcement:String = "") {

    if let url = track.mediaItem.location {
      
      if !allowDuplicates {
        for playListItem in playList {
          if playListItem.track.persistentID == track.persistentID {
            return
          }
        }
      }
      
      do {
        
        let player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
        player.isMeteringEnabled = true
        player.delegate = self
        
        playList.append((track:track, index:at, player:player, announcement:announcement))
        
        sortPlayList()
        
        let trackDuration = track.mediaItem.totalTime
        
        if let pos = playListPosition(index: at) {
          if playIndex >= pos {
            playIndex += 1
          }
        }
        
        durationOfPlaylist += trackDuration
        
        albumVolume = 1.0
        for playListItem in playList {
          albumVolume = min(albumVolume, playListItem.track.volume)
        }
        
        setButtons()

      }
      catch
      {
        print("PlayList.add: couldn't load file")
      }
    }
    else {
      print("PlayList.add: bad url: \(track.location)")
    }
    
  }
  
  public func remove(at:Int) {
    
    if let pos = playListPosition(index: at) {
      
      let trackDuration = playList[pos].track.mediaItem.totalTime
      
      durationOfPlaylist -= trackDuration
      
      if playIndex >= pos {
        playIndex -= 1
      }
      
      playList.remove(at: pos)
      
    }
    
    setButtons()

  }
  
  public func replace(track:MusicTrack, at:Int) {
    
    var restart = false
    
    let savePlayIndex = playIndex
    
    if isPlaying && playList[playIndex].index == at {
      stopPlayer()
      restart = true
    }
    remove(at: at)
    add(track: track, at: at)
    
    if restart {
      playIndex = savePlayIndex
      startPlayer()
    }
    
  }
  
  public func removeAll() {
    stopPlayer()
    playList.removeAll()
    playIndex = 0
    durationOfPlaylist = 0
  }
  
  public var startPosition : StartPosition {
    get {
      return _startPosition
    }
    set(value) {
      if _startPosition != value {
        _startPosition = value
        initPlayIndexDone = false
      }
    }
  }
  
  public func setStartIndex() {
    
    var runTime : Double = 0.0
    
    var index : Int = 0
    
    initPlayIndexDone = true
    
    switch programmeMode {
    case .All:
      playIndex = 0
      return
    case .MaxRuntime:
      runTime = Double(UserDefaults.standard.integer(forKey: DEFAULT.MAX_RUNTIME)) * 60.0 * 1000.0
      break
    case .TargetTime:
      let hours = UserDefaults.standard.integer(forKey: DEFAULT.TARGET_TIME_HOUR)
      let minutes = UserDefaults.standard.integer(forKey: DEFAULT.TARGET_TIME_MINUTES)
      let dateNow = Date()
      var dateTarget = Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: dateNow)!
      if dateTarget < dateNow {
        dateTarget.addTimeInterval(24 * 60 * 60)
      }
      runTime = Double((dateTarget.timeIntervalSince1970 - dateNow.timeIntervalSince1970) * 1000)
      break
    }
    
    let ms = runTime
    var total = 0.0
    index = playList.count - 1
    while index >= 0 {
      let entry = playList[index].track
      let tt : Double = Double(entry.mediaItem.totalTime)
      if total + tt <= ms {
        total += tt
      }
      else {
        playIndex = index + 1
        return
      }
      index -= 1
    }
    
    playIndex = index + 1

  }
  
  // Audio Player Delegate Functions
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                   successfully flag: Bool) {
    
    stopPlayer()
    
    playIndex += 1
    
    if playIndex < playList.count {
      startPlayer()
    }
    else if announceSongs && endAnnouncement != "" {
      playerState = .speaking
      speak(message: endAnnouncement)
    }
    else {
      nextProgramme()
    }
    
    setButtons()
    
  }
  
  // Synthesizer Delegate Functions
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
  willSpeakRangeOfSpeechString characterRange: NSRange,
  utterance: AVSpeechUtterance) {
    restartPoint = characterRange.upperBound
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    if playIndex < playList.count {
      startPlayer()
    }
    else {
      nextProgramme()
    }
  }

}

public enum SortOrder {
  case ascending
  case descending
}

public enum StartPosition {
  case first
  case last
}

protocol ChartPlayerDelegate: AnyObject {
  func nextChart(sender:PlayerControlPlus)
  func nowPlaying(sender:PlayerControlPlus, index:Int)
  func endOfProgramme(sender:PlayerControlPlus) -> Bool
}

protocol AlbumPlayerDelegate: AnyObject {
  func previousAlbum(sender: PlayerControlPlus)
  func nextAlbum(sender: PlayerControlPlus)
  func stop(sender: PlayerControlPlus)
  func updateMeters(player:AVAudioPlayer)
  func updateProgressIndicators(player:AVAudioPlayer, durationOfCompletedTracks:Int, durationOfPlaylist:Int)
  func updateState(sender:PlayerControlPlus)
}

typealias PlayListItem = (track:MusicTrack, index:Int, player:AVAudioPlayer, announcement:String)


