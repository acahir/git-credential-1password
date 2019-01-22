#!/usr/bin/env swift

import Foundation

// parse args and set options if needed
let verbose = false
let quiet = false

// can avoid this by using /usr/local/env op
let opPath = "/usr/local/bin/op"

// defaults while developting/testing
let domain = "my.1password.com"
let host = "github.com"

enum OutputType {
  case error
  case standard
}

/* ---- Structs, Classes, and Functions ---- */
struct OPItem: Decodable {
  let details: OPItemDetails
}
struct OPItemDetails: Decodable {
  let fields: [OPItemDetailsFields]
}
struct OPItemDetailsFields: Decodable {
  let designation: String
  let value: String
}

class ConsoleIO {
  func writeMessage(_ message: String, to: OutputType = .standard) {
    switch to {
    case .standard:
      // 1
      print("\(message)")
    case .error:
      // 2
      fputs("\(message)\n", stderr)
      // fputs("\u{001B}[0;31m\(message)\n", stderr) // red
    }
  }
  
  func printUsage(_ msg:String = "") {
    let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
    
    if msg != "" {
      writeMessage("\(msg)\n", to:.error)
    }
    
    writeMessage("usage: \(executableName) [ -hvq | --help | --verbose | --quiet ] item\n")
    writeMessage("  searches for item and prints username and password to stout if found\n")
    writeMessage("  -v, --verbose  prints out verbose (debug) messages")
    writeMessage("  -q, --quiet    suppresses all standard output messages")
    writeMessage("  note: -v and -q are independent, -q will not supress -v messages\n")
    writeMessage("  returns  0  if item exists")
    writeMessage("           N  if N (> 1) items found")
    writeMessage("          -1  if item not found")
    writeMessage("          -2  if this message was displayed")
    writeMessage("           1  in all other cases")
  }
}

let consoleIO = ConsoleIO()

func shell(_ launchPath: String, _ arguments: [String] = []) -> (String?, Int32) {
  let task = Process()
  task.executableURL = URL(fileURLWithPath: launchPath)
  task.arguments = arguments
  
  let pipe = Pipe()
  task.standardOutput = pipe
  task.standardError = pipe
  do {
    if verbose { consoleIO.writeMessage("Running process \(launchPath) with args: \(arguments)", to: .error) }
    try task.run()
  } catch {
    consoleIO.writeMessage("Error: \(error.localizedDescription)", to: .error)
    exit(-2)
  }
    
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  let output = String(data: data, encoding: .utf8)
  if verbose {
    consoleIO.writeMessage("Shell return status: \(task.terminationStatus)", to: .error)
  }
  
  task.waitUntilExit()
  return (output, task.terminationStatus)
}

func getPW() -> String? {
  return String(cString: getpass("Password:"))
}

// gets a valid 1Password token either from env or from a signin
func getOpToken(_ opDomain: String = domain) -> String? {
  // check for a token in env
  let envVars = ProcessInfo.processInfo.environment
  for (key, val) in envVars {
    if key.hasPrefix("OP_SESSION_") {
      if verbose { consoleIO.writeMessage("Found token in env vars", to: .error) }
      return val
    }
  }
  
  // op signin call currently disabled because terminal is echoing pw when entered
  // Not sure why, when op called from a perl or python script, pw is not echoed
  // also can prompt for a password in termianl from this script using getpass()
//  let (optToken, _) = shell(opPath, ["signin", opDomain, "--output=raw"])
//  if let token = optToken {
//    return token
//  } else {
//    // TODO - handle error
//  }
  
  // default return
  return nil
}
/* ---- End Structs, Classes, and Functions ----- */

// begin script execution here
var status: Int32 = 0

// get a valid token
let optToken = getOpToken(domain)
guard let token = optToken else {
  // TODO - handle error
  exit(2)
}

// get item json
var optItem: String?
(optItem, status) = shell(opPath, ["get", "item", host, "--session=" + token])
guard let item = optItem, status == 0 else {
  // TODO - handle error
  if let item = optItem {
    consoleIO.writeMessage("Error getting item: \(item) ", to: .error)
  }
  consoleIO.writeMessage("Reeturn status: \(status) ", to: .error)
  exit(-2)
}

// should now have a valid json object in item
if verbose {
  consoleIO.writeMessage("Received item:" + item.prefix(50) + "...", to: .error)
}

// parse json
do {
  let decoder = JSONDecoder()
  let records = try decoder.decode(OPItem.self, from: Data(item.utf8))
  
  var user = ""
  var pass = ""
  if (records.details.fields.count > 0) {
    for field in records.details.fields {
      if field.designation == "username" {
        user = field.value
      } else if field.designation == "password" {
        pass = field.value
      }
    }
  } else {
    print("No Fields")
  }
  
  print("username=\(user)\npassword=\(pass)\n")
} catch {
  // error decoding json
  print("Error decoding json")
}

exit(0)
