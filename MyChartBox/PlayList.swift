//
//  PlayList.swift
//  MyChartBox
//
//  Created by Paul Willmott on 08/01/2021.
//  Copyright © 2021 Paul Willmott. All rights reserved.
//

import Foundation
import AVFoundation
import Cocoa

class PlayList : NSObject, PlayerControlDelegate, AVAudioPlayerDelegate {
  
  // Constructor
  
  // Private Properties
  
  private var playIndex : Int = 0
  
  private let updateInterval = 0.05

  private var timer: Timer?
  
  private var _sortOrder : SortOrder = .ascending
  
  private var _startPosition : StartPosition = .first
  
  private var initPlayIndexDone : Bool = false
  
  private var albumVolume : Float = 1.0
  
  private var playIndexSafe : Bool {
    get {
      return playIndex >= 0 && playIndex < playList.count
    }
  }

  // Public Properties
  
  public var playList : [PlayListItem] = []
  
  public var displayDelegate : PlayerDisplayDelegate?
  
  public var albumPlayerDelegate : AlbumPlayerDelegate?
  
  public var chartPlayerDelegate : ChartPlayerDelegate?
  
  public var viewController : NSViewController?
  
  public var tableView: NSTableView?
  
  public var isAlbumMode : Bool = false
  
  public var durationOfPlaylist : Int = 0

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
  
  private func startMeters() {
    
    stopMeters()
    
    timer = Timer.scheduledTimer(timeInterval: updateInterval,
                                 target: self,
                                 selector: #selector(self.updateMeters),
                                 userInfo: nil,
                                 repeats: true)
    RunLoop.current.add(timer!, forMode: .common)
    
  }

  private func stopMeters() {
    
    guard timer != nil, timer!.isValid else {
      return
    }

    timer?.invalidate()
    
    timer = nil
    
  }
  
  @objc private func updateMeters() {
    
    if playIndexSafe {
      let player = playList[playIndex].player
      let duration = durationOfCompletedTracks
      displayDelegate?.updateMeters(player: player)
      displayDelegate?.updateProgressIndicators(player: player, durationOfCompletedTracks: duration, durationOfPlaylist: durationOfPlaylist)
      albumPlayerDelegate?.updateMeters(player: player)
      albumPlayerDelegate?.updateProgressIndicators(player: player, durationOfCompletedTracks: duration, durationOfPlaylist: durationOfPlaylist)
    }
    
  }
  
  private func startPlayer() {
    
    if !initPlayIndexDone {
      playIndex = _startPosition == .first ? 0 : playList.count - 1
      initPlayIndexDone = true
    }
    
    if playIndexSafe {
      let playListItem = playList[playIndex]
//      chartPlayerDelegate?.nowPlaying(sender: self, index: playListItem.index)
      playListItem.player.volume = isAlbumMode ? albumVolume : playListItem.track.volume
      playListItem.player.currentTime = 0.0
      playListItem.player.play()
      startMeters()
      tableView?.selectRowIndexes(.init(integer: playListItem.index), byExtendingSelection: false)
    }
    
  }
  
  private func stopPlayer() {
    if playIndexSafe {
      let player = playList[playIndex].player
      player.stop()
    }
//    chartPlayerDelegate?.nowPlaying(sender: self, index: -1)
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
  
  // Public Methods
  
  public func add(track:MusicTrack, at:Int, announcement:String = "") {

    if let url = track.mediaItem.location {
      
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

  }
  
  public func removeAll() {
    stopMeters()
    stopPlayer()
    displayDelegate?.playlistFinished()
    playList.removeAll()
    playIndex = 0
    durationOfPlaylist = 0
  }
  
  public func play(at:Int) {
    
    stopPlayer()
    
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
    
    if pos == playList.count {
      playIndex = 0
    }
    else {
      playIndex = pos
      initPlayIndexDone = true
      startPlayer()
    }
    
  }
  
  // Player Control Delegate Functions
  
  @objc func play(playerControl:PlayerControl) {
    if playList.count == 0 {
 //     chartPlayerDelegate?.nextChart(sender: self)
    }
    startPlayer()
  }
  
  @objc func play(playerControl:PlayerControl, at:Int) {
    play(at: at)
  }
  
  @objc func pause(playerControl:PlayerControl) {
    if playIndexSafe {
      playList[playIndex].player.pause()
    }
  }
  
  @objc func resume(playerControl:PlayerControl) {
    if playIndexSafe {
      playList[playIndex].player.play()
    }
  }
  
  @objc func backward(playerControl:PlayerControl) {
    
    stopMeters()
    stopPlayer()
    
    playIndex -= 1
    
    if playIndex < 0 {
      playIndex = 0
      displayDelegate?.playlistFinished()
  //    albumPlayerDelegate?.previousAlbum(sender: self)
    }
    else {
      startPlayer()
    }
    
  }
  
  @objc func forward(playerControl:PlayerControl) {
    
    stopMeters()
    stopPlayer()
    
    playIndex += 1
    
    if playIndex < playList.count {
      startPlayer()
    }
    else {
      playIndex = 0
      displayDelegate?.playlistFinished()
  //    albumPlayerDelegate?.nextAlbum(sender: self)
    }
 
  }
  
  @objc func stop(playerControl:PlayerControl) {
    stopMeters()
    stopPlayer()
    displayDelegate?.playlistFinished()
    playIndex = 0
//    albumPlayerDelegate?.stop(sender: self)
    viewController?.view.window?.close()
  }
  
  @objc func stopPlaylist() {
    removeAll()
    displayDelegate?.playlistFinished()
    viewController?.view.window?.close()
  }
  
  // Audio Player Delegate Functions
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                   successfully flag: Bool) {
    
    player.stop()
    
    playIndex += 1
    
    if playIndex < playList.count {
      startPlayer()
    }
    else {

      var playAgain = false
      
 //     albumPlayerDelegate?.nextAlbum(sender: self)

      playIndex = 0

      if let delegate = chartPlayerDelegate {
  //      playAgain = delegate.endOfProgramme(sender: self)
        if playAgain {
   //       delegate.nextChart(sender: self)
          startPlayer()
        }
      }
      
      if !playAgain {
        stopMeters()
        displayDelegate?.playlistFinished()
      }
      
    }
    
  }

}


