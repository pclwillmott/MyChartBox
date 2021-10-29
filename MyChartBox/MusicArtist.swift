//
//  MusicArtist.swift
//  MyChartBox
//
//  Created by Paul Willmott on 02/01/2021.
//  Copyright © 2021 Paul Willmott. All rights reserved.
//

import Foundation
import iTunesLibrary

public class MusicArtist {
  
  public var normalizedName : String = ""
  public var name : String
  public var iTunesTracks : [Int:MusicTrack] = [:]
  public var iTunesAlbums : [Int:MusicAlbum] = [:]
  
  init(artistName:String) {
    self.name = artistName
    if let normalized = normalizeArtistName(name: artistName) {
      self.normalizedName = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }

  public func findTracks(containsPattern:String) -> [MusicTrack] {
    
    var result : [MusicTrack] = []
    
    let pattern = containsPattern.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
    
    let selectAll = pattern.count == 0

    let fm = FileManager.default
    
    for (_, track) in iTunesTracks {
      
      if selectAll || track.mediaItem.title.uppercased().contains(pattern) {
        
        if fm.fileExists(atPath: track.location) {
          result.append(track)
        }

      }
      
    }
       
    result.sort {
      $0.mediaItem.title < $1.mediaItem.title
    }
    
    return result
    
  }

  public func findAlbums(containsPattern:String) -> [MusicAlbum] {
    
    var result : [MusicAlbum] = []
    
    let pattern = containsPattern.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
    
    let selectAll = pattern.count == 0

    let fm = FileManager.default
    
    for (_, album) in iTunesAlbums {
      
      if selectAll || album.title.uppercased().contains(pattern) {
        
        var albumOK = album.majorityArtist != nil
        
        for musicTrack in album.iTunesTracksSorted {
          if !fm.fileExists(atPath: musicTrack.location) {
            albumOK = false
          }
        }
        
        if albumOK {
          result.append(album)
        }

      }
      
    }
       
    result.sort {
      $0.title < $1.title
    }
    
    return result
    
  }
  
}
