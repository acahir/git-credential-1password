//
//  OP.swift
//  git-credential-1password
//
//  Class for handling interactions with the 1Password command line utility
//
//  Currently supports
//    - signin
//      Note: while this functionality works, it echos the 1P password on the terminal
//      so it not recommended for use
//    - get item
//

import Foundation

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

// 


class OP {
  let console: Console
  var requireEnvToken: Bool
  var token: String?

  init() {
    self.console = Console()
    requireEnvToken = false
  }
  
  // get a valid token for OP session
  // - first checks env for token
  // - if not found and requireEnvToken not set, will do op signin
  func getToken(_ domain: String = "my.1password.com") -> Bool {
    // check for a token in env
    let envVars = ProcessInfo.processInfo.environment
    for (key, val) in envVars {
      if key.hasPrefix("OP_SESSION_") {
        console.write("Found token in env vars", to: .error)
        self.token = val
        return true
      }
    }
    
    // op signin call not recommended because terminal is echoing pw when entered
    // Not sure why, when op called from a perl or python script, pw is not echoed
    if !requireEnvToken {
      let shell = Shell(path: opPath)
      
      let (optToken, optErr, status) = shell.execute(["signin", domain, "--output=raw"])
      if optToken != nil {
        self.token = optToken!
        return true
      } else {
        if let err = optErr {
          console.write("Error getting item: \(err) ", to: .error)
        }
        exitOnError(msg: "Return status: \(status) ", force: false, status: status)
      }
    } else {
      // no token found and token required
      exitOnError(msg:"No token found but required. You can get a new token with the command:\n    eval $(op signin \(domain))", force: true, status: 2)
    }
    
    return false
  }
  
  // get item json
  func getItem(query: String) -> String? {
    if let tok = token {
      let shell = Shell(path: opPath)
      
      let (optItem, optErr, status) = shell.execute(["get", "item", query, "--session=" + tok])
      guard let item = optItem, status == 0 else {
        if let err = optErr {
          if err.hasSuffix("You are not currently signed in. Please run `op signin --help` for instructions\n") {
            let msg = "Expired token found but required. You can get a new token for with the command:\n    eval $(op signin)"
            if requireEnvToken { exitOnError(msg: msg, force: true, status: 2) }
            // TODO - if getting tokens fixed, add else clause here to
            //   - get a new token and
            //   - call getItems .
            //   Be sure to guard against infinite recursion if getToken fails again
          } else {
            console.write("Error getting item: \(err) ", to: .error)
          }
        }
        exitOnError(msg: "Return status: \(status) ", force: false, status: status)
        return nil
      }
      // should now have a valid json object in item
      console.write("Received item:" + item.prefix(40) + "...", to: .error)
      return item
    }
    return nil
  }
  
  
  // parse item json
  func parseItem(data: String) -> OPItem? {
    do {
      let decoder = JSONDecoder()
      let records = try decoder.decode(OPItem.self, from: Data(data.utf8))
      
      return records
    } catch {
      // error decoding json
      exitOnError(msg: "Error decoding json", force: false, status: 1)
    }
    return nil
  }
  
  func printUsage(_ msg:String = "") {
    let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
    
    if msg != "" {
      console.write("\(msg)\n", to:.error)
    }
    
    console.write("usage: \(executableName) [ -hvq | --help | --verbose | --quiet ] item\n")
    console.write("  searches for item and prints username and password to stout if found\n")
    console.write("  -v, --verbose  prints out verbose (debug) messages")
    console.write("  -q, --quiet    suppresses all standard output messages")
    console.write("  note: -v and -q are independent, -q will not supress -v messages\n")
    console.write("  returns  0  if item exists")
    console.write("           N  if N (> 1) items found")
    console.write("          -1  if item not found")
    console.write("          -2  if this message was displayed")
    console.write("           1  in all other cases")
  }
}
