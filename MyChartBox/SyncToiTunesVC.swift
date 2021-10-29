//
//  SyncToiTunesVC.swift
//  MyChartBox
//
//  Created by Paul Willmott on 03/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa
import iTunesLibrary

class SyncToiTunesVC: NSViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    progressIndicator.minValue = 0.0
    progressIndicator.maxValue = 100.0
    progressIndicator.doubleValue = 0.0
  }
  
  @IBAction func CancelClick(_ sender: NSButton) {
    stopModal()
  }
  
  @IBOutlet weak var btnSync: NSButton!
  
  @IBAction func SyncClick(_ sender: NSButton) {
    
    if btnSync.title == "Done" {
      stopModal()
      return
    }
    
    btnSync.isEnabled = false
    
    DispatchQueue.global(qos: .userInitiated).async {
      
      let group = DispatchGroup()
      
      group.enter()
      
      let queue = DispatchQueue(label: "work-queue")
      
      queue.async {
        self.sync()
        group.leave()
      }
      
      group.notify(queue: DispatchQueue.main) {
        self.btnSync.title = "Done"
        self.btnSync.isEnabled = true
      }
      
    }
     
  }
  
  func sync() {
    
    let commands = [
             
      "UPDATE [\(TABLE.ITUNES_ARTIST)] SET UPDATED = NULL;",
      "UPDATE [\(TABLE.ITUNES_TRACK)] SET UPDATED = NULL;",
      "UPDATE [\(TABLE.ITUNES_ALBUM)] SET UPDATED = NULL;",

    ]
    
    Database.execute(commands: commands)
                    
    let library: ITLibrary

    do {
      library = try ITLibrary(apiVersion: "1.0")
    } catch
    {
      print("Error occured!")
      return
    }

    let tracks = library.allMediaItems
        
    let maxValue = Double(tracks.count-1)
    var index = 0.0
        
    let fm = FileManager.default

    for track in tracks {
      
      if track.mediaKind == .kindSong {
        
        if let url = track.location {
          
          let path = "\(url.path)"
          
          let exists = fm.fileExists(atPath: path)
          
          if exists && path.fileExtension() != "m4p" {
          
            if let art = track.artist {
              let ita = iTunesArtistX(artist: art)
              if ita.updated == nil {
                ita.updated = 1
                ita.Save()
              }
              let itab = iTunesAlbum(album: track.album)
              if itab.updated == nil {
                itab.updated = 1
                itab.save()
              }
              let tra = iTunesTrackX(item: track)
              if tra.updated == nil {
                tra.updated = 1
                tra.Save()
              }
            }

          }
          else if !exists {
//            print ("Not Exist - \(path)")
          }
          else {
//            print ("DRM Protected - \(path)")
          }

        }
        
      }
      
      index += 1.0
      
      DispatchQueue.main.async {
        if let progress = self.progressIndicator {
         progress.doubleValue = index / maxValue * 100.0
        }
      }

    }
    
    relinkOverrides()
    
  }
  
  func relinkOverrides() {
    
    let commands = [
      
      "DELETE FROM [\(TABLE.ITUNES_ARTIST)] " +
      "WHERE [\(ITUNES_ARTIST.UPDATED)] IS NULL",
    
      "DELETE FROM [\(TABLE.ITUNES_TRACK)] " +
      "WHERE [\(ITUNES_TRACK.UPDATED)] IS NULL",
    
      "DELETE FROM [\(TABLE.ITUNES_ALBUM)] " +
      "WHERE [\(ITUNES_ALBUM.UPDATED)] IS NULL",

      "DELETE FROM [\(TABLE.TRACK_OVERRIDE)] " +
      "WHERE [\(TRACK_OVERRIDE.NOT_THIS_TRACK)] IS NULL AND " +
      "[\(TRACK_OVERRIDE.ITUNES_TRACK_ID)] NOT IN " +
      "(SELECT [\(ITUNES_TRACK.ITUNES_TRACK_ID)] FROM [\(TABLE.ITUNES_TRACK)] " +
      "GROUP BY [\(ITUNES_TRACK.ITUNES_TRACK_ID)])",
    
    ]
    
    Database.execute(commands: commands)
    
  }
  
  @IBOutlet weak var progressIndicator: NSProgressIndicator!
  
}
