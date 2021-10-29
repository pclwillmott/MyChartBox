//
//  SingleSide.swift
//  MyChartBox
//
//  Created by Paul Willmott on 30/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation

public class SingleSide : NSObject {

  private var _musicTracks     = [MusicTrack]()
  private var _artist          : Artist?
  private var _artistId        : Int = -1
  private var _ukChartTitle    : String = ""

  public var ArtistId : Int {
    get {
      return _artistId
    }
    set(value) {
      _artistId = value
    }
  }
  
  public var UKChartTitle : String {
    get {
      return _ukChartTitle
    }
    set(value) {
      _ukChartTitle = value
    }
  }
  
  var UKChartTitleClean : String {
    get {
      var temp = ""
      var inSeq = false
      for c in _ukChartTitle {
        if inSeq {
          if c == "}" {
            inSeq = false
          }
        }
        else if c == "{" {
          inSeq = true;
        }
        else {
          temp += String(c)
        }
      }
      return temp.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
    }
  }

  public var ArtistObj : Artist {
    get {
      if let artist = _artist {
        return artist
      }
      _artist = Artist(artistId: ArtistId)
      return _artist!
    }
  }

  public var musicTracks : [MusicTrack] {
     get {
      
       if _musicTracks.count == 0 {

         let matches = musicLibrary.find(artistName: ArtistObj.UKChartName, trackName: UKChartTitle)
        
         for track in matches {
           _musicTracks.append(track)
         }

       }

       return _musicTracks
     }
   }
}
