//
//  DJ.swift
//  MyChartBox
//
//  Created by Paul Willmott on 07/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation

@available(OSX 10.14, *)
class DJ : NSObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
  
  private var itemQueue : [DJItem] = []
  
  public var queueEmpty : Bool {
    get {
      return itemQueue.count == 0
    }
  }
  
  public var windowTitle = "MyChartBox"
  
  private enum DJStatus {
    case Stopped
    case Speaking
    case Playing
  }
  
  private var status : DJStatus = .Stopped
  
  private var _isPaused : Bool = false
  
  public var isPaused : Bool {
    get {
      return _isPaused
    }
    set(value) {
      _isPaused = value
      delegate?.djPauseChanged(sender: self, value: _isPaused)
    }
  }
  
  private var synthesizer = AVSpeechSynthesizer()
  private var utterance   = AVSpeechUtterance()
  private var voice       = AVSpeechSynthesisVoice(language: "en-GB")
  private var playerQueue : [AVAudioPlayer] = []
  private var trackQueue  : [MusicTrack] = []
  
  private var timer: Timer?
  
  public var announcer : Bool = false
  
  override init() {
    super.init()
    synthesizer.delegate = self
  }
  
  public func addItem(announcement:String, chartEntry:ChartEntry?, index:Int) {
    
    itemQueue.append(DJItem(announcement: announcement, chartEntry: chartEntry, index: index))

    if let entry = chartEntry {
      if let track = entry.bestTrack {
        if let url = URL(string: track.urlLocation) {
          do {
            let player = try AVAudioPlayer(contentsOf: url)
            
            player.delegate = self;
            player.prepareToPlay()
            player.volume = track.volume
            player.isMeteringEnabled = true
            playerQueue.append(player)
            trackQueue.append(track)
          }
          catch
          {
            print("DJ.addItem: couldn't load file - \"\(entry.bestTrack!.location)\"")
          }
        }
        else {
          print("DJ.addItem: URL failed - \"\(track.urlLocation)\"")
        }
      }
    }

    if status == .Stopped {
      play()
    }
    
  }
  
  public func play() {
    
    isPaused = false

    if itemQueue.count == 0 {
      stop() // perform reset to initial state
      return
    }

    if status == .Playing {
      playerQueue[0].play()
      startMeters()
      if let entry = itemQueue[0].chartEntry {
        let pos = (entry.Position == "") ? "" : "\(entry.Position) - "
        let message = "\(pos)\(entry.chartListing.ArtistObj.ArtistName) - \(entry.chartListing.sides[entry.Index].UKChartTitle)"
        delegate?.djNowPlaying(sender: self, message: message, index: itemQueue[0].index)
      }
    }
    else {
      status = .Speaking
      let item = itemQueue[0]
      var message = " "
      if announcer {
        message = String(item.announcement.suffix(item.announcement.count - item.restartPos))
      }
      utterance = AVSpeechUtterance(string: message)
      utterance.voice = voice
      utterance.volume = 0.5
      synthesizer.speak(utterance)
      delegate?.djNowPlaying(sender: self, message: windowTitle, index: -1)
      delegate?.djQueueNextItem(sender: self)
    }

  }
  
  public func pause() {
    
    if !isPaused {
      
      isPaused = true
    
      if status == .Speaking {
        synthesizer.stopSpeaking(at: .word)
      }
      else if status == .Playing {
        playerQueue[0].pause()
      }
      
    }

  }
  
  // The stop() function resets everything to initial state.
  
  public func stop() {
    if status == .Speaking {
      synthesizer.stopSpeaking(at: .word)
    }
    else if status == .Playing {
      playerQueue[0].stop()
      stopMeters()
    }
    itemQueue.removeAll()
    playerQueue.removeAll()
    trackQueue.removeAll()
    status = .Stopped
    isPaused = true
    delegate?.djDidFinishShow(sender: self)
    delegate?.djNowPlaying(sender: self, message: windowTitle, index: -1)
  }
  
  public func fastForward() {
    if itemQueue.count > 0 {
      if status == .Speaking {
        synthesizer.stopSpeaking(at: .word)
      }
      else if status == .Playing {
        playerQueue[0].stop()
      }
      nextItem()
    }
  }
  
  public func volumeUp() {
    if status == .Playing {
      let track = trackQueue[0]
      playerQueue[0].volume = min(1.0, track.volume + 0.05)
      track.volume = playerQueue[0].volume
    }
  }

  public func volumeDown() {
    if status == .Playing {
      let track = trackQueue[0]
      playerQueue[0].volume = max(0.0, track.volume - 0.05)
      track.volume = playerQueue[0].volume
    }
  }
  
  public func volumeReset() {
    if status == .Playing {
      let track = trackQueue[0]
      playerQueue[0].volume = track.baseVolume
      track.volume = playerQueue[0].volume
    }
  }

  private func nextItem() {
    stopMeters()
    if let _ = itemQueue[0].chartEntry {
      playerQueue.remove(at: 0)
      trackQueue.remove(at: 0)
    }
    itemQueue.remove(at: 0)
    status = .Stopped
    play()
  }
  
  public func rewind() {
    if status == .Playing {
      playerQueue[0].currentTime = 0.0
    }
    else if status == .Speaking {
      synthesizer.stopSpeaking(at: .word)
      itemQueue[0].restartPos = 0
      play()
    }
  }
  
  private let updateInterval = 0.05

  func startMeters() {
    timer = Timer.scheduledTimer(timeInterval: updateInterval,
                                 target: self,
                                 selector: #selector(self.updateMeters),
                                 userInfo: nil,
                                 repeats: true)
    RunLoop.current.add(timer!, forMode: .common)
    
  }

  func stopMeters() {
    guard timer != nil, timer!.isValid else {
      return
    }

    timer?.invalidate()
    
    timer = nil
    
    delegate?.djUpdateMeters(sender: self, leftValue: -160.0, rightValue: -160.0)
    delegate?.djUpdateProgress(sender: self, progress: 0.0, totalTime: trackQueue[0].mediaItem.totalTime)
  }
  
  @objc private func updateMeters() {
    
    if playerQueue.count == 0 {
      return
    }
    
    let player = playerQueue[0]
    
    player.updateMeters()
    
    let l = pow(10.0,player.averagePower(forChannel: 0)/20.0) * 100.0
    let r = pow(10.0,player.averagePower(forChannel: 1)/20.0) * 100.0
    
    delegate?.djUpdateMeters(sender: self, leftValue: l, rightValue: r)

    var progress : Double = Double(player.currentTime) / Double(player.duration) * 100.0
    
    if progress > 99.5 {
      progress = 100.0
    }

    let songDuration = trackQueue[0].mediaItem.totalTime
    delegate?.djUpdateProgress(sender: self, progress: progress, totalTime: songDuration)
    
   }
  
  public weak var delegate: DJDelegate?
  
  // Synthesizer Delegations
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
  willSpeakRangeOfSpeechString characterRange: NSRange,
  utterance: AVSpeechUtterance) {
    itemQueue[0].restartPos = characterRange.upperBound
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    if let _ = itemQueue[0].chartEntry {
      status = .Playing
      play()
    }
    else {
      nextItem()
    }
  }
  
  // Player Delegations
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                   successfully flag: Bool) {
    nextItem()
  }

  
}

class DJItem : NSObject {
  
  public var announcement : String = ""
  public var chartEntry   : ChartEntry?
  public var restartPos   : Int    = 0
  public var index        : Int    = -1
  
  init(announcement:String, chartEntry:ChartEntry?, index:Int) {
    super.init()
    self.announcement = announcement
    self.chartEntry   = chartEntry
    self.index        = index
  }
  
}

@available(OSX 10.14, *)
protocol DJDelegate: AnyObject {
  func djQueueNextItem(sender: DJ)
  func djDidFinishShow(sender: DJ)
  func djNowPlaying(sender: DJ, message:String, index:Int)
  func djPauseChanged(sender: DJ, value:Bool)
  func djUpdateMeters(sender:DJ, leftValue:Float, rightValue:Float)
  func djUpdateProgress(sender:DJ, progress:Double, totalTime:Int)
}

protocol DJController: AnyObject {
  func djPlay()
  func djRewind()
  func djFastForward()
  func djStop()
  func djVolumeUp()
  func djVolumeDown()
  func djVolumeReset()
}

enum RepeatMode : Int {
  case Off = 0
  case All = 1
  case One = 2
}

