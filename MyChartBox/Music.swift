//
//  Music.swift
//  MyChartBox
//
//  Created by Paul Willmott on 23/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import iTunesLibrary

public class Music {
  
  public var artists : [String:MusicArtist] = [:]
  public var tracks  : [Int:MusicTrack] = [:]
  public var albums  : [Int:MusicAlbum] = [:]
  
  init?() {
    
    let library: ITLibrary

    do {
      library = try ITLibrary(apiVersion: "1.0")
    } catch
    {
      print("Error reading iTunes Library")
      return nil
    }

    let items = library.allMediaItems

    for track in items {

      if track.mediaKind != .kindSong || track.isDRMProtected {
        continue
      }
      
      if let artist = track.artist, let artistName = artist.name {

        if let name = normalizeArtistName(name: artistName) {
        
          var musicArtist : MusicArtist? = artists[name]

          if musicArtist == nil {
            musicArtist = MusicArtist(artistName: artistName)
            artists[musicArtist!.normalizedName] = musicArtist!
          }

          if let musicTrack = MusicTrack(iTunesTrack: track, musicArtist: musicArtist!) {
          
            musicArtist!.iTunesTracks[musicTrack.persistentID] = musicTrack

            tracks[musicTrack.persistentID] = musicTrack
            
            let albumId = Int(truncating: musicTrack.mediaItem.album.persistentID)

            var musicAlbum : MusicAlbum? = albums[albumId]
            
            if musicAlbum == nil {
              musicAlbum = MusicAlbum(iTunesAlbum: musicTrack.mediaItem.album)
              albums[albumId] = musicAlbum
            }
            
            musicAlbum!.iTunesTracks[musicTrack.persistentID] = musicTrack
            
            musicArtist!.iTunesAlbums[musicAlbum!.persistentID] = musicAlbum

          }
              
        }
        
      }
      
    }
    
  }
  
  public var artistsSorted : [MusicArtist] {
    get {
      var results : [MusicArtist] = []
      for artist in artists {
        results.append(artist.value)
      }
      results.sort {
        $0.normalizedName < $1.normalizedName
      }
      return results
    }
  }
  
  public func find(containsPattern:String) -> [MusicArtist] {
    
    var result : [MusicArtist] = []
    
    let pattern = containsPattern.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
    
    let selectAll = pattern.count == 0
    
    for (_, artist) in artists {
      
      if selectAll || artist.normalizedName.uppercased().contains(pattern) {
        result.append(artist)
      }
      
    }
       
    result.sort {
      $0.normalizedName < $1.normalizedName
    }
    
    return result
    
  }
  
  public func find(artistName:String) -> [MusicArtist] {
  
    var result : [MusicArtist] = []
    
    if let normalName = normalizeArtistName(name: artistName) {
      
      for step in 1...4 {
      
        var test = ""
        
        switch(step) {
        case 1:
          test = normalName
          break
        case 2:
          if let index = normalName.index(of: " FT ") {
            test = String(normalName[..<index])
          }
          break
        case 3:
          if let index = normalName.index(of: " & ") {
            test = String(normalName[..<index])
          }
          break
        case 4:
          if let index = normalName.index(of: "/") {
            test = String(normalName[..<index])
          }
          break
        default:
          break
        }
        
        test = test.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if test.count != 0 {
          if let musicArtist = artists[test] {
            result.append(musicArtist)
          }
          if step == 4 {
            let x = find(containsPattern: test)
            for y in x {
              result.append(y)
            }
          }
        }
        
      }
      
    }
    
    return result
    
  }
  
  public func find(artistName:String, trackName:String) -> [MusicTrack] {
    
    var result : [MusicTrack] = []
    
    if let normalName = normalizeTrackName(name: trackName) {
      
      let artistList = find(artistName: artistName)

      let fm = FileManager.default

      for artist in artistList {
        
        for (_, track) in artist.iTunesTracks {
          
          if track.name.contains(normalName) {
            if fm.fileExists(atPath: track.location) {
              result.append(track)
            }
          }
          
        }
        
      }
      
      result.sort {
        $0.mediaItem.totalTime < $1.mediaItem.totalTime
      }
      
    }
    
    return result
    
  }

  public func find(artistName:String, albumName:String) -> [MusicAlbum] {
    
    var result : [MusicAlbum] = []
    
    
    if let normalName = normalizeAlbumName(name: albumName) {

      let artistList = find(artistName: artistName)

      let fm = FileManager.default

      for artist in artistList {
        
        for (_, album) in artist.iTunesAlbums {
 
          if album.normalizedTitle.contains(normalName) {
            
            var albumOK = true
            
            for musicTrack in album.iTunesTracksSorted {
              if !fm.fileExists(atPath: musicTrack.location) {
                albumOK = false
                print(musicTrack.location)
              }
            }
            
            if albumOK {
              result.append(album)
            }
            
          }
          
        }
        
      }
      
      result.sort {
        $0.title < $1.title
      }
      
    }
    
    return result
    
  }

}


public let baseVolume : Float = 0.5

public class MusicTrack {
  
  public var name : String
  public var mediaItem : ITLibMediaItem
  public var musicArtist : MusicArtist
  
  init?(iTunesTrack:ITLibMediaItem, musicArtist:MusicArtist) {
    if let temp = normalizeTrackName(name: iTunesTrack.title) {
      name = temp
    }
    else {
      return nil
    }
    self.mediaItem = iTunesTrack
    self.musicArtist = musicArtist
  }
  
  public var artistPid : Int {
    get {
      return Int(truncating: mediaItem.artist!.persistentID)
    }
  }
  
  public var title : String {
    get {
      
      var result = mediaItem.title
      
      // Remove parentheticals
      
      let pTypes : [(Character,Character)] = [("[","]")]
      
      for p in pTypes {
        
        var temp = ""
        var inParenthesis = false
      
        for c in result {
          if c == p.0 {
            inParenthesis = true
          }
          else if c == p.1 {
            inParenthesis = false
          }
          else if !inParenthesis {
            temp += String(c)
          }
        }
        
        result = temp

      }

      // Single space
      
      let split = result.split(separator: " ", omittingEmptySubsequences: true)
      
      result = ""
      
      for s in split {
        if result != "" {
          result += " "
        }
        result += s
      }
      
      return result
      
    }
  }
  
  public var isBonusTrack : Bool {
    get {
      let t = mediaItem.title.uppercased()
      return t.contains("[BONUS]") || mediaItem.title.uppercased().contains("[BONUS TRACK]")
    }
  }
  
  public var isChristmasSong : Bool {
    get {
      return mediaItem.genre == "Christmas"
    }
  }
  
  public var isLive : Bool {
    get {
      return mediaItem.title.uppercased().contains("[LIVE]")
    }
  }

  public var isDemo : Bool {
    get {
      return mediaItem.title.uppercased().contains("[DEMO]")
    }
  }
  
  public var isOKToPlayInAlbumMode : Bool {
    get {
      var skip : Bool = false
      let skipBonusTracks = UserDefaults.standard.bool(forKey: DEFAULT.SKIP_BONUS_TRACKS)
      skip = skip || (skipBonusTracks && isBonusTrack)
      let skipLiveTracks = UserDefaults.standard.bool(forKey: DEFAULT.SKIP_LIVE_TRACKS)
      skip = skip || (skipLiveTracks && isLive)
      let skipDemoTracks = UserDefaults.standard.bool(forKey: DEFAULT.SKIP_DEMO_TRACKS)
      skip = skip || (skipDemoTracks && isDemo)
      return !skip
    }
  }

  public var persistentID : Int {
    get {
      return Int(truncating: mediaItem.persistentID)
    }
  }
  
  public var fileType : String {
    get {
      return location.fileExtension()
    }
  }
  
  public var trackSequenceNumber : Int {
    get {
      return mediaItem.trackNumber + mediaItem.album.discNumber * 100
    }
  }
  
  public var trackSequenceNumberAsString : String {
    get {
      return mediaItem.album.discCount == 1 ? "\(mediaItem.trackNumber)" : "\(mediaItem.album.discNumber)-\(mediaItem.trackNumber)"
    }
  }
  
  private var _musicTrackProperties : MusicTrackProperties?
  
  public var volume : Float {
    get {
      if _musicTrackProperties == nil {
        _musicTrackProperties = MusicTrackProperties(musicTrack: self)
      }
      return _musicTrackProperties!.volume
    }
    set(value) {
      if _musicTrackProperties == nil {
        _musicTrackProperties = MusicTrackProperties(musicTrack: self)
      }
      _musicTrackProperties!.volume = value
      _musicTrackProperties!.save()
    }
  }
  
  public var baseVolume : Float {
    get {
      let cap : Int = 9000
      let minVal : Float = 0.3
      let volumeAdjustment = min(mediaItem.volumeNormalizationEnergy, cap)
      return minVal + (1.0 - minVal) * (1.0 - Float(volumeAdjustment) / Float(cap))
    }
  }
  
  public var location : String {
    if let loc = mediaItem.location {
      return "\(loc.path)"
    }
    return ""
  }
  
  public var urlLocation : String {
    if let loc = mediaItem.location {
      return "\(loc.absoluteString)"
    }
    return ""
  }
  
  public var timeAsString : String {
    get {
      return timeString(milliseconds:mediaItem.totalTime)
    }
  }
  
  public var albumInfo : String {
    get {
      
      let album = mediaItem.album
      var discInfo = ""
      if album.discCount > 1 {
        discInfo = " Disc \(album.discNumber) of \(album.discCount) "
      }
      return "\(album.title!) -\(discInfo) Track \(mediaItem.trackNumber)"
    }
  }

  
}

public func normalizeArtistName(name: String) -> String? {
  
  // Force to uppercase and remove leading and trailing whitespace
  
  var normalized = name.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
  
  // Remove leading "THE", except for "THE THE"
  
  if normalized != "THE THE" && normalized.prefix(4) == "THE " {
    normalized = String(normalized.suffix(normalized.count - 4))
  }
  
  // Change "AND" to "&"
  
  normalized = normalized.replacingOccurrences(of: " AND ", with: " & ")
  
  // Drop single quotes
  
  normalized = normalized.replacingOccurrences(of: "\'", with: "")

  // Drop periods
  
  normalized = normalized.replacingOccurrences(of: ".", with: "")
  
  // Drop commas
  
  normalized = normalized.replacingOccurrences(of: ",", with: " ")
  
  // Drop hyphens
  
  normalized = normalized.replacingOccurrences(of: "-", with: " ")
  
  // Drop exclamation marks
  
  normalized = normalized.replacingOccurrences(of: "P!NK", with: "PINK")
  normalized = normalized.replacingOccurrences(of: "!", with: "")

  // Replace featurings with FT
  
  let ft = [" FEATURING ", " FEAT ", " WITH "]
  
  for option in ft {
    normalized = normalized.replacingOccurrences(of: option, with: " FT ")
  }
  
  // Remove parentheticals
  
  let pTypes : [(Character,Character)] = [("(",")"), ("{","}"), ("[","]")]
  
  for p in pTypes {
    
    var temp = ""
    var inParenthesis = false
  
    for c in normalized {
      if c == p.0 {
        inParenthesis = true
      }
      else if c == p.1 {
        inParenthesis = false
      }
      else if !inParenthesis {
        temp += String(c)
      }
    }
    
    normalized = temp

  }

  // Single space
  
  let split = normalized.split(separator: " ", omittingEmptySubsequences: true)
  
  normalized = ""
  
  for s in split {
    if normalized != "" {
      normalized += " "
    }
    normalized += s
  }
  
  if normalized == "" {
    return nil
  }

  // return result
  
  return normalized
  
}

public func normalizeTrackName(name: String) -> String? {
  
  // Force to uppercase and remove leading and trailing whitespace
  
  var normalized = name.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
  
  // Change "AND" to "&"
  
  normalized = normalized.replacingOccurrences(of: " AND ", with: " & ")
  
  // Drop single quotes
  
  normalized = normalized.replacingOccurrences(of: "\'", with: " ")

  // Drop periods
  
  normalized = normalized.replacingOccurrences(of: ".", with: " ")
  
  // Drop commas
  
  normalized = normalized.replacingOccurrences(of: ",", with: " ")
  
  // Drop hyphens
  
  normalized = normalized.replacingOccurrences(of: "-", with: " ")
  
  // Drop exclamation marks
  
  normalized = normalized.replacingOccurrences(of: "!", with: " ")

  // Replace featurings with FT
  
  let ft = [" FEAT "]
  
  for option in ft {
    normalized = normalized.replacingOccurrences(of: option, with: " FT ")
  }
  
  if let index = normalized.index(of: " FT ") {
    normalized = String(normalized[..<index])
  }
  
  // Remove selected parentheticals
  
  let pTypes : [(Character,Character)] = [("{","}"), ("[","]")]
  
  for p in pTypes {
    
    var temp = ""
    var inParenthesis = false
  
    for c in normalized {
      if c == p.0 {
        inParenthesis = true
      }
      else if c == p.1 {
        inParenthesis = false
      }
      else if !inParenthesis {
        temp += String(c)
      }
    }
    
    normalized = temp

  }

  // Single space
  
  let split = normalized.split(separator: " ", omittingEmptySubsequences: true)
  
  normalized = ""
  
  for s in split {
    if normalized != "" {
      normalized += " "
    }
    normalized += s
  }
  
  if normalized == "" {
    return nil
  }

  // return result
  
  return normalized
  
}

public func normalizeAlbumName(name: String) -> String? {
  
  // Force to uppercase and remove leading and trailing whitespace
  
  var normalized = name.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
  
  // Change "AND" to "&"
  
  normalized = normalized.replacingOccurrences(of: " AND ", with: " & ")
  
  // Drop single quotes
  
  normalized = normalized.replacingOccurrences(of: "\'", with: " ")

  // Drop periods
  
  normalized = normalized.replacingOccurrences(of: ".", with: " ")
  
  // Drop commas
  
  normalized = normalized.replacingOccurrences(of: ",", with: " ")
  
  // Drop hyphens
  
  normalized = normalized.replacingOccurrences(of: "-", with: " ")
  
  // Drop exclamation marks
  
  normalized = normalized.replacingOccurrences(of: "!", with: " ")

  // Replace featurings with FT
  
  let ft = [" FEAT "]
  
  for option in ft {
    normalized = normalized.replacingOccurrences(of: option, with: " FT ")
  }
  
  if let index = normalized.index(of: " FT ") {
    normalized = String(normalized[..<index])
  }
  
  // Remove selected parentheticals
  
  let pTypes : [(Character,Character)] = [("{","}"), ("[","]")]
  
  for p in pTypes {
    
    var temp = ""
    var inParenthesis = false
  
    for c in normalized {
      if c == p.0 {
        inParenthesis = true
      }
      else if c == p.1 {
        inParenthesis = false
      }
      else if !inParenthesis {
        temp += String(c)
      }
    }
    
    normalized = temp

  }

  // Single space
  
  let split = normalized.split(separator: " ", omittingEmptySubsequences: true)
  
  normalized = ""
  
  for s in split {
    if normalized != "" {
      normalized += " "
    }
    normalized += s
  }
  
  if normalized == "" {
    return nil
  }

  // return result
  
  return normalized
  
}

public class MusicTrackProperties {
  
  private var _volume : Float
  private var _modified = false
  private var _persistantID : Int
  private var _newRow = true
  
  public var persistantID : Int {
    get {
      return _persistantID
    }
  }
  
  public var volume : Float {
    get {
      return _volume
    }
    set(value) {
      if value != _volume {
        _volume = value
        _modified = true
      }
    }
  }
  
  init(musicTrack:MusicTrack!) {
    
    _persistantID = musicTrack.persistentID
    
    _volume = musicTrack.baseVolume
    
    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT " + MusicTrackProperties.ColumnNames + " FROM [\(TABLE.MUSIC_TRACK)] " +
    "WHERE [\(MUSIC_TRACK.MUSIC_PID)] = @\(MUSIC_TRACK.MUSIC_PID)"

    cmd.parameters.addWithValue(key: "@\(MUSIC_TRACK.MUSIC_PID)", value: _persistantID)
    
    if let reader = cmd.executeReader() {
         
      if reader.read() {
        decode(sqliteDataReader: reader)
      }
         
      reader.close()
         
    }
    
    if shouldClose {
      conn.close()
    }

  }
  
  public static var ColumnNames : String {
    get {
      return
        "[\(MUSIC_TRACK.MUSIC_PID)], " +
        "[\(MUSIC_TRACK.VOLUME_ADJUSTMENT)] "
    }
  }
  
  private func decode(sqliteDataReader:SqliteDataReader?) {
      
    if let reader = sqliteDataReader {
        
      _persistantID = reader.getInt(index: 0)!
        
      if !reader.isDBNull(index: 1) {
        _volume = Float(reader.getDouble(index: 1)!)
      }
        
      _modified = false
      _newRow = false
      
    }
    
  }
  
  public func save() {
     
     if _modified {
       
       var sql = ""
       
       if _newRow {
        sql = "INSERT INTO [\(TABLE.MUSIC_TRACK)] (" +
          "[\(MUSIC_TRACK.MUSIC_PID)], " +
          "[\(MUSIC_TRACK.VOLUME_ADJUSTMENT)]" +
         ") VALUES (" +
          "@\(MUSIC_TRACK.MUSIC_PID), " +
          "@\(MUSIC_TRACK.VOLUME_ADJUSTMENT)" +
         ")"
       }
       else {
        sql = "UPDATE [\(TABLE.MUSIC_TRACK)] SET " +
          "[\(MUSIC_TRACK.VOLUME_ADJUSTMENT)] = @\(MUSIC_TRACK.VOLUME_ADJUSTMENT) " +
        "WHERE [\(MUSIC_TRACK.MUSIC_PID)] = @\(MUSIC_TRACK.MUSIC_PID)"
       }

       let conn = Database.getConnection()
       
       let shouldClose = conn.state != .Open
        
       if shouldClose {
          _ = conn.open()
       }
        
       let cmd = conn.createCommand()
        
       cmd.commandText = sql
       
       cmd.parameters.addWithValue(key: "@\(MUSIC_TRACK.MUSIC_PID)", value: _persistantID)
       cmd.parameters.addWithValue(key: "@\(MUSIC_TRACK.VOLUME_ADJUSTMENT)", value: Double(_volume))
       
       _ = cmd.executeNonQuery()

       if shouldClose {
         conn.close()
       }
       
       _modified = false
      _newRow = false
       
     }

   }

  
}
