//
//  UpdaterTools.swift
//  MyChartBox
//
//  Created by Paul Willmott on 13/12/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation

func getChart(chartId:Int, date:Date) {

  // Build web page url.
    
  var calendar = Calendar.current
  calendar.timeZone = TimeZone(secondsFromGMT: 0)!
  let year  = calendar.component(.year,  from: date)
  let month = calendar.component(.month, from: date)
  let day   = calendar.component(.day,   from: date)
  
  var fn = ""
  if chartId == 2 {
    fn = String(format:"https://www.officialcharts.com/charts/albums-chart/%04d%02d%02d/7502/", year, month, day)
  }
  else {
    fn = String(format:"https://www.officialcharts.com/charts/singles-chart/%04d%02d%02d/7501/", year, month, day)
  }

  // Retrieve page and decode.
    
  if let url = URL(string: fn) {
    do {
      let contents = try String(contentsOf: url)
      decodePage(chartId:chartId, input: contents, chartDate: date)
    }
    catch {
      print("contents could not be loaded")
    }
  }
  else {
    print("the URL was bad!")
  }
  
}

func decodePage(chartId:Int, input:String, chartDate:Date) {
    
  let start_tags : [String] =
  [
    "<span class=\"position\">",
    "<span class=\"last-week",
    "<div class=\"title\">",
    "<div class=\"artist\">",
    "<div class=\"label-cat\"><span class=\"label\">",
    "<a href=\"\" data-productid=",
    "<!-- Peak Position-->",
    "<!-- Wks -->"
  ]
    
  let nl : Character = "\u{000d}\u{000a}"
    
  let lines : [Substring] = input.split(separator: nl)
  let n = lines.count
    
  var i : Int = 0
  var nextLine : Bool = false
  var activeTag : Int = 0;
    
  var position : String = ""
  var last_position : String = ""
  var title : String = ""
  var artist : String = ""
  var label : String = ""
  var number : (String,String) = ("","")
  var peak : String = ""
  var weeks : String = ""
    
  while i < n {
    let trimmedString = (lines[i]).trimmingCharacters(in: .whitespaces)
    if nextLine {
      switch (activeTag) {
      case 1:
        last_position = getValue(line: trimmedString)
      case 2:
        title = getValue(line: trimmedString)
      case 3:
        artist = getValue(line: trimmedString)
      case 6:
        peak = getValue(line: trimmedString)
      case 7:
        weeks = getValue(line: trimmedString)
      default:
        break
      }
      nextLine = false;
    }
    else {
      for tag_index in 0...start_tags.count-1 {
        let tag = start_tags[tag_index]
        if trimmedString.prefix(tag.count) == tag {
          switch (tag_index) {
          case 0:
            position = getValue(line: trimmedString)
          case 1:
            activeTag = tag_index
            nextLine = true
          case 2:
            activeTag = tag_index
            nextLine = true
          case 3:
            activeTag = tag_index
            nextLine = true
          case 4:
            label = getValue(line: trimmedString)
          case 5:
            number = getNumber(line: trimmedString)
            artist = String(artist.prefix(artist.count)).replacingOccurrences(of: "&amp;", with: "&")
            artist = String(artist.prefix(artist.count)).replacingOccurrences(of: "&#39;", with: "'")
            title = String(title.prefix(title.count)).replacingOccurrences(of: "&amp;", with: "&")
            title = String(title.prefix(title.count)).replacingOccurrences(of: "&#39;", with: "'")
            label = String(label.prefix(label.count)).replacingOccurrences(of: "&amp;", with: "&")
            label = String(label.prefix(label.count)).replacingOccurrences(of: "&#39;", with: "'")
            let chartObj = Chart(chartId: chartId)
            let artistObj = Artist(ukChartName: artist)
            let labelObj = Label(ukChartName: label)
            let chartListingObj = ChartListing(chartId: chartObj.chartId, artistId: artistObj.ArtistId, ukChartTitle: title, labelId: labelObj.LabelId, catalogueNumber: number.0, productType: number.1)
            let chartEntryObj = ChartEntry(chartListingId: chartListingObj.ChartListingId, chartDate: chartDate, position: position, lastPosition: last_position, highestPosition: peak, weeksOnChart: weeks)
            print("\(chartEntryObj.ChartEntryId) \"\(artistObj.ArtistName)\" \"\(chartListingObj.UKChartTitle)\" \"\(labelObj.UKChartName)\" \"\(chartListingObj.CatalogueNumber)\" \"\(chartEntryObj.ChartDate)\" \"\(chartEntryObj.Position)\"")
          case 6:
            activeTag = tag_index
            nextLine = true
          case 7:
            activeTag = tag_index
            nextLine = true
          default:
            break
          }
          break
        }
      }
    }
    i += 1
  }
    
}
  
func getValue(line:String) -> String {
  var result : String = ""
  var inTag : Bool = false;
  for c in line {
    if c == "<" {
      inTag = true;
    }
    else if c == ">" {
      inTag = false;
    }
    else if !inTag {
      result += String(c);
    }
  }
  return result
}

func getNumber(line:String) -> (String, String) {
  
  var result : String = ""
  var inTag : Bool = false;
  var index : Int = 0;
  
  for c in line {
    if inTag {
      if c == "\"" {
        inTag = false
        index += 1
        if index == 2 {
          break
        }
      }
      else {
        result += String(c)
      }
    }
    else if c == "\"" {
      inTag = true
    }
  }
  
  let parts = result.split(separator: "-")

  return (String(parts[2]), String(parts[3]))
}
