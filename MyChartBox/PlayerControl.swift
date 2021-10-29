//
//  PlayerControl.swift
//  MyChartBox
//
//  Created by Paul Willmott on 04/01/2021.
//  Copyright © 2021 Paul Willmott. All rights reserved.
//

import Cocoa
import AVFoundation

public enum PlayerControlState {
  case stopped
  case speaking
  case speakingPaused
  case playing
  case playingPaused
}

class PlayerControl: NSView, PlayerDisplayDelegate {
  
  /*
   * NOTES
   * -----
   *
   * 1). Create a View (xib) file
   * 2). Create a NSView file, this must have the same name as the xib file.
   * 3). Set xib's File Owner to the NSView file
   * 4). Create outlet from the custom control root to contentView
   * 5). Add the code section below between BEGIN and END comments
   * 6). The class of the xib is NSView
   */
  
  // BEGIN
  
  @IBOutlet var contentView: NSView!
  
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setup()
  }

  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    setup()
  }
  
  open func setup() {
    var name = String(describing: type(of: self))
    name = "PlayerControl" // this sets the name back to the parent name
    Bundle.main.loadNibNamed(name, owner: self, topLevelObjects: nil)
    contentView.autoresizingMask = [.width]
    contentView.autoresizesSubviews = true
    let contentFrame = NSMakeRect(0,0,frame.size.width, frame.size.height)
    self.contentView.frame = contentFrame
    self.addSubview(self.contentView)
    isProgressHidden = true
  }

  // END
  
  override func draw(_ dirtyRect:NSRect) {
    super.draw(dirtyRect)
  }
  
  // Public Properties
  
  public var delegate : PlayerControlDelegate?
  
  public var slave : PlayerControl?
  
  public var isProgressHidden : Bool {
    get {
      return _isProgressHidden
    }
    set(value) {
      _isProgressHidden = value
      barTrack.isHidden = _isProgressHidden
      barTotal.isHidden = _isProgressHidden
      lblTimeDone.isHidden = _isProgressHidden
      lblTimeToDo.isHidden = _isProgressHidden
      lblTotalTimeDone.isHidden = _isProgressHidden
      lblTotalTimeToDo.isHidden = _isProgressHidden
    }
  }
  
  public var playerState : PlayerControlState {
    get {
      return _playerState
    }
    set(value) {
      
      _playerState = value
      
      btnPlay.state = _playerState == .playingPaused || _playerState == .stopped || _playerState == .speakingPaused ? .off : .on
      
      if let playMenuItem = getMenuItem(tag:100) {
        playMenuItem.state = btnPlay.state
        playMenuItem.title = isPaused || isStopped ? "Play" : "Pause"
      }
      
    }
  }
  
  public var isPlaying : Bool {
    get {
      return !isStopped
    }
  }
  
  public var isPaused : Bool {
    get {
      return playerState == .playingPaused || playerState == .speakingPaused
    }
  }
  
  public var isStopped : Bool {
    get {
      return playerState == .stopped
    }
  }
  
  // Private Properties
  
  private var _isProgressHidden = false
  
  private var _playerState : PlayerControlState = .stopped

  // Private Methods
  
  
  // Public Methods
  
  public func backwards() {
    if isPlaying {
      playerState = .playing
      delegate?.backward?(playerControl: self)
    }
  }
  
  public func stop() {
    playerState = .stopped
    delegate?.stop?(playerControl: self)
    isProgressHidden = true
  }
  
  public func play() {
    switch playerState {
    case .playing, .speaking:
      playerState = .playingPaused
      delegate?.pause?(playerControl: self)
      break
    case .playingPaused, .speakingPaused:
      playerState = .playing
      delegate?.resume?(playerControl: self)
      break
    default:
      playerState = .playing
      delegate?.play?(playerControl: self)
      break
    }
    if slave != nil  {
      slave?.playerState = self.playerState
    }
  }
  
  public func forwards() {
    if isPlaying {
      playerState = .playing
      btnPlay.state = .on
      delegate?.forward?(playerControl: self)
    }
  }
  
  public func volumeUp() {
    if isPlaying {
      delegate?.volumeUp?(playerControl: self)
    }
  }
  
  public func volumeDown() {
    if isPlaying {
      delegate?.volumeDown?(playerControl: self)
    }
  }
  
  public func volumeReset() {
    if isPlaying {
      delegate?.volumeReset?(playerControl: self)
    }
  }
  
  public func stopPlaylist() {
    delegate?.stopPlaylist?()
  }
  
  public func play(at: Int) {
    playerState = .playing
    delegate?.play?(playerControl: self, at: at)
  }
  
  // Outlets
  
  @IBOutlet weak var btnBackward: NSButton!
  @IBOutlet weak var btnStop: NSButton!
  @IBOutlet weak var btnPlay: NSButton!
  @IBOutlet weak var btnForward: NSButton!
  @IBOutlet weak var levelLeft: NSLevelIndicator!
  @IBOutlet weak var levelRight: NSLevelIndicator!
  @IBOutlet weak var barTrack: NSProgressIndicator!
  @IBOutlet weak var barTotal: NSProgressIndicator!
  @IBOutlet weak var lblTimeDone: NSTextField!
  @IBOutlet weak var lblTotalTimeDone: NSTextField!
  @IBOutlet weak var lblTimeToDo: NSTextField!
  @IBOutlet weak var lblTotalTimeToDo: NSTextField!
  
  // Actions
  
  @IBAction func btnBackwardAction(_ sender: Any?) {
    backwards()
  }
  
  @IBAction func btnStopAction(_ sender: Any?) {
    stop()
  }
  
  @IBAction func btnPlayAction(_ sender: Any?) {
    play()
  }
  
  @IBAction func btnForwardAction(_ sender: Any?) {
    forwards()
  }
  
  // PlayerDisplayDelegate methods
  
  func updateMeters(player: AVAudioPlayer) {
    
    player.updateMeters()
    
    levelLeft.floatValue = pow(10.0,player.averagePower(forChannel: 0)/20.0) * 100.0
    levelRight.floatValue = pow(10.0,player.averagePower(forChannel: 1)/20.0) * 100.0
    
  }
  
  func updateProgressIndicators(player: AVAudioPlayer, durationOfCompletedTracks: Int, durationOfPlaylist: Int) {
    
    let sec2ms = 1000.0
    
    let timeDone      = player.currentTime * sec2ms
    let trackDuration = player.duration * sec2ms
    
    var trackProgress = timeDone / trackDuration * 100.0
    
    if trackProgress > 99.5 {
      trackProgress = 100.0
    }
    
    let timeToDo = trackDuration - timeDone
    let totalDone = durationOfCompletedTracks + Int(timeDone)
    let totalToDo = durationOfPlaylist - totalDone
    
    lblTimeToDo.stringValue = timeString(milliseconds: Int(timeToDo))
    lblTotalTimeToDo.stringValue = timeString(milliseconds: totalToDo)
    lblTimeDone.stringValue = timeString(milliseconds: Int(timeDone))
    lblTotalTimeDone.stringValue = timeString(milliseconds: totalDone)
    
    barTrack.doubleValue = trackProgress
    barTotal.doubleValue = Double(totalDone) / Double(durationOfPlaylist) * 100.0
    
    if isProgressHidden {
      isProgressHidden = false
    }

  }

  func playlistFinished() {
    
    levelLeft.floatValue  = 0.0
    levelRight.floatValue = 0.0
    
    isProgressHidden = true
    
    btnPlay.state = .off

    playerState = .stopped
    
  }

}

@objc protocol PlayerControlDelegate: AnyObject {
  @objc optional func play(playerControl:PlayerControl)
  @objc optional func play(playerControl:PlayerControl, at:Int)
  @objc optional func pause(playerControl:PlayerControl)
  @objc optional func resume(playerControl:PlayerControl)
  @objc optional func backward(playerControl:PlayerControl)
  @objc optional func forward(playerControl:PlayerControl)
  @objc optional func stop(playerControl:PlayerControl)
  @objc optional func stopPlaylist()
  @objc optional func volumeUp(playerControl:PlayerControl)
  @objc optional func volumeDown(playerControl:PlayerControl)
  @objc optional func volumeReset(playerControl:PlayerControl)
}

protocol PlayerDisplayDelegate: AnyObject {
  func updateMeters(player:AVAudioPlayer)
  func updateProgressIndicators(player:AVAudioPlayer, durationOfCompletedTracks:Int, durationOfPlaylist:Int)
  func playlistFinished()
}

protocol PlayerViewDelegate: AnyObject {
  func playerControlInstance()-> PlayerControl
}

