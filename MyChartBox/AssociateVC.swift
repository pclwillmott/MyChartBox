//
//  AssociateVC.swift
//  MyChartBox
//
//  Created by Paul Willmott on 03/01/2021.
//  Copyright © 2021 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa

class AssociateVC: NSViewController, NSSearchFieldDelegate {

  private var collectionDS = ComboBoxDataSource(tableName: TABLE.COLLECTION, codeColumn: COLLECTION.COLLECTION_ID, displayColumn: COLLECTION.COLLECTION_NAME, sortColumn: COLLECTION.SORT_NAME)
  
  private var collection : ArtistCollection?

  private var sourceDS = ChartArtistTableViewDS()
  private var destDS = ChartArtistTableViewDS()

  private var sources : [Artist] = []
  private var dests   : [Artist] = []
  
  // View Control
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
    
    cboArtistName.dataSource = collectionDS
    cboArtistName.delegate   = collectionDS
    
    sourceDS.artists = sources
    destDS.artists = dests
    
    tblPossibleAssociations.dataSource = sourceDS
    
    tblAssociatedArtists.dataSource = destDS

    tblPossibleAssociations.delegate = sourceDS
    
    tblAssociatedArtists.delegate = destDS
    
    txtSearch.delegate = self
    
    btnDeleteArtist.isEnabled = false
    btnRemoveAssociation.isEnabled = false
    btnAddAssociation.isEnabled = false
     
  }

// Outlets and Actions
  
  @IBOutlet weak var cboArtistName: NSComboBox!
  
  @IBAction func cboArtistNameAction(_ sender: NSComboBox) {
    if !sender.stringValue.isEmpty {
      let code = collectionDS.codeOfItemWithStringValue(string: sender.stringValue)
      if code != -1 {
        collection = ArtistCollection(collectionid: code)
      }
      else {
        collection = ArtistCollection()
        collection?.collectionName = sender.stringValue
        collection?.Save()
        collectionDS.reloadData()
        cboArtistName.reloadData()
      }
      btnDeleteArtist.isEnabled = true
    }
    txtSearch.stringValue = sender.stringValue
    refreshSources(artist: sender.stringValue)
    refreshDests()
  }

  private func refreshSources(artist:String) {
  
    sources.removeAll()
    
    if let coll = collection {
    
      let conn = Database.getConnection()
               
      let shouldClose = conn.state != .Open
                
      if shouldClose {
        _ = conn.open()
      }
                
      let cmd = conn.createCommand()
      
      var artistName = artist
      
      if artistName.prefix(4).uppercased() == "THE " {
        artistName = artistName.suffix(artistName.count-4).trimmingCharacters(in: .whitespacesAndNewlines)
      }
                
      cmd.commandText = "SELECT " + Artist.ColumnNames + " FROM [\(TABLE.ARTIST)] " +
      "WHERE [\(ARTIST.UKCHART_NAME)] LIKE @\(ARTIST.UKCHART_NAME) AND " +
      "[\(ARTIST.ARTIST_ID)] NOT IN (\(coll.links)) " +
      "ORDER BY [\(ARTIST.UKCHART_NAME)]"
               
      cmd.parameters.addWithValue(key: "@\(ARTIST.UKCHART_NAME)", value: "%\(artistName)%")
    
      if let reader = cmd.executeReader() {

        while reader.read() {
          sources.append(Artist(reader:reader))
        }
        
        reader.close()
                    
      }
               
      if shouldClose {
        conn.close()
      }
    
    }
    
    sourceDS.artists = sources
    tblPossibleAssociations.reloadData()
    btnAddAssociation.isEnabled = sources.count != 0

  }

  private func refreshDests() {
  
    dests.removeAll()
    
    if collection != nil {

      let conn = Database.getConnection()
               
      let shouldClose = conn.state != .Open
                
      if shouldClose {
        _ = conn.open()
      }
                
      let cmd = conn.createCommand()
                
      cmd.commandText = "SELECT " + Artist.ColumnNames + " FROM [\(TABLE.ARTIST)] " +
        "WHERE [\(ARTIST.ARTIST_ID)] IN (\(collection!.links)) " +
        "ORDER BY [\(ARTIST.UKCHART_NAME)]"
               
      if let reader = cmd.executeReader() {

        while reader.read() {
          dests.append(Artist(reader:reader))
        }
        
        reader.close()
                    
      }
               
      if shouldClose {
        conn.close()
      }

    }
    
    destDS.artists = dests
    tblAssociatedArtists.reloadData()
    btnRemoveAssociation.isEnabled = dests.count != 0

  }

  @IBOutlet weak var btnDeleteArtist: NSButton!
  
  @IBAction func btnDeleteArtistAction(_ sender: Any) {
    
    if let col = collection {

      let commands = [
        "DELETE FROM [\(TABLE.COLLECTION)] WHERE " +
        "[\(COLLECTION.COLLECTION_ID)] = \(col.collectionId)"
      ]
    
      Database.execute(commands: commands)
    
    }
    
    collection = nil
    
    collectionDS.reloadData()
    cboArtistName.reloadData()
    cboArtistName.stringValue = ""
    btnDeleteArtist.isEnabled = false
    refreshDests()
    refreshSources(artist: "")
    txtSearch.stringValue = ""

  }
  
  @IBOutlet weak var tblPossibleAssociations: NSTableView!
  
  @IBAction func tblPossibleAssiciationsDoubleAction(_ sender: NSTableView) {
    addAssociation()
  }
  
  @IBOutlet weak var tblAssociatedArtists: NSTableView!
  
  @IBAction func tblAssociatedArtistsDoubleAction(_ sender: Any) {
    removeAssociation()
  }
  
  @IBOutlet weak var btnAddAssociation: NSButton!
  
  func addAssociation() {
    if let artist = collection {
      for index in tblPossibleAssociations.selectedRowIndexes {
        if !artist.links.isEmpty {
          artist.links += ", "
        }
        let chartArtist = sources[index]
        artist.links += "\(chartArtist.ArtistId)"
      }
      artist.Save()
      refreshDests()
      refreshSources(artist: txtSearch.stringValue)
    }
  }
  
  @IBAction func btnAddAssociationAction(_ sender: NSButton) {
    addAssociation()
  }
  
  @IBOutlet weak var btnRemoveAssociation: NSButton!
  
  func removeAssociation() {
    if let artist = collection {
      artist.links = ""
      for index in 0..<tblAssociatedArtists.numberOfRows {
        if !tblAssociatedArtists.isRowSelected(index) {
          if !artist.links.isEmpty {
            artist.links += ", "
          }
          artist.links += "\(dests[index].ArtistId)"
        }
      }
      artist.Save()
      refreshDests()
      refreshSources(artist: txtSearch.stringValue)
    }
  }
  
  @IBAction func btnRemoveAssociationAction(_ sender: NSButton) {
    removeAssociation()
  }
  
  @IBOutlet weak var txtSearch: NSSearchField!
  
  func controlTextDidChange(_ obj: Notification) {
//    let x: NSTextField = obj.object! as! NSTextField
    refreshSources(artist: txtSearch.stringValue)
  }

}

