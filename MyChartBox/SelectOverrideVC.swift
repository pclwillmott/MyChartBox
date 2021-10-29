//
//  SelectOverrideVC.swift
//  MyChartBox
//
//  Created by Paul Willmott on 04/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation

class SelectOverrideVC: NSViewController, NSTextFieldDelegate, AVAudioPlayerDelegate {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    lblTitle.stringValue = ""
    lblArtist.stringValue = ""
    btnSelect.isEnabled = false
    txtArtist.delegate = self
    txtTrack.delegate = self
    albumName.stringValue = ""
  }
  
  let artistDS = ArtistTableViewDS()
  var trackDS = TrackTableViewDS()
  
  public var chartListing : ChartListing?
  public var sideIndex : Int = 0
  
  
  override func viewDidAppear() {
    
    if let listing = chartListing {
      
      if listing.ProductType == "SINGLE" {
        lblTitle.stringValue = listing.sides[sideIndex].UKChartTitle
        lblArtist.stringValue = listing.ArtistObj.UKChartName
        txtArtist.stringValue = lblArtist.stringValue
        txtArtist.stringValue = normalizeArtistName(name: lblArtist.stringValue) ?? ""
        txtTrack.stringValue = lblTitle.stringValue.uppercased()

        
        let best = listing.bestTrack(index:sideIndex)
        var musicArtist : MusicArtist?
        
        if let track = best {
          musicArtist = track.musicArtist //musicLibrary.allArtists[track.artistPid]
          if let artist = musicArtist {
            txtArtist.stringValue = artist.normalizedName
            txtTrack.stringValue = track.mediaItem.title.uppercased()
          }
        }
        
        artistTableView.dataSource = artistDS
        artistTableView.delegate = artistDS
        refreshArtists(artist: txtArtist.stringValue)

        trackTableView.dataSource = trackDS
        trackTableView.delegate = trackDS
        
        if let track = best, let artist = musicArtist {
          artistTableView.selectRowIndexes(.init(integer: artistDS.getRowIndex(artistName: track.musicArtist.normalizedName)), byExtendingSelection: false)
          refreshTracks(artist: artist, track: track.mediaItem.title)
          trackTableView.selectRowIndexes(.init(integer: trackDS.getRowIndex(trackId: track.persistentID)), byExtendingSelection: false)
          albumName.stringValue = track.albumInfo
        }

      }
      else {
        lblTitle.stringValue = listing.UKChartTitle
        lblArtist.stringValue = listing.ArtistObj.UKChartName
        txtArtist.stringValue = normalizeArtistName(name: lblArtist.stringValue) ?? ""
        txtTrack.stringValue = lblTitle.stringValue.uppercased()

        btnPlay.isHidden = true
        btnNotThisTrack.isHidden = true
        albumName.isHidden = true
        
        
        let best = listing.bestAlbum()
   //     var musicArtist : MusicArtist?
        
        
        if let album = best {
          if let artist = album.majorityArtist {
            txtArtist.stringValue = artist.normalizedName
          }
          else {
            txtArtist.stringValue = "Various Artists"
          }
          txtTrack.stringValue = album.title.uppercased()
        }
        
        artistTableView.dataSource = artistDS
        artistTableView.delegate = artistDS
        refreshArtists(artist: txtArtist.stringValue)

        trackTableView.dataSource = trackDS
        trackTableView.delegate = trackDS
        
        if let album = best, let artist = album.majorityArtist {
          artistTableView.selectRowIndexes(.init(integer: artistDS.getRowIndex(artistName: artist.normalizedName)), byExtendingSelection: false)
          refreshAlbums(artist: artist, album: album.title)
          trackTableView.selectRowIndexes(.init(integer: trackDS.getRowIndex(albumId: album.persistentID)), byExtendingSelection: false)
          albumName.stringValue = album.title
        }

      }
      
    }
  }
  
  private var artists : [MusicArtist] = []
  
  private var tracks : [MusicTrack] = []
  
  private var albums : [MusicAlbum] = []
  
  private func refreshArtists(artist:String) {

    artists = musicLibrary.find(containsPattern: artist)
    artistDS.artists = artists
    artistTableView.reloadData()

  }

  private func refreshTracks(artist:MusicArtist, track:String) {
    
    tracks = artist.findTracks(containsPattern: track)
    trackDS.tracks = tracks
    trackTableView.reloadData()

  }

  private func refreshAlbums(artist:MusicArtist, album:String) {
    
    albums = artist.findAlbums(containsPattern: album)
    trackDS.albums = albums
    trackTableView.reloadData()

  }

@IBAction func CloseClick(_ sender: NSButton) {
    stopModal()
  }
  
  @IBAction func SelectClick(_ sender: NSButton) {
    save()
    stopModal()
  }
  
  @IBOutlet weak var btnSelect: NSButton!
  
  @IBOutlet weak var lblTitle: NSTextField!
  
  @IBOutlet weak var lblArtist: NSTextField!
  
  @IBAction func ArtistChanged(_ sender: NSTextField) {
  }
  
  func controlTextDidChange(_ obj: Notification) {
    let x: NSTextField = obj.object! as! NSTextField
    if x.tag == 1 {
      refreshArtists(artist: txtArtist.stringValue)
    }
    else if artistTableView.selectedRow != -1 {
      if chartListing!.ProductType == "SINGLE" {
        refreshTracks(artist: artists[artistTableView.selectedRow], track: txtTrack.stringValue)
      }
      else {
        refreshAlbums(artist: artists[artistTableView.selectedRow], album: txtTrack.stringValue)
      }
    }
  }
  
  @IBOutlet weak var txtArtist: NSTextField!
  
  @IBOutlet weak var artistTableView: NSTableView!
  
  @IBAction func artistAction(_ sender: NSTableView) {
    if sender.selectedRow != -1 {
      if chartListing!.ProductType == "SINGLE" {
        refreshTracks(artist: artists[sender.selectedRow], track: txtTrack.stringValue)
      }
      else {
        refreshAlbums(artist: artists[artistTableView.selectedRow], album: txtTrack.stringValue)
      }
    }
  }
  
  @IBAction func trackTableViewAction(_ sender: NSTableView) {
    stopPlayer()
    btnSelect.isEnabled = true
    btnPlay.isEnabled = true
    if trackTableView.selectedRow != -1 {
      if chartListing!.ProductType == "SINGLE" {
        let track = tracks[trackTableView.selectedRow]
        albumName.stringValue = track.albumInfo
      }
      else {
        let album = albums[trackTableView.selectedRow]
        albumName.stringValue = album.title
      }
    }
  }
  
  @IBOutlet weak var trackTableView: NSTableView!
  
  @IBOutlet weak var btnPlay: NSButton!
  
  private var isPlaying = false
  
  private var player : AVAudioPlayer?
  
  private func stopPlayer() {
    btnPlay.image = NSImage(named: "NSTouchBarPlayTemplate")
    player?.stop()
    player = nil
    isPlaying = false
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                   successfully flag: Bool) {
    stopPlayer()
  }

  @IBAction func btnPlayClick(_ sender: Any) {
    isPlaying = !isPlaying
    if isPlaying {
      btnPlay.image = NSImage(named: "NSTouchBarRecordStopTemplate")
      let track = tracks[trackTableView.selectedRow]
      if let url = URL(string: track.location) {
        do {
          player = try AVAudioPlayer(contentsOf: url)
          player!.prepareToPlay()
          player!.volume = track.volume
          player?.delegate = self
          player!.play()
        }
        catch
        {
          print("SelectOverrideVC: couldn't load file")
        }
      }
    }
    else {
      stopPlayer()
    }

  }
  
  
  @IBAction func trackDoubleAction(_ sender: NSTableView) {
    stopPlayer()
    save()
    stopModal()
  }
  
  @IBAction func trackAction(_ sender: NSTextField) {
    if artistTableView.selectedRow != -1 {
      if chartListing!.ProductType == "SINGLE" {
        refreshTracks(artist: artists[artistTableView.selectedRow], track: sender.stringValue)
      }
      else {
        refreshAlbums(artist: artists[artistTableView.selectedRow], album: sender.stringValue)
      }
    }
  }
  
  @IBOutlet weak var txtTrack: NSTextField!
  
  @IBAction func allArtistsClick(_ sender: NSButton) {
    txtArtist.stringValue = ""
    refreshArtists(artist: txtArtist.stringValue)
  }
  
  @IBOutlet weak var albumName: NSTextField!
  
  @IBAction func allTracksClick(_ sender: NSButton) {
    txtTrack.stringValue = ""
    if artistTableView.selectedRow != -1 {
      if chartListing!.ProductType == "SINGLE" {
        refreshTracks(artist: artists[artistTableView.selectedRow], track: txtTrack.stringValue)
      }
      else {
        refreshAlbums(artist: artists[artistTableView.selectedRow], album: txtTrack.stringValue)
      }
    }
  }
  
  @IBOutlet weak var btnNotThisTrack: NSButton!
  
  @IBAction func clearLinkClick(_ sender: NSButton) {
    
    let commands = [
      
      "DELETE FROM [\(TABLE.TRACK_OVERRIDE)] " +
      "WHERE [\(TRACK_OVERRIDE.CHART_LISTING_ID)] = \(chartListing!.ChartListingId) AND " +
      "[\(TRACK_OVERRIDE.SIDE_INDEX)] = \(sideIndex)",
    ]
    
    Database.execute(commands: commands)

    let sql =
        "INSERT INTO [\(TABLE.TRACK_OVERRIDE)] (" +
          "[\(TRACK_OVERRIDE.TRACK_OVERRIDE_ID)], " +
          "[\(TRACK_OVERRIDE.CHART_LISTING_ID)], " +
          "[\(TRACK_OVERRIDE.SIDE_INDEX)], " +
          "[\(TRACK_OVERRIDE.ITUNES_TRACK_ID)], " +
          "[\(TRACK_OVERRIDE.NOT_THIS_TRACK)], " +
          "[\(TRACK_OVERRIDE.MUSIC_PID)] " +

        ") VALUES (" +
          "@\(TRACK_OVERRIDE.TRACK_OVERRIDE_ID), " +
          "@\(TRACK_OVERRIDE.CHART_LISTING_ID), " +
          "@\(TRACK_OVERRIDE.SIDE_INDEX), " +
          "NULL, " +
          "1," +
          "0 " +
        ")"

    let conn = Database.getConnection()
      
    let shouldClose = conn.state != .Open
       
    if shouldClose {
       _ = conn.open()
    }
       
    let cmd = conn.createCommand()
       
    cmd.commandText = sql
      
    cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.TRACK_OVERRIDE_ID)", value: Database.nextCode(tableName: TABLE.TRACK_OVERRIDE, primaryKey: TRACK_OVERRIDE.TRACK_OVERRIDE_ID)!)
    cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.CHART_LISTING_ID)", value: chartListing!.ChartListingId)
    cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.SIDE_INDEX)", value: sideIndex)

    _ = cmd.executeNonQuery()

    if shouldClose {
      conn.close()
    }
      
    stopModal()
    
  }
  
  func save() {
    
    if trackTableView.selectedRow != -1 {

      if chartListing!.ProductType == "SINGLE" {
        
        let track = tracks[trackTableView.selectedRow]
        
        let commands = [
          
          "DELETE FROM [\(TABLE.TRACK_OVERRIDE)] " +
          "WHERE [\(TRACK_OVERRIDE.CHART_LISTING_ID)] = \(chartListing!.ChartListingId) AND " +
          "[\(TRACK_OVERRIDE.SIDE_INDEX)] = \(sideIndex)",
        ]
        
        Database.execute(commands: commands)

        let sql =
          "INSERT INTO [\(TABLE.TRACK_OVERRIDE)] (" +
            "[\(TRACK_OVERRIDE.TRACK_OVERRIDE_ID)], " +
            "[\(TRACK_OVERRIDE.CHART_LISTING_ID)], " +
            "[\(TRACK_OVERRIDE.SIDE_INDEX)], " +
            "[\(TRACK_OVERRIDE.ITUNES_TRACK_ID)], " +
            "[\(TRACK_OVERRIDE.NOT_THIS_TRACK)], " +
            "[\(TRACK_OVERRIDE.MUSIC_PID)] " +
          ") VALUES (" +
            "@\(TRACK_OVERRIDE.TRACK_OVERRIDE_ID), " +
            "@\(TRACK_OVERRIDE.CHART_LISTING_ID), " +
            "@\(TRACK_OVERRIDE.SIDE_INDEX), " +
            "NULL, " +
            "NULL," +
            "@\(TRACK_OVERRIDE.MUSIC_PID) " +
          ")"

        let conn = Database.getConnection()
        
        let shouldClose = conn.state != .Open
         
        if shouldClose {
           _ = conn.open()
        }
         
        let cmd = conn.createCommand()
         
        cmd.commandText = sql
        
        cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.TRACK_OVERRIDE_ID)", value: Database.nextCode(tableName: TABLE.TRACK_OVERRIDE, primaryKey: TRACK_OVERRIDE.TRACK_OVERRIDE_ID)!)
        cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.CHART_LISTING_ID)", value: chartListing!.ChartListingId)
        cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.SIDE_INDEX)", value: sideIndex)
        cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.MUSIC_PID)", value: track.persistentID)

        _ = cmd.executeNonQuery()

        if shouldClose {
          conn.close()
        }
        
      }
      
      else {
        
        let album = albums[trackTableView.selectedRow]
        
        let commands = [
          
          "DELETE FROM [\(TABLE.TRACK_OVERRIDE)] " +
          "WHERE [\(TRACK_OVERRIDE.CHART_LISTING_ID)] = \(chartListing!.ChartListingId) AND " +
          "[\(TRACK_OVERRIDE.SIDE_INDEX)] = 1",
        ]
        
        Database.execute(commands: commands)

        let sql =
          "INSERT INTO [\(TABLE.TRACK_OVERRIDE)] (" +
            "[\(TRACK_OVERRIDE.TRACK_OVERRIDE_ID)], " +
            "[\(TRACK_OVERRIDE.CHART_LISTING_ID)], " +
            "[\(TRACK_OVERRIDE.SIDE_INDEX)], " +
            "[\(TRACK_OVERRIDE.ITUNES_TRACK_ID)], " +
            "[\(TRACK_OVERRIDE.NOT_THIS_TRACK)], " +
            "[\(TRACK_OVERRIDE.MUSIC_PID)] " +
          ") VALUES (" +
            "@\(TRACK_OVERRIDE.TRACK_OVERRIDE_ID), " +
            "@\(TRACK_OVERRIDE.CHART_LISTING_ID), " +
            "@\(TRACK_OVERRIDE.SIDE_INDEX), " +
            "NULL, " +
            "NULL," +
            "@\(TRACK_OVERRIDE.MUSIC_PID) " +
          ")"

        let conn = Database.getConnection()
        
        let shouldClose = conn.state != .Open
         
        if shouldClose {
           _ = conn.open()
        }
         
        let cmd = conn.createCommand()
         
        cmd.commandText = sql
        
        cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.TRACK_OVERRIDE_ID)", value: Database.nextCode(tableName: TABLE.TRACK_OVERRIDE, primaryKey: TRACK_OVERRIDE.TRACK_OVERRIDE_ID)!)
        cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.CHART_LISTING_ID)", value: chartListing!.ChartListingId)
        cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.SIDE_INDEX)", value: 1)
        cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.MUSIC_PID)", value: album.persistentID)

        _ = cmd.executeNonQuery()

        if shouldClose {
          conn.close()
        }
      }
    }
  }
  
}

