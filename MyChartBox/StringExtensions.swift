//
//  StringExtensions.swift
//  MyChartBox
//
//  Created by Paul Willmott on 10/01/2021.
//  Copyright © 2021 Paul Willmott. All rights reserved.
//

import Foundation

extension String {

  func fileName() -> String {
    return URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
  }

  func fileExtension() -> String {
    return URL(fileURLWithPath: self).pathExtension
  }
  
}
