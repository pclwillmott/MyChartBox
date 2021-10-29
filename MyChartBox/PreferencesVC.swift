//
//  PreferencesVC.swift
//  MyChartBox
//
//  Created by Paul Willmott on 22/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa

class PreferencesVC: NSViewController, NSWindowDelegate {

  override func viewDidLoad() {
    
    super.viewDidLoad()
    
    var calendar = Calendar.current
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let maxYear  = calendar.component(.year, from: Date())
    
    cboShuffleTo.addItem(withObjectValue: "TODAY")
    cboAlbumShuffleTo.addItem(withObjectValue: "TODAY")

    for year in 1953 ... maxYear {
      cboShuffleFrom.addItem(withObjectValue: "\(year)")
      cboShuffleTo.addItem(withObjectValue: "\(year)")
      if year > 1956 {
        cboAlbumShuffleFrom.addItem(withObjectValue: "\(year)")
        cboAlbumShuffleTo.addItem(withObjectValue: "\(year)")
      }
    }
    
    cboShuffleFrom.stringValue = UserDefaults.standard.string(forKey: DEFAULT.SHUFFLE_FROM) ?? "1953"
    cboShuffleTo.stringValue = UserDefaults.standard.string(forKey: DEFAULT.SHUFFLE_TO) ?? "TODAY"
    cboAlbumShuffleFrom.stringValue = UserDefaults.standard.string(forKey: DEFAULT.ALBUM_SHUFFLE_FROM) ?? "1957"
    cboAlbumShuffleTo.stringValue = UserDefaults.standard.string(forKey: DEFAULT.ALBUM_SHUFFLE_TO) ?? "TODAY"

    let maxRuntime = Int32(UserDefaults.standard.integer(forKey: DEFAULT.MAX_RUNTIME))
    txtMaxRuntime.intValue = maxRuntime == 0 ? 120 : maxRuntime
    
    let date = Date()
    let hour = UserDefaults.standard.integer(forKey: DEFAULT.TARGET_TIME_HOUR)
    let minutes = UserDefaults.standard.integer(forKey: DEFAULT.TARGET_TIME_MINUTES)
    txtTargetTime.dateValue = Calendar.current.date(bySettingHour: hour, minute: minutes, second: 0, of: date)!
    
    chkSkipBonusTracks.state = UserDefaults.standard.bool(forKey: DEFAULT.SKIP_BONUS_TRACKS) ? .on : .off
    chkSkipLiveTracks.state = UserDefaults.standard.bool(forKey: DEFAULT.SKIP_LIVE_TRACKS) ? .on : .off
    chkSkipDemoTracks.state = UserDefaults.standard.bool(forKey: DEFAULT.SKIP_DEMO_TRACKS) ? .on : .off
    chkSkipRecentlyPlayed.state = UserDefaults.standard.bool(forKey: DEFAULT.SKIP_RECENTLY_PLAYED) ? .on : .off

    chkOnlyPlayChristmasSongsInDecember.state = UserDefaults.standard.bool(forKey: DEFAULT.ONLY_PLAY_CHRISTMAS_SONGS_IN_DECEMBER) ? .on : .off
    
    chkSkipReEntries.state = UserDefaults.standard.bool(forKey: DEFAULT.SKIP_RE_ENTRIES) ? .on : .off

  }
  
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    
    UserDefaults.standard.set(cboShuffleFrom.stringValue, forKey: DEFAULT.SHUFFLE_FROM)
    UserDefaults.standard.set(cboShuffleTo.stringValue, forKey: DEFAULT.SHUFFLE_TO)
    UserDefaults.standard.set(cboAlbumShuffleFrom.stringValue, forKey: DEFAULT.ALBUM_SHUFFLE_FROM)
    UserDefaults.standard.set(cboAlbumShuffleTo.stringValue, forKey: DEFAULT.ALBUM_SHUFFLE_TO)

    let date = txtTargetTime.dateValue
    let calendar = Calendar.current

    UserDefaults.standard.set(txtMaxRuntime.intValue, forKey: DEFAULT.MAX_RUNTIME)

    UserDefaults.standard.set(calendar.component(.hour, from: date), forKey: DEFAULT.TARGET_TIME_HOUR)
    UserDefaults.standard.set(calendar.component(.minute, from: date), forKey: DEFAULT.TARGET_TIME_MINUTES)

    UserDefaults.standard.set(chkSkipBonusTracks.state == .on, forKey: DEFAULT.SKIP_BONUS_TRACKS)
    UserDefaults.standard.set(chkSkipLiveTracks.state == .on, forKey: DEFAULT.SKIP_LIVE_TRACKS)
    UserDefaults.standard.set(chkSkipDemoTracks.state == .on, forKey: DEFAULT.SKIP_DEMO_TRACKS)
    UserDefaults.standard.set(chkSkipRecentlyPlayed.state == .on, forKey: DEFAULT.SKIP_RECENTLY_PLAYED)
    UserDefaults.standard.set(chkOnlyPlayChristmasSongsInDecember.state == .on, forKey: DEFAULT.ONLY_PLAY_CHRISTMAS_SONGS_IN_DECEMBER)
    UserDefaults.standard.set(chkSkipReEntries.state == .on, forKey: DEFAULT.SKIP_RE_ENTRIES)

    stopModal()
    
    return true
    
  }
  
  override func viewDidAppear() {
    self.view.window!.delegate = self
  }
  
  @IBOutlet weak var cboShuffleFrom: NSComboBox!
  @IBOutlet weak var cboShuffleTo: NSComboBox!
  @IBOutlet weak var cboAlbumShuffleFrom: NSComboBox!
  @IBOutlet weak var cboAlbumShuffleTo: NSComboBox!
  
  @IBAction func resetShufflePlayCounts(_ sender: NSButton) {
    PlayCount.resetPlayCounts(chartId: 1)
  }
  
  @IBAction func resetAlbumShufflePlayCounts(_ sender: NSButton) {
    PlayCount.resetPlayCounts(chartId: 2)
  }
  
  @IBAction func resetAlbumPlayCounts(_ sender: NSButton) {
    AlbumPlayCount.resetPlayCounts()
  }
  
  @IBOutlet weak var txtMaxRuntime: NSTextField!
  @IBOutlet weak var txtTargetTime: NSDatePicker!
  
  @IBOutlet weak var chkSkipBonusTracks: NSButton!
  @IBOutlet weak var chkSkipLiveTracks: NSButton!
  @IBOutlet weak var chkSkipDemoTracks: NSButton!
  @IBOutlet weak var chkSkipRecentlyPlayed: NSButton!
  
  @IBOutlet weak var chkOnlyPlayChristmasSongsInDecember: NSButton!
  @IBOutlet weak var chkSkipReEntries: NSButton!
    
}

