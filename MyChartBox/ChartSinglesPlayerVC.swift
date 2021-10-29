//
//  ChartSinglesPlayerVC.swift
//  MyChartBox
//
//  Created by Paul Willmott on 10/01/2021.
//  Copyright © 2021 Paul Willmott. All rights reserved.
//

import Cocoa

class ChartSinglesPlayerVC: NSViewController, ChartPlayerDelegate, PlayerViewDelegate {
  
  // View Control Functions
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
    
    playerControl.isAlbumMode = false
    playerControl.sortOrder = .descending
    playerControl.tableView = tableView
    playerControl.chartPlayerDelegate = self
    
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

    let jd = jdFromDate(date: Date())
    let dt = dateFromJd(jd: jd)
    
    datePicker.maxDate = dt
    datePicker.dateValue = dt

    let announcer = UserDefaults.standard.bool(forKey: DEFAULT.ANNOUNCER)
    chkAnnounceSongs.state = (announcer) ? .on : .off
    playerControl.announceSongs = announcer
    
    lblChartDates.stringValue = ""
    
  }
  
  // Private Properties
  
  private var tableViewDS = MainTableViewDS()
  
  private var programme : Programme!
  
  private var repeatCount : Int = 0

  // Public Properties
  
  // Private Methods
  
  private func setupChart(date:Date) {
    
    let limits = ["Number Ones": 1, "Top 5":5, "Top 10":10, "Top 40":40, "Top 50":50, "Top 75":75, "Top 100":100, "Max Runtime":-1, "Target Time":-2]
    
    let minPosition = limits[cboTop.stringValue] ?? 100
    
    let programmeMode : ProgrammeMode = minPosition == -1 ? .MaxRuntime : minPosition == -2 ? .TargetTime : .All
    
    programme = Programme(isSinglesMode:true, date: date, minPosition: minPosition)
    
    playerControl.programmeMode = programmeMode

    playerControl.startAnnouncement = " . Welcome to the Chart Show! Here is The UK chart for \(programme.dateString)."
    
    playerControl.endAnnouncement = "And that was the chart for \(programme.dateString). Thank You for listening!"

    tableViewDS.chartEntries = programme.chartEntries
    tableView.dataSource = tableViewDS
    tableView.delegate = tableViewDS
    tableView.reloadData()

    lblChartDates.stringValue = programme.chartDates
    
    var lastSong : String = ""
    
    var index = 0
    
    let onlyPlayChristmasSongsInDecember = !programme.isDecember && UserDefaults.standard.bool(forKey: DEFAULT.ONLY_PLAY_CHRISTMAS_SONGS_IN_DECEMBER)
    
    let skipReEntries = UserDefaults.standard.bool(forKey: DEFAULT.SKIP_RE_ENTRIES)

    for chartListing in programme.chartEntries {
      
      let reentry = chartListing.chartListing.UKChartTitle.contains("{") && chartListing.chartListing.UKChartTitle.contains("}")
      
      if let track = chartListing.bestTrack {

        let entry = chartListing.chartListing
        
        var skip = skipReEntries && (reentry || chartListing.LastPosition.uppercased().trimmingCharacters(in: .whitespacesAndNewlines) == "RE")
        
        skip = skip || onlyPlayChristmasSongsInDecember && track.isChristmasSong
        
        if !skip {
        
          let newSong = entry.UKChartTitle  + entry.ArtistObj.UKChartName
          
          var nextMessage : String = ""
          
          if newSong != lastSong {

            lastSong = newSong
            
            let artistName = entry.ArtistObj.ArtistNameClean
            let title = entry.UKChartTitleClean
            let position = Int(chartListing.Position)!
            let lastPosition = Int(chartListing.LastPosition)
            
            if position == 1 {
              
              if chartListing.LastPosition == "New" {
                nextMessage += "Straight in at number one is "
              }
              else {
                nextMessage += "And this weeks' number one is "
              }
              
              nextMessage += "\(artistName) with \(title)! "
              
            }
            else if chartListing.LastPosition == "Re" {
              nextMessage += "Re-entry at number \(position) for \(artistName), with \(title). "
            }
            else if chartListing.LastPosition == "New" {
              nextMessage += "New entry at number \(position) for \(artistName) with \(title). "
            }
            else if lastPosition! > position {
              nextMessage += "Up from \(lastPosition!) to \(position) for \(artistName) with \(title). "
            }
            else if lastPosition! < position {
              nextMessage += "Down from \(lastPosition!) to \(position) for \(artistName), with \(title). "
            }
            else {
              nextMessage += "Non-Mover at number \(position) for \(artistName), with \(title). "
            }
   
          }

          playerControl.add(track: track, at: index, announcement: nextMessage)
          
        }
        
      }
      
      index += 1
    }
    
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
      
      var maxYear  = max(1953, calendar.component(.year, from: date))
      
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

  // Public Methods
  
  // Outlets
  
  @IBOutlet weak var datePicker: NSDatePicker!
  @IBOutlet weak var cboTop: NSComboBox!
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var chkAnnounceSongs: NSButton!
  @IBOutlet weak var btnSelect: NSButton!
  @IBOutlet weak var playerControl: PlayerControlPlus!
  @IBOutlet weak var lblChartDates: NSTextField!
  
  // Actions
  
  @IBAction func chkAnnounceAction(_ sender: NSButton) {
    let announceSongs = sender.state == .on
    playerControl.announceSongs = announceSongs
    UserDefaults.standard.set(announceSongs, forKey: DEFAULT.ANNOUNCER)
  }
  
  @IBAction func datePickerAction(_ sender: NSDatePicker) {
  }
  
  @IBAction func cboTopAction(_ sender: Any) {
    UserDefaults.standard.set(cboTop.stringValue, forKey: DEFAULT.TOP_LIMIT)
  }
  
  @IBAction func tableViewDoubleAction(_ sender: NSTableView) {
    playerControl.play(at: tableView.selectedRow)
  }
  
  @IBAction func btnSelectAction(_ sender: NSButton) {
    setupChart(date: getDate())
  }
  
  @IBAction func btnFindAction(_ sender: NSButton) {
    let chartEntry = programme.chartEntries[sender.tag]
    let isInPlaylist = chartEntry.bestTrack != nil
    let pid = chartEntry.bestTrack?.persistentID ?? -1
    selectOverride(chartListing: chartEntry.chartListing, sideIndex: chartEntry.Index)
    tableView.reloadData()
    if isInPlaylist && chartEntry.bestTrack == nil {
      playerControl.remove(at: sender.tag)
    }
    else if !isInPlaylist && chartEntry.bestTrack != nil {
      playerControl.add(track: chartEntry.bestTrack!, at: sender.tag)
    }
    else if chartEntry.bestTrack != nil && chartEntry.bestTrack!.persistentID != pid {
      playerControl.replace(track: chartEntry.bestTrack!, at: sender.tag)
    }
  }
  
  // Chart Player Delegate Functions
  
  func nextChart(sender: PlayerControlPlus) {
    setupChart(date: getDate())
  }
  
  func endOfProgramme(sender: PlayerControlPlus) -> Bool {
   
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
    
    return result

  }

  func nowPlaying(sender: PlayerControlPlus, index: Int) {
    var message = "Singles Chart"
    if index != -1 {
      let entry = programme.chartEntries[index]
      message = "\(entry.Position.trimmingCharacters(in: .whitespacesAndNewlines))  \(entry.chartListing.ArtistObj.ArtistName) - \(entry.chartListing.sides[entry.Index].UKChartTitle)"
    }
    view.window?.title = message
  }
  
  // Player View Delegate Functions
  
  func playerControlInstance() -> PlayerControl {
    return playerControl
  }
  
}
