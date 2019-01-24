#!/usr/bin/env swift

import Foundation

/* ---- variables and default values ---- */

let opPath = "/usr/local/bin/op"

struct Options {
  var verbose = false
  var quiet = false
  var requireEnvToken = false
  var domain = "my.1password.com"
}

struct MainVars {
  var status: Int32 = 0
  var gtg = false
  var params = [String:String]()
}

var options = Options()
var main = MainVars()

/* ---- Structs, Classes, and Helper Functions ---- */

/* -- CONSOLE_CLASS  -- */


// exitOnError function
// - conditionally displays msg based on verbose and force
// - sends quit signal to git crediental if in quiet mode
// - exits with status
func exitOnError(msg: String, force: Bool, status: Int32) {
  // tell github credential to quit if we encounter an error
  if options.quiet {
    print("quit=1")
  }
  if (options.verbose || force) {
    fputs("\(msg)\n", stderr)
  }
  exit(status)
}


/* -- SHELL_CLASS  -- */

/* -- OP_CLASS  -- */

/* ---- End Structs, Classes, and Helper Functions ---- */

// init objects
let console = Console()
let op = OP()


// -d --domain, -h --help, -q --quiet, -t --token, -v --verbose
func parseArgs() {
  let args = CommandLine.arguments[1...] // all but first arg to exclude the executable
  for (index, arg) in args.enumerated() {
    let splitArg = arg.components(separatedBy: "=")
    // process each arg
    switch splitArg[0] {
    case "-d":
      options.domain = args[index + 1]
      // sanity check, should not start with a '-'
      if options.domain.prefix(1) == "-" {
        exitOnError(msg: "Error reading domain following option '-d'", force: false, status: 1)
      }
    case "--domain":
      if splitArg.count == 2 {
        options.domain = splitArg[1]
      } else {
        exitOnError(msg: "Error reading value from option '--domain'", force: false, status: 1)
      }
    case "-h", "--help":
      op.printUsage()
      exit(0)
    case "-q", "--quiet":
      options.quiet = true
    case "-t", "--token":
      options.requireEnvToken = true
    case "-v", "--verbose":
      options.verbose = true
    case "get":
      // this should be the final arg, but don't rely on that
      // we found 'get' arg, so we're good to go
      main.gtg = true
    case "store", "erase":
      exitOnError(msg: "Launched with arg: \(arg). This utility only supports get requests.", force: false, status: 0)
    default:
      // warn if unknown arg, but don't need to exit if all others are good
      console.write("Unknown argument: \(arg), ignoring ", to: .error) }
  }
}

/* ---- End Structs, Classes, and Functions ----- */



/* ---- Script Execution Begins Here ---- */

// parse command line arguments
parseArgs()

console.write("Launched with options: \(CommandLine.arguments[1...])", to: .error)

// check to make sure we have everything we need and how to continue
//   ie interactively or automated
if !main.gtg {
  exitOnError(msg: "Missing 'get' arg. This utility only supports get requests.", force: false, status: 1)
}


// if not quiet, prompt for interactive input
if !options.quiet {
  print("Enter host in 'host=value' format followed by a blank line:")
}

// read input from stdin either from user interactively or from git credentials
while true {
  let optLine = readLine(strippingNewline: true)
  if let line = optLine {
    if line == "" {
      break
    } else {
      console.write("Input line: \(line)", to: .error)
      let parts = line.components(separatedBy: "=")
      if parts.count == 2 {
        main.params[parts[0]] = parts[1]
      }
    }
  }
}


// verify we have a host param
guard let host = main.params["host"] else {
  // didn't find a 'host' key, handle error
  exitOnError(msg: "Invalid input: missing host value", force: false, status: 1)
  exit(1)
}

// get a valid token either from env or call to op
guard op.getToken(options.domain) else {
  exitOnError(msg: "Unable to get session token", force: false, status: 2)
  exit(2)
}

// get item json
var optItem = op.getItem(query: host)
guard let item = optItem else {
  exitOnError(msg: "Error getting item", force: false, status: 1)
  exit(2)
}


// get struct from json
let optResult = op.parseItem(data: item)

// get user and pass from results and print to stdout
if let result = optResult {
  var user = "", pass = ""
  if (result.details.fields.count > 0) {
    for field in result.details.fields {
      if field.designation == "username" {
        user = field.value
      } else if field.designation == "password" {
        pass = field.value
      }
    }
  } else {
    exitOnError(msg: "No fields in query response", force: false, status: 1)
  }
  
  print("username=\(user)\npassword=\(pass)")
} else {
  exitOnError(msg: "No result from get item", force: false, status: 1)
}

exit(0)
