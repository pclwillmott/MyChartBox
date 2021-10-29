//
//  UpdateVC.swift
//  MyChartBox
//
//  Created by Paul Willmott on 13/12/2020.
//  Copyright © 2020 Paul Willmott. All rights reserved.
//

import Foundation
import Cocoa

class UpdateVC: NSViewController, NSWindowDelegate {

  override func viewDidLoad() {
      
    super.viewDidLoad()
    
    cboBaseInterval.stringValue = UserDefaults.standard.string(forKey: DEFAULT.BASE_INTERVAL) ?? "120 seconds"

    cboVariance.stringValue = UserDefaults.standard.string(forKey: DEFAULT.VARIANCE) ?? "20 seconds"
    
    cboMethod.stringValue = UserDefaults.standard.string(forKey: DEFAULT.METHOD) ?? "Random"

    cboMaxLoads.stringValue = UserDefaults.standard.string(forKey: DEFAULT.MAXLOADS) ?? "1"
    
    cboChart.stringValue = UserDefaults.standard.string(forKey: DEFAULT.CHART) ?? "Singles"
    
  }
  
  func close() {
    
    UserDefaults.standard.set(cboBaseInterval.stringValue, forKey: DEFAULT.BASE_INTERVAL)
    UserDefaults.standard.set(cboVariance.stringValue, forKey: DEFAULT.VARIANCE)
    UserDefaults.standard.set(cboMethod.stringValue, forKey: DEFAULT.METHOD)
    UserDefaults.standard.set(cboMaxLoads.stringValue, forKey: DEFAULT.MAXLOADS)
    UserDefaults.standard.set(cboChart.stringValue, forKey: DEFAULT.CHART)

    stopModal()
    self.view.window?.close()
  }
  
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    close()
    return true
  }
  
  override func viewDidAppear() {
    self.view.window!.delegate = self
  }
  
  @IBOutlet weak var btnUpdate: NSButton!
  
  @IBOutlet weak var btnCancel: NSButton!
  
  @IBOutlet weak var cboBaseInterval: NSComboBox!
  
  @IBOutlet weak var cboMethod: NSComboBox!
  
  @IBOutlet weak var cboChart: NSComboBox!
  
  @IBOutlet weak var cboVariance: NSComboBox!
  
  @IBOutlet weak var cboMaxLoads: NSComboBox!
  
  @IBOutlet weak var barProgress: NSProgressIndicator!
  
  @IBOutlet weak var lblProgress: NSTextField!
  
  var timer : Timer?
  
  func startTimer() {
    
    let baseLookup : [String:Int] = [
      "30 seconds" : 30,
      "45 seconds" : 45,
      "60 seconds" : 60,
      "90 seconds" : 90,
      "120 seconds" : 120,
      "240 seconds" : 240,
    ]
    
    let baseInterval = baseLookup[cboBaseInterval.stringValue]!
    
    let varianceLookup : [String:Int] = [
      "10 seconds" : 10,
      "15 seconds" : 15,
      "20 seconds" : 20,
    ]
    
    let variance = varianceLookup[cboVariance.stringValue]!
    
    let randomNumber = baseInterval + Int.random(in: 0...variance)
    
    timer = Timer.scheduledTimer(timeInterval: Double(randomNumber), target: self, selector: #selector(runCode), userInfo: nil, repeats: false)
  }
  
  var cancel = false
  
  var last_number : Int = 1;
  
  var loadCount : Int = 0
 
  @objc func runCode() {
    
    let chartId = cboChart.stringValue == "Singles" ? 1 : 2
    
    let date = Date()
    
    let week = weekFromDate(chartId: chartId, date: date)

    var count : Int = 0
    var chart : Date = Date()

    if cboMethod.stringValue == "Random" {
      repeat {
        let randomWeek = Int.random(in: 1...week)
        chart = chartDate(chartId: chartId, week: randomWeek)
        count = entryCount(chartId: chartId, date: chart)
      } while count != 0
    }
    else {
      if last_number == week {
        btnUpdate.isEnabled = true
        return
      }
      for w in last_number...week {
        last_number = w
        chart = chartDate(chartId: chartId, week: w)
        count = entryCount(chartId: chartId, date: chart)
        if (count == 0) {
          break;
        }
      }
    }
    

    getChart(chartId: chartId, date: chart)
    
    let dc = doneCount(chartId: chartId)
    barProgress.doubleValue = Double(dc)/Double(week)*100.0
    lblProgress.stringValue = "\(dc) of \(week)"

    loadCount += 1

    if !cancel && loadCount < cboMaxLoads.intValue && dc < week {
      startTimer()
    }
    else {
      btnUpdate.isEnabled = true
    }
    
  }

  @IBAction func btnUpdate(_ sender: NSButton) {
    barProgress.isHidden = false
    lblProgress.isHidden = false
    btnUpdate.isEnabled = false
    last_number = 1
    cancel = false
    loadCount = 0
    runCode()
  }
  
  @IBAction func btnCancel(_ sender: NSButton) {
    cancel = true
    timer?.invalidate()
    close()
  }
  
}
