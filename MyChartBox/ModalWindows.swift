//
//  ModalWindows.swift
//  MyChartBox
//
//  Created by Paul Willmott on 03/08/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa

@available(OSX 10.14, *)
var mainVC : MainVC?

enum AppStoryboard : String {
  
  case Main                       = "Main"
  case SelectOverride             = "SelectOverride"
  case ArtistView                 = "ArtistView"
  case Preferences                = "Preferences"
  case Update                     = "Update"
  case AlbumPlayer                = "AlbumPlayer"
  case Associate                  = "Associate"
  case ArtistAlbumsPlayer         = "ArtistAlbumsPlayer"
  case ArtistSinglesPlayer        = "ArtistSinglesPlayer"
  case ChartSinglesPlayer         = "ChartSinglesPlayer"
  case ChartAlbumsPlayer          = "ChartAlbumsPlayer"

  var instance : NSStoryboard {
    return NSStoryboard(name: self.rawValue, bundle: Bundle.main)
  }
  
}

let storyboardLookup           : [String:AppStoryboard] = [
  "SelectOverride"             : AppStoryboard.SelectOverride,
  "ArtistView"                 : AppStoryboard.ArtistView,
  "Preferences"                : AppStoryboard.Preferences,
  "Update"                     : AppStoryboard.Update,
  "AlbumPlayer"                : AppStoryboard.AlbumPlayer,
  "Associate"                  : AppStoryboard.Associate,
  "ArtistAlbumsPlayer"         : AppStoryboard.ArtistAlbumsPlayer,
  "ArtistSinglesPlayer"        : AppStoryboard.ArtistSinglesPlayer,
  "ChartSinglesPlayer"         : AppStoryboard.ChartSinglesPlayer,
  "ChartAlbumsPlayer"          : AppStoryboard.ChartAlbumsPlayer,
]

/*
 * 1) No spaces in identifiers
 * 2) Storyboard ID of WINDOW not VIEW of xxxWC
 * 3) Remember to ctrl+drag button to controller icon and select class to destroy instance
 * 4) View and Window controller instances named xxxVC and xxxWC
 * 5) Turn off Minimize, Maxmize, Resize on Window Controller
 * 6) Add the turn off modal code
 */

enum ModalWindow : String {
  
  case SelectOverride         = "SelectOverride"
  case ArtistView             = "ArtistView"
  case Preferences            = "Preferences"
  case Update                 = "Update"
  case AlbumPlayer            = "AlbumPlayer"
  case Associate              = "Associate"
  case ArtistAlbumsPlayer     = "ArtistAlbumsPlayer"
  case ArtistSinglesPlayer    = "ArtistSinglesPlayer"
  case ChartSinglesPlayer     = "ChartSinglesPlayer"
  case ChartAlbumsPlayer      = "ChartAlbumsPlayer"

  var windowController : NSWindowController {
    let storyboard = storyboardLookup[self.rawValue]!
    let wc = storyboard.instance.instantiateController(withIdentifier: "\(self.rawValue)WC") as! NSWindowController
    return wc
  }
  
  public func runModal(windowController: NSWindowController) {
    if let window = windowController.window {
      NSApplication.shared.runModal(for: window)
      window.close()
    }
  }

  public func runModel() {
    runModal(windowController: self.windowController)
  }
  
  public func viewController(windowController: NSWindowController) -> NSViewController {
    return windowController.window!.contentViewController! // as! xxxViewController
  }
  
}

func stopModal() {
  NSApplication.shared.stopModal()
}

func selectOverride(chartListing:ChartListing, sideIndex:Int) {
  let x = ModalWindow.SelectOverride
  let wc = x.windowController
  let vc = x.viewController(windowController: wc) as! SelectOverrideVC
  vc.chartListing = chartListing
  vc.sideIndex = sideIndex
  x.runModal(windowController: wc)
}

func artistView() {
  let x = ModalWindow.ArtistView
  let wc = x.windowController
//  let vc = x.viewController(windowController: wc) as! ArtistViewVC
//  x.runModal(windowController: wc)
  wc.showWindow(nil)
}

func associate() {
  let x = ModalWindow.Associate
  let wc = x.windowController
//  let vc = x.viewController(windowController: wc) as! AssociateVC
//  x.runModal(windowController: wc)
  wc.showWindow(nil)
}

func artistAlbumsPlayer() {
  let x = ModalWindow.ArtistAlbumsPlayer
  let wc = x.windowController
//  let vc = x.viewController(windowController: wc) as! AssociateVC
//  x.runModal(windowController: wc)
  wc.showWindow(nil)
}

func artistSinglesPlayer() {
  let x = ModalWindow.ArtistSinglesPlayer
  let wc = x.windowController
//  let vc = x.viewController(windowController: wc) as! AssociateVC
//  x.runModal(windowController: wc)
  wc.showWindow(nil)
}

func chartSinglesPlayer() {
  let x = ModalWindow.ChartSinglesPlayer
  let wc = x.windowController
//  let vc = x.viewController(windowController: wc) as! AssociateVC
//  x.runModal(windowController: wc)
  wc.showWindow(nil)
}

func chartAlbumsPlayer() {
  let x = ModalWindow.ChartAlbumsPlayer
  let wc = x.windowController
//  let vc = x.viewController(windowController: wc) as! AssociateVC
//  x.runModal(windowController: wc)
  wc.showWindow(nil)
}

func preferences() {
  let x = ModalWindow.Preferences
  let wc = x.windowController
//  let vc = x.viewController(windowController: wc) as! PreferencesVC
  x.runModal(windowController: wc)
}

func updateView() {
  let x = ModalWindow.Update
  let wc = x.windowController
//  let vc = x.viewController(windowController: wc) as! UpdateVC
  wc.showWindow(nil)
}

func albumPlayer(album:MusicAlbum, delegate:AlbumPlayerDelegate, startAtBeginning:Bool) -> AlbumPlayerVC {
  let x = ModalWindow.AlbumPlayer
  let wc = x.windowController
  let vc = x.viewController(windowController: wc) as! AlbumPlayerVC
  vc.album = album
  vc.delegate = delegate
  vc.startAtBeginning = startAtBeginning
  wc.showWindow(nil)
  return vc
}



