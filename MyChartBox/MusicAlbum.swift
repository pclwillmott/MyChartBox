//
//  MusicAlbum.swift
//  MyChartBox
//
//  Created by Paul Willmott on 02/01/2021.
//  Copyright © 2021 Paul Willmott. All rights reserved.
//

import Foundation
import iTunesLibrary

public class MusicAlbum {
  
  public var title : String
  public var persistentID : Int = 0
  public var iTunesTracks : [Int:MusicTrack] = [:]
  public var normalizedTitle : String
  public var iTunesAlbum : ITLibAlbum
  
  private var albumPlayCount : AlbumPlayCount? = nil
  
  init(iTunesAlbum:ITLibAlbum!) {
    title = iTunesAlbum.title!.trimmingCharacters(in: .whitespacesAndNewlines)
    persistentID = Int(truncating: iTunesAlbum.persistentID)
    normalizedTitle = normalizeAlbumName(name: title) ?? ""
    self.iTunesAlbum = iTunesAlbum
  }
  
  public var majorityArtist : MusicArtist? {
    get {
      if let artistName = majorityArtistName {
        if let artist = musicLibrary.artists[artistName] {
          return artist
        }
      }
      return nil
    }
  }
  
  public var majorityArtistName : String? {
    get {
      var artist : [String:Int] = [:]
      for (_, track) in iTunesTracks {
        let count = artist[track.musicArtist.normalizedName] ?? 0
        artist[track.musicArtist.normalizedName] = count + 1
      }
      var max : Int = 0
      var maxArtistName : String = ""
      for (artistName, count) in artist {
        if max < count {
          max = count
          maxArtistName = artistName
        }
      }
      let percent = Double(max) / Double(iTunesTracks.count)
      if maxArtistName != "" && percent > 0.5 {
        return maxArtistName
      }
      return nil
    }
  }
  
  public var fileType : String {
    get {
      var fileType : [String:Int] = [:]
      for (_, track) in iTunesTracks {
        let ext = track.location.fileExtension().lowercased()
        let count = fileType[ext] ?? 0
        fileType[ext] = count + 1
      }
      var max = 0
      var maxFileType = ""
      for (ext, count) in fileType {
        if count > max {
          max = count
          maxFileType = ext
        }
      }
      if fileType.count > 1 {
        maxFileType += "!"
      }
      return maxFileType
    }
  }

  public var timeAsString : String {
    get {
      var totalTime : Int = 0
      for (_, track) in iTunesTracks {
        totalTime += track.mediaItem.totalTime
      }
      return timeString(milliseconds:totalTime)
    }
  }

  public var iTunesTracksSorted : [MusicTrack] {
    var result : [MusicTrack] = []
    for track in iTunesTracks {
      result.append(track.value)
    }
    result.sort {
      $0.trackSequenceNumber < $1.trackSequenceNumber
    }
      
    return result
  }
  
  public var iTunesTracksForAlbumPlay : (playList:[MusicTrack], trackIndex:[Int], durationOfPlaylist:Int) {
    
    get {
      
      let tracks = iTunesTracksSorted
      
      var playList : [MusicTrack] = []
      
      var trackIndex : [Int] = []
      
      var durationOfPlayList : Int = 0
      
      if tracks.count > 0 {
        
        var index = 0
        for track in tracks {
          if track.isOKToPlayInAlbumMode {
            playList.append(track)
            trackIndex.append(index)
            durationOfPlayList += track.mediaItem.totalTime
          }
          index += 1
        }
        
      }
      return (playList, trackIndex, durationOfPlayList)
    }
    
  }
  
  private var _albumDuration : Int = -1
  
  public var albumDuration : Int {
    get {
      if (_albumDuration < 0) {
        _albumDuration = iTunesTracksForAlbumPlay.durationOfPlaylist
      }
      return _albumDuration
    }
  }
  
  public var playCount : Int {
    get {
      if albumPlayCount == nil {
        albumPlayCount = AlbumPlayCount(albumId: self.persistentID)
      }
      return albumPlayCount!.playCount
    }
  }
  
  public func incrementPlayCount() {
    if albumPlayCount == nil {
      albumPlayCount = AlbumPlayCount(albumId: self.persistentID)
    }
    albumPlayCount!.incrementPlayCount()
  }

}

