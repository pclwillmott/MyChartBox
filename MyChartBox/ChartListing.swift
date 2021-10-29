//
//  ChartListing.swift
//  MyChartBox
//
//  Created by Paul Willmott on 12/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation

public class ChartListing : NSObject {
  
  private var _chartListingId  : Int = -1
  private var _chartId         : Int = -1
  private var _artistId        : Int = -1
  private var _ukChartTitle    : String = ""
  private var _labelId         : Int = -1
  private var _catalogueNumber : String = ""
  private var _productType     : String = ""
  private var _modified        : Bool = false
  private var _artist          : Artist?
  private var _sides           : [SingleSide] = []

  public var ChartListingId : Int {
    get {
      return _chartListingId
    }
    set(value) {
      if value != _chartListingId {
        _chartListingId = value
        Modified = true
      }
    }
  }
  
  public var ChartId : Int {
    get {
      return _chartId
    }
    set(value) {
      if value != _chartId {
        _chartId = value
        Modified = true
      }
    }
  }
  
  public var ArtistId : Int {
    get {
      return _artistId
    }
    set(value) {
      if value != _artistId {
        _artistId = value
        Modified = true
      }
    }
  }
  
  public var UKChartTitle : String {
    get {
      return _ukChartTitle
    }
    set(value) {
      if value != _ukChartTitle {
        _ukChartTitle = value
        Modified = true
      }
    }
  }
  
  var UKChartTitleClean : String {
    get {
      
      let singleSides = sides
      
      var temp = ""

      switch (singleSides.count) {
      case 2:
        temp = "the double A side "
        break
      case 3:
        temp = "the triple A side "
        break;
      case 4:
        temp = "the quadruple A side "
        break
      default:
        break
      }

      for i in 0...singleSides.count - 1 {
        if i > 0 {
          if i == singleSides.count - 1 {
            temp += " and "
          }
          else {
            temp += ", "
          }
        }
        temp += singleSides[i].UKChartTitleClean
      }
      
      return temp
    }
  }
  
  public var sides : [SingleSide] {
    get {
      if _sides.count == 0 {
        let bits = UKChartTitle.split(separator: "/")
        for bit in bits {
          let side = SingleSide()
          side.UKChartTitle = String(bit)
          side.ArtistId = ArtistId
          _sides.append(side)
        }
      }
      return _sides
    }
  }
  
  public var LabelId : Int {
    get {
      return _labelId
    }
    set(value) {
      if value != _labelId {
        _labelId = value
        Modified = true
      }
    }
  }
  
  public var LabelObj : Label? {
    get {
      return Label(labelid:LabelId)
    }
  }
  
  public var CatalogueNumber : String {
    get {
      return _catalogueNumber
    }
    set(value) {
      if value != _catalogueNumber {
        _catalogueNumber = value
        Modified = true
      }
    }
  }
  
  public var ProductType : String {
    get {
      return _productType
    }
    set(value) {
      if value != _productType {
        _productType = value
        Modified = true
      }
    }
  }
  
  public var Modified : Bool {
    get {
      return _modified
    }
    set(value) {
      _modified = value
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
  
  override init() {
    super.init()
  }
  
  init(listingId:Int) {
    
    super.init()
    
    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT " + ChartListing.ColumnNames + " FROM [\(TABLE.CHART_LISTING)] " +
      "WHERE [\(CHART_LISTING.CHART_LISTING_ID)] = @\(CHART_LISTING.CHART_LISTING_ID)"

    cmd.parameters.addWithValue(key: "@\(CHART_LISTING.CHART_LISTING_ID)", value: listingId)

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
  
  init(
    chartId:Int,
    artistId:Int,
    ukChartTitle:String,
    labelId:Int,
    catalogueNumber:String,
    productType:String
  ) {
    
    super.init()

    let conn = Database.getConnection()
    
    let shouldClose = conn.state != .Open
     
    if shouldClose {
       _ = conn.open()
    }
     
    let cmd = conn.createCommand()
     
    cmd.commandText = "SELECT " + ChartListing.ColumnNames + " FROM [\(TABLE.CHART_LISTING)] " +
      "WHERE [\(CHART_LISTING.CHART_ID)] = @\(CHART_LISTING.CHART_ID) AND " +
      "[\(CHART_LISTING.ARTIST_ID)] = @\(CHART_LISTING.ARTIST_ID) AND " +
      "[\(CHART_LISTING.UKCHART_TITLE)] = @\(CHART_LISTING.UKCHART_TITLE) AND " +
      "[\(CHART_LISTING.LABEL_ID)] = @\(CHART_LISTING.LABEL_ID) AND " +
      "[\(CHART_LISTING.CATALOGUE_NUMBER)] = @\(CHART_LISTING.CATALOGUE_NUMBER) AND " +
      "[\(CHART_LISTING.PRODUCT_TYPE)] = @\(CHART_LISTING.PRODUCT_TYPE)"

    cmd.parameters.addWithValue(key: "@\(CHART_LISTING.CHART_ID)", value: chartId)
    cmd.parameters.addWithValue(key: "@\(CHART_LISTING.ARTIST_ID)", value: artistId)
    cmd.parameters.addWithValue(key: "@\(CHART_LISTING.UKCHART_TITLE)", value: ukChartTitle)
    cmd.parameters.addWithValue(key: "@\(CHART_LISTING.LABEL_ID)", value: labelId)
    cmd.parameters.addWithValue(key: "@\(CHART_LISTING.CATALOGUE_NUMBER)", value: catalogueNumber)
    cmd.parameters.addWithValue(key: "@\(CHART_LISTING.PRODUCT_TYPE)", value: productType)

    if let reader = cmd.executeReader() {
         
      if reader.read() {
        decode(sqliteDataReader: reader)
      }
         
      reader.close()
         
    }
    
    if ChartListingId == -1 {
      ChartId = chartId
      ArtistId = artistId
      UKChartTitle = ukChartTitle
      LabelId = labelId
      CatalogueNumber = catalogueNumber
      ProductType = productType
      Save()
    }
       
    if shouldClose {
      conn.close()
    }

  }
  
  public func Save() {
    
    if Modified {
      
      var sql = ""
      
      if ChartListingId == -1 {
        sql = "INSERT INTO [\(TABLE.CHART_LISTING)] (" +
        "[\(CHART_LISTING.CHART_LISTING_ID)], " +
        "[\(CHART_LISTING.CHART_ID)], " +
        "[\(CHART_LISTING.ARTIST_ID)], " +
        "[\(CHART_LISTING.UKCHART_TITLE)], " +
        "[\(CHART_LISTING.LABEL_ID)], " +
        "[\(CHART_LISTING.CATALOGUE_NUMBER)], " +
        "[\(CHART_LISTING.PRODUCT_TYPE)]" +
        ") VALUES (" +
        "@\(CHART_LISTING.CHART_LISTING_ID), " +
        "@\(CHART_LISTING.CHART_ID), " +
        "@\(CHART_LISTING.ARTIST_ID), " +
        "@\(CHART_LISTING.UKCHART_TITLE), " +
        "@\(CHART_LISTING.LABEL_ID), " +
        "@\(CHART_LISTING.CATALOGUE_NUMBER), " +
        "@\(CHART_LISTING.PRODUCT_TYPE)" +
        ")"
        ChartListingId = Database.nextCode(tableName: TABLE.CHART_LISTING, primaryKey: CHART_LISTING.CHART_LISTING_ID)!
      }
      else {
        sql = "UPDATE [\(TABLE.CHART_LISTING)] SET " +
        "[\(CHART_LISTING.CHART_ID)] = @\(CHART_LISTING.CHART_ID), " +
        "[\(CHART_LISTING.ARTIST_ID)] = @\(CHART_LISTING.ARTIST_ID), " +
        "[\(CHART_LISTING.UKCHART_TITLE)] = @\(CHART_LISTING.UKCHART_TITLE), " +
        "[\(CHART_LISTING.LABEL_ID)] = @\(CHART_LISTING.LABEL_ID), " +
        "[\(CHART_LISTING.CATALOGUE_NUMBER)] = @\(CHART_LISTING.CATALOGUE_NUMBER), " +
        "[\(CHART_LISTING.PRODUCT_TYPE)] = @\(CHART_LISTING.PRODUCT_TYPE) " +
        "WHERE [\(CHART_LISTING.CHART_LISTING_ID)] = @\(CHART_LISTING.CHART_LISTING_ID)"
      }

      let conn = Database.getConnection()
      
      let shouldClose = conn.state != .Open
       
      if shouldClose {
         _ = conn.open()
      }
       
      let cmd = conn.createCommand()
       
      cmd.commandText = sql
      
      cmd.parameters.addWithValue(key: "@\(CHART_LISTING.CHART_LISTING_ID)", value: ChartListingId)
      cmd.parameters.addWithValue(key: "@\(CHART_LISTING.CHART_ID)", value: ChartId)
      cmd.parameters.addWithValue(key: "@\(CHART_LISTING.ARTIST_ID)", value: ArtistId)
      cmd.parameters.addWithValue(key: "@\(CHART_LISTING.UKCHART_TITLE)", value: UKChartTitle)
      cmd.parameters.addWithValue(key: "@\(CHART_LISTING.LABEL_ID)", value: LabelId)
      cmd.parameters.addWithValue(key: "@\(CHART_LISTING.CATALOGUE_NUMBER)", value: CatalogueNumber)
      cmd.parameters.addWithValue(key: "@\(CHART_LISTING.PRODUCT_TYPE)", value: ProductType)

      _ = cmd.executeNonQuery()

      if shouldClose {
        conn.close()
      }
      
      Modified = false

    }

  }

  public static var ColumnNames : String {
    get {
      return
        "[\(CHART_LISTING.CHART_LISTING_ID)], " +
        "[\(CHART_LISTING.CHART_ID)], " +
        "[\(CHART_LISTING.ARTIST_ID)], " +
        "[\(CHART_LISTING.UKCHART_TITLE)], " +
        "[\(CHART_LISTING.LABEL_ID)], " +
        "[\(CHART_LISTING.CATALOGUE_NUMBER)], " +
        "[\(CHART_LISTING.PRODUCT_TYPE)]"
    }
  }
  
  private func decode(sqliteDataReader:SqliteDataReader?) {
    
    if let reader = sqliteDataReader {
      
      ChartListingId = reader.getInt(index: 0)!
      
      if !reader.isDBNull(index: 1) {
        ChartId = reader.getInt(index: 1)!
      }
      
      if !reader.isDBNull(index: 2) {
        ArtistId = reader.getInt(index: 2)!
      }
      
      if !reader.isDBNull(index: 3) {
        UKChartTitle = reader.getString(index: 3)!
      }
      
      if !reader.isDBNull(index: 4) {
        LabelId = reader.getInt(index: 4)!
      }
      
      if !reader.isDBNull(index: 5) {
        CatalogueNumber = reader.getString(index: 5)!
      }
      
      if !reader.isDBNull(index: 6) {
        ProductType = reader.getString(index: 6)!
      }

    }
    
    Modified = false
    
  }

  public func bestAlbum() -> MusicAlbum? {
    
    var _bestAlbum : MusicAlbum?
    
    let conn = Database.getConnection()
        
    let shouldClose = conn.state != .Open
         
    if shouldClose {
      _ = conn.open()
    }
         
    let cmd = conn.createCommand()

    cmd.commandText =
      "SELECT [\(TRACK_OVERRIDE.MUSIC_PID)], [\(TRACK_OVERRIDE.NOT_THIS_TRACK)]  FROM [\(TABLE.TRACK_OVERRIDE)] " +
      "WHERE [\(TRACK_OVERRIDE.CHART_LISTING_ID)] = @\(TRACK_OVERRIDE.CHART_LISTING_ID) AND " +
      "[\(TRACK_OVERRIDE.SIDE_INDEX)] = 1"
        
    cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.CHART_LISTING_ID)", value: ChartListingId)

    var notThisAlbum = 0
    
    if let reader = cmd.executeReader() {
             
      if reader.read() {
        
        if reader.isDBNull(index: 0) {
          print("ChartListing.bestAlbum: override without musicPid")
        }
        else {
          
          let musicPid = reader.getInt(index: 0)!
          
          if !reader.isDBNull(index: 1) {
            notThisAlbum = reader.getInt(index: 1)!
          }
          
          if notThisAlbum == 0 {

            if let musicAlbum = musicLibrary.albums[musicPid] {
              
              let fm = FileManager.default
              
              var albumOK = true
              
              for musicTrack in musicAlbum.iTunesTracksSorted {
                if !fm.fileExists(atPath: musicTrack.location) {
                  albumOK = false
                  print(musicTrack.location)
                }
             }
              
              if albumOK {
                _bestAlbum = musicAlbum
              }
            }

          }
          
        }
        
      }
             
      reader.close()
             
    }
        
    if shouldClose {
      conn.close()
    }

    if notThisAlbum == 0 && _bestAlbum == nil {
      for album in musicAlbums {
        _bestAlbum = album
        break
      }
    }

    return _bestAlbum
  }
  
  var _musicAlbums : [MusicAlbum] = []
  
  public var musicAlbums : [MusicAlbum] {
     get {
      
       if _musicAlbums.count == 0 {

         let matches = musicLibrary.find(artistName: ArtistObj.UKChartName, albumName: UKChartTitle)
        
         for album in matches {
           _musicAlbums.append(album)
         }

       }

       return _musicAlbums
     }
   }

  
  public func bestTrack(index:Int) -> MusicTrack? {
    
    var _bestTrack : MusicTrack?
    
    let conn = Database.getConnection()
        
    let shouldClose = conn.state != .Open
         
    if shouldClose {
      _ = conn.open()
    }
         
    let cmd = conn.createCommand()

    cmd.commandText =
      "SELECT [\(TRACK_OVERRIDE.MUSIC_PID)], [\(TRACK_OVERRIDE.NOT_THIS_TRACK)]  FROM [\(TABLE.TRACK_OVERRIDE)] " +
      "WHERE [\(TRACK_OVERRIDE.CHART_LISTING_ID)] = @\(TRACK_OVERRIDE.CHART_LISTING_ID) AND " +
      "[\(TRACK_OVERRIDE.SIDE_INDEX)] = @\(TRACK_OVERRIDE.SIDE_INDEX)"
        
    cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.CHART_LISTING_ID)", value: ChartListingId)
    cmd.parameters.addWithValue(key: "@\(TRACK_OVERRIDE.SIDE_INDEX)", value: index)

    var notThisTrack = 0
    
    if let reader = cmd.executeReader() {
             
      if reader.read() {
        
        if reader.isDBNull(index: 0) {
          print("ChartListing.bestTrack: override without musicPid")
        }
        else {
          
          let musicPid = reader.getInt(index: 0)!
          
          if !reader.isDBNull(index: 1) {
            notThisTrack = reader.getInt(index: 1)!
          }
          
          if notThisTrack == 0 {

            if let musicTrack = musicLibrary.tracks[musicPid] {
              
              let fm = FileManager.default
              
              if fm.fileExists(atPath: musicTrack.location) {
                _bestTrack = musicTrack
              }
              else {
                print(musicTrack.location)
              }

            }

          }
          
        }
        
      }
             
      reader.close()
             
    }
        
    if shouldClose {
      conn.close()
    }

    if notThisTrack == 0 && _bestTrack == nil {
      let side = sides[index]
      for itrack in side.musicTracks {
        _bestTrack = itrack
        break
      }
    }

    return _bestTrack
  }
}
