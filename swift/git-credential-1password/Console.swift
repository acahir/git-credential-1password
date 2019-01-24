//
//  Console.swift
//  git-credential-1password
//
//  Created by Steve Cochran on 1/23/19.
//  Copyright © 2019 Steve Cochran. All rights reserved.
//

import Foundation

enum OutputType {
  case error
  case standard
}

// central class to handle outputs based on options
// Relies on externals:
// - Options.verbose
// - Options.quiet
class Console {
  func write(_ message: String, to: OutputType = .standard, force: Bool = false) {
    switch to {
    case .standard:
      if !options.quiet {
        print("\(message)")
      }
      
    case .error:
      if (options.verbose || force) {
        fputs("\(message)\n", stderr)
        // fputs("\u{001B}[0;31m\(message)\n", stderr) // red
      }
    }
  }
}
