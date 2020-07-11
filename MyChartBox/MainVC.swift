//
//  MainVC.swift
//  MyChartBox
//
//  Created by Paul Willmott on 05/07/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Cocoa

class MainVC: NSViewController {

  var timer : Timer?
  
  @objc func runCode()
  {
    let randomNumber = Int.random(in: 3...10)
    TestLabel.intValue = Int32(randomNumber)
    timer = Timer.scheduledTimer(timeInterval: Double(randomNumber), target: self, selector: #selector(runCode), userInfo: nil, repeats: false)
  }
  // https://www.officialcharts.com/charts/singles-chart/20110703/7501/
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    
    
//    if let url = URL(string: "xhttps://www.officialcharts.com/charts/singles-chart/20110703/7501/") {

    let path = "/Users/paul/Documents/MyChartBox/Test.html"
    
    do {
      
      let contents = try String(contentsOfFile: path, encoding: .utf8)
    //  print(contents) // print contents of file
      process(input: contents)
      
    }
    catch {}
    /*
    if let url = URL(string: "/Users/paul/Documents/MyChartBox/Test.html") {
      do {
        let contents = try String(contentsOf: url, encoding: .utf8)
        print(contents)
      } catch
      {
        // contents could not be loaded
      }
    }
    else {
      // the URL was bad!
    }
 */
    //   runCode()
  }
  
  func process(input:String) {
    
    let start_tags : [String] =
    [
      "<span class=\"position\">",
      "<span class=\"last-week",
      "<div class=\"title\">",
      "<div class=\"artist\">",
      "<div class=\"label-cat\"><span class=\"label\">",
      "<a href=\"\" data-productid="
    ]
    
    let end_tags : [String] =
    [
      "</span>",
      "</span>",
      "</div>",
      "</div>",
      "</span>",
    ]
    
    let lines : [Substring] = input.split(separator: "\n")
    let n = lines.count
    
    var i : Int = 0
    var nextLine : Bool = false
    var activeTag : Int = 0;
    
    var position : String = ""
    var last_position : String = ""
    var title : String = ""
    var artist : String = ""
    var label : String = ""
    var number : String = ""
    
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
              print(position, last_position, title, artist, label, number)
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
  
  func getNumber(line:String) -> String {
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

    return String(parts[2])
  }
  
  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }

  @IBOutlet weak var TestLabel: NSTextField!
  
}

