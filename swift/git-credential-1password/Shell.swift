//
//  Shell.swift
//  git-credential-1password
//
//  Wrapper class for executing shell commands
//

import Foundation


class Shell {
  let console: Console
  let execPath: URL
  
  init(path: String) {
    self.console = Console()
    
    execPath = URL(fileURLWithPath: path)
  }
  
  // function to execute the execPath with given arguments
  // returns a tuple with:
  //    - stdout as String?
  //    - stderr as String?
  //    - return status from process called
  func execute(_ arguments: [String] = []) -> (String?, String?, Int32) {
    let task = Process()
    task.arguments = arguments
    
    let sOut = Pipe()
    let sErr = Pipe()
    task.standardOutput = sOut
    task.standardError = sErr
    
    do {
      console.write("Running process \(execPath.path) with args: \(arguments)", to: .error)
      try task.run()
    } catch {
      console.write("Error: \(error.localizedDescription)", to: .error)
      exit(-2)
    }
    
    // stdout and strerr to strings
    var data = sOut.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)
    data = sErr.fileHandleForReading.readDataToEndOfFile()
    let error = String(data: data, encoding: .utf8)
    
    console.write("Shell return status: \(task.terminationStatus)", to: .error)
    
    task.waitUntilExit()
    return (output, error, task.terminationStatus)
  }
  
  
  // function to prompt the user for secure input on the command line
  //  - disabled echo and displays a key icon
  func getPW(prompt: String = "Password:") -> String? {
    return String(cString: getpass(prompt))
  }
}
