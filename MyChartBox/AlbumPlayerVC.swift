//
//  AlbumPlayerVC.swift
//  MyChartBox
//
//  Created by Paul Willmott on 27/12/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import AVFoundation
import Cocoa

@available(OSX 10.14, *)
class AlbumPlayerVC: NSViewController, PlayerViewDelegate {
  
  // View Control Functions
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewDidAppear() {

    playerControl.tableView = tableView
    playerControl.albumPlayerDelegate = delegate
    playerControl.viewController = self
    playerControl.isAlbumMode = true
    
    if let a = album {
      
      a.incrementPlayCount()
      
      lblArtist.stringValue = a.majorityArtist?.name.uppercased() ?? "VARIOUS ARTISTS"
      lblAlbum.stringValue = a.title.uppercased()
      
      let tracks = a.iTunesTracksSorted
      trackDS = AlbumPlayerTableViewDS()
      trackDS?.tracks = tracks
      tableView.dataSource = trackDS
      tableView.delegate = trackDS
      
      if tracks.count > 0 {
        
        lblGenre.stringValue = tracks[0].mediaItem.genre.uppercased()
        lblYear.stringValue = "\(tracks[0].mediaItem.year)"
      
        for track in tracks {
          if track.mediaItem.hasArtworkAvailable {
            if let artwork = track.mediaItem.artwork {
              imgArtwork.image = artwork.image
              break
            }
          }
        }
        
        var index = 0
        for track in tracks {
          if track.isOKToPlayInAlbumMode {
            playerControl.add(track: track, at: index)
          }
          index += 1
        }

        playerControl.startPosition = startAtBeginning ? .first : .last
        
      }
      else {
        lblGenre.stringValue = ""
        lblYear.stringValue = ""
      }
      
      playerControl.btnPlayAction(nil)
    
    }
    
  }
  
  // Private Properties
  
  private var trackDS : AlbumPlayerTableViewDS?
  
  private var _delegate : AlbumPlayerDelegate?

  // Public Properties
  
  public var album : MusicAlbum?
  
  public var startAtBeginning = true
  
  public var delegate : AlbumPlayerDelegate? {
    get {
      return _delegate
    }
    set(value) {
      _delegate = value
 //     playerControl.albumPlayerDelegate = _delegate
    }
  }
 
  // Private Methods
  
  // Public Methods
  
  // Outlets
  
  @IBOutlet weak var lblArtist: NSTextField!
  @IBOutlet weak var lblAlbum: NSTextField!
  @IBOutlet weak var lblGenre: NSTextField!
  @IBOutlet weak var lblYear: NSTextField!
  @IBOutlet weak var imgArtwork: NSImageView!
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var playerControl: PlayerControlPlus!
  
  // Actions
  
  @IBAction func tableViewDoubleClick(_ sender: NSTableView) {
    playerControl.play(at: sender.clickedRow)
  }
  
  // Player View Delegate Functions
  
  func playerControlInstance() -> PlayerControl {
    return playerControl
  }
  
}
