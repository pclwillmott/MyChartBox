//
//  AppDelegate.swift
//  MyChartBox
//
//  Created by Paul Willmott on 05/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  // Application Control Functions
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Insert code here to initialize your application
    
    let appFolder  = "/MyChartBox"
    let libFolder  = "/MyChartBox Library"
    let dataFolder = "/MyChartBox Database"
    
    if let _ = UserDefaults.standard.string(forKey: DEFAULT.VERSION) {
    }
    else {
      
      UserDefaults.standard.set("Version 1.0", forKey: DEFAULT.VERSION)
      
      let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as [String]
      
      UserDefaults.standard.set(paths[0] + appFolder + dataFolder, forKey: DEFAULT.DATABASE_PATH)
      
      UserDefaults.standard.set(paths[0] + appFolder + libFolder,  forKey: DEFAULT.LIBRARY_PATH)
      
      UserDefaults.standard.set("Top 40", forKey: DEFAULT.TOP_LIMIT)
      
      UserDefaults.standard.set(true, forKey: DEFAULT.ANNOUNCER)

      UserDefaults.standard.set(false, forKey: DEFAULT.SHUFFLE)

      UserDefaults.standard.set(RepeatMode.Off.rawValue, forKey: DEFAULT.REPEAT)
      
      UserDefaults.standard.set("1953", forKey: DEFAULT.SHUFFLE_FROM)
      UserDefaults.standard.set("TODAY", forKey: DEFAULT.SHUFFLE_TO)

    }
    
    let shuffle = UserDefaults.standard.bool(forKey: DEFAULT.SHUFFLE)
    
    shuffleOn.state = (shuffle) ? .on : .off
    shuffleOff.state = (shuffle) ? .off : .on
    
    repeatAll.state = .off
    repeatOff.state = .off
    repeatOne.state = .off
    
    let repeatMode = RepeatMode(rawValue:UserDefaults.standard.integer(forKey: DEFAULT.REPEAT))
    
    switch repeatMode {
    case .All:
      repeatAll.state = .on
    case .One:
      repeatOne.state = .on
    case .Off:
      repeatOff.state = .on
    case .none:
      break
    }
    
  }
  
  // Outlets
  
  @IBOutlet weak var play: NSMenuItem!
  @IBOutlet weak var stop: NSMenuItem!
  @IBOutlet weak var next: NSMenuItem!
  @IBOutlet weak var previous: NSMenuItem!
  
  // Artists Menu Actions
  
  // Charts Menu Actions
  
  @IBAction func playAction(_ sender: NSMenuItem) {
    if let window = NSApp.keyWindow, let vc = window.contentViewController  {
      let playerView = vc as! PlayerViewDelegate
      let playerControl = playerView.playerControlInstance()
      playerControl.play()
    }
  }
  
  @IBAction func stopAction(_ sender: NSMenuItem) {
    if let window = NSApp.keyWindow, let vc = window.contentViewController  {
      let playerView = vc as! PlayerViewDelegate
      let playerControl = playerView.playerControlInstance()
      playerControl.stop()
    }
  }
  
  @IBAction func nextAction(_ sender: NSMenuItem) {
    if let window = NSApp.keyWindow, let vc = window.contentViewController  {
      let playerView = vc as! PlayerViewDelegate
      let playerControl = playerView.playerControlInstance()
      playerControl.forwards()
    }
  }
  
  @IBAction func previousAction(_ sender: NSMenuItem) {
    if let window = NSApp.keyWindow, let vc = window.contentViewController  {
      let playerView = vc as! PlayerViewDelegate
      let playerControl = playerView.playerControlInstance()
      playerControl.backwards()
    }
  }
  
  @IBAction func volumeUpAction(_ sender: NSMenuItem) {
    if let window = NSApp.keyWindow, let vc = window.contentViewController  {
      let playerView = vc as! PlayerViewDelegate
      let playerControl = playerView.playerControlInstance()
      playerControl.volumeUp()
    }
  }
  
  @IBAction func volumeDownAction(_ sender: NSMenuItem) {
    if let window = NSApp.keyWindow, let vc = window.contentViewController  {
      let playerView = vc as! PlayerViewDelegate
      let playerControl = playerView.playerControlInstance()
      playerControl.volumeDown()
    }
  }
  
  @IBAction func volumeResetAction(_ sender: NSMenuItem) {
    if let window = NSApp.keyWindow, let vc = window.contentViewController  {
      let playerView = vc as! PlayerViewDelegate
      let playerControl = playerView.playerControlInstance()
      playerControl.volumeReset()
    }
  }
  
  // Unsorted

  @IBAction func preferencesClick(_ sender: NSMenuItem) {
    preferences()
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  @IBAction func djPlay(_ sender: NSMenuItem) {
    if #available(OSX 10.14, *) {
      if let window = NSApp.keyWindow, let vc = window.contentViewController  {
        let playerView = vc as! PlayerViewDelegate
        let playerControlPlus = playerView.playerControlInstance()
        playerControlPlus.play()
      }
    }
  }
  
  @IBAction func djStop(_ sender: NSMenuItem) {
    if #available(OSX 10.14, *) {
      if let window = NSApp.keyWindow, let vc = window.contentViewController  {
        let djVC = vc as! DJController
        djVC.djStop()
      }
    }
  }
  
  @IBAction func djNext(_ sender: NSMenuItem) {
    if #available(OSX 10.14, *) {
      if let window = NSApp.keyWindow, let vc = window.contentViewController  {
        let djVC = vc as! DJController
        djVC.djFastForward()
      }
    }
  }
  
  @IBAction func djRewind(_ sender: NSMenuItem) {
    if #available(OSX 10.14, *) {
      if let window = NSApp.keyWindow, let vc = window.contentViewController  {
        let djVC = vc as! DJController
        djVC.djRewind()
      }
    }
  }
  
  @IBAction func shuffleOnClick(_ sender: NSMenuItem) {
    shuffleOn.state = .on
    shuffleOff.state = .off
    UserDefaults.standard.set(true, forKey: DEFAULT.SHUFFLE)
    /*
    repeatAll.state = .off
    repeatOff.state = .on
    repeatOne.state = .off
    UserDefaults.standard.set(RepeatMode.Off.rawValue, forKey: DEFAULT.REPEAT)
 */
  }
  
  @IBOutlet weak var shuffleOn: NSMenuItem!
  
  @IBAction func shuffleOffClick(_ sender: NSMenuItem) {
    shuffleOn.state = .off
    shuffleOff.state = .on
    UserDefaults.standard.set(false, forKey: DEFAULT.SHUFFLE)
  }
  
  @IBOutlet weak var shuffleOff: NSMenuItem!
  
  @IBAction func repeatOffClick(_ sender: NSMenuItem) {
    repeatAll.state = .off
    repeatOff.state = .on
    repeatOne.state = .off
    UserDefaults.standard.set(RepeatMode.Off.rawValue, forKey: DEFAULT.REPEAT)
  }
  
  @IBOutlet weak var repeatOff: NSMenuItem!
  
  @IBAction func repearAllClick(_ sender: NSMenuItem) {
    repeatAll.state = .on
    repeatOff.state = .off
    repeatOne.state = .off
    UserDefaults.standard.set(RepeatMode.All.rawValue, forKey: DEFAULT.REPEAT)
    /*
    shuffleOn.state = .off
    shuffleOff.state = .on
    UserDefaults.standard.set(false, forKey: DEFAULT.SHUFFLE)
 */
  }
  
  @IBOutlet weak var repeatAll: NSMenuItem!
  
  @IBAction func repeatOneClick(_ sender: NSMenuItem) {
    repeatAll.state = .off
    repeatOff.state = .off
    repeatOne.state = .on
    UserDefaults.standard.set(RepeatMode.One.rawValue, forKey: DEFAULT.REPEAT)
    /*
    shuffleOn.state = .off
    shuffleOff.state = .on
    UserDefaults.standard.set(false, forKey: DEFAULT.SHUFFLE)
 */
  }
  
  @IBAction func controlsClick(_ sender: Any) {
  }
  
  
  @IBOutlet weak var repeatOne: NSMenuItem!
  
  @IBAction func artistsClick(_ sender: NSMenuItem) {
    artistView()
  }
  
  @IBAction func mnuUpdate(_ sender: Any) {
    updateView()
  }
  
  @IBAction func mnuAssociateClick(_ sender: Any) {
    associate()
  }
  
  @IBAction func mnuArtistsSinglesClick(_ sender: Any) {
    artistSinglesPlayer()
  }
  
  @IBAction func mnuArtistsAlbumsClick(_ sender: Any) {
    artistAlbumsPlayer()
  }
  
  @IBAction func mnuChartsSinglesClick(_ sender: Any) {
    chartSinglesPlayer()
  }
  
  @IBAction func mnuChartsAlbumsClick(_ sender: Any) {
    chartAlbumsPlayer()
  }
  
}

public func getMenuItem(tag:Int) -> NSMenuItem? {
  let mainMenu = NSApplication.shared.mainMenu!
  for item in mainMenu.items {
    if let appMenu = item.submenu {
      for menuItem in appMenu.items {
        if menuItem.tag == tag {
          return menuItem
        }
      }
    }
  }
  return nil
}
