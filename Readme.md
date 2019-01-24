# git-credential-1password

Git credential.helper written in python to use the 1Password command line utility to authenticate git commands.

Repo also includes a development version written in swift that is currently in testing.


### How it works

Git passes in parameters on stdin, and this utility returns a username and 
password on stdout if found in 1Password. See the [references](https://github.com/acahir/git-credential-1password#references) for full details.


### Status

The python script is functional with good error handling and can be considered ready for use. It currently only works with existing, non-expired 1Password session tokens stored in the shell env, with a flag (-t) to enforce this behavior.


The swift script is now feature equivalent with the python script. It can be compiled into a binary or installed as a swift script. After downloading or 
cloning the project, b



### Installation & Usage

1. First install the [1Password command line utility](https://support.1password.com/command-line-getting-started/).
2. Download or clone this project to your computer.
3. Decide if you want to use the python script, swift script, or swift binary and use the options below to find the correct file:
    - Python: locate the file git-credential-1password in the python directory of the downloaded project
    - Swift: First open the xcode project and build the release scheme.
    - Swift script: The swift script is located at project/swift/git-credential-1password/git-credential-1password.swift
    - Swift binary: Control-click on git-credential-1password under Products in the left sidebar of Xcode and choose "Show in Finder"
4. Move your chosen script to somewhere in your path and name it "git-credential-1password". A good choice would be  ```/usr/local/bin/```
    - Note: only the swift script should need renaming.
5. Configure git to use the script with the command: ```git config --global credential.helper '1password -t -q --domain=<domain>'``` The domain option defaults to my.1password.com if not included, which is the correct setting for individual accounts. If you have a team or business account, you need to use a different domain.
  ```git config --global credential.helper '1password -t -q --domain=<domain>'```


#### Testing

To test the script, you can run it interactively from the command line.

1. Launch the script: ```/path/to/git-credential-1password --domain=<your domain> get```
2. You will be prompted to enter the "host" to search for, in the format 
```host=example.com```. This is actually the name of an item in 1Password, such 
as "github.com". You can search for anything as a test, but git will use the host of the remote git service as the passed in value.
3. Enter a blank line after you have entered the host.
4. If you have a valid token, that's it. Otherwise if you have not flagged tokens as required, you will be prompted to enter your password.

Note: it has only been tested on macos, but should work on linux. It is unlikely to work on Windows from my understanding of python on that platform.

### Known Issues

#### 1Password Session Signin

Both scripts support creating a 1Password session via signin interactively during execution if no valid token is found (either missing or expired). However, currently this doesn't work for either script for different reasons:

##### Python

When prompted for the password to sign into 1Password, the following error occurs:

```[LOG] 2019/01/22 06:46:56 (ERROR) inappropriate ioctl for device```

To work around this, script currently includes a flag (requireEvnTokens) that exits if a valid token isn't found.

##### swift

The swift script has a problem at the same step of the process, but for different reasons. When 1Password prompts the user for their password to create a session, the input is echoed in the terminal, unacceptably exposing the password. 

The swift script uses the same workaround, only relying on existing, valid tokens for 1Password.


### Command Line Usage

The command line usage output which incliudes full options definitions.

<pre>
usage: git-credential-1password [-dhv | --domain=my.1password.com 
                 --help | --verbose ] get

  Utility to automate logging into git using 1Password command line utility.
  Git passes in parameters on stdin, and this utility returns a username and 
  password on stdout if found. See Ref [1] for full details.
  
  Before attempting to sign into 1Password, will check for existing token in 
  the current environment variables and will attempt to use it.
  
  To configure git to use this helper, run the following command:
  
    git config --global credential.helper '1password -q --domain=<domain>'
  
  where domain is the correct domain for your 1Password account.
  
  
  Options
    -d, --domain   the domain (or subdomain) to sign into. Defaults to 'my'
    -h, --help     prints this message
    -q, --quiet    suppresses prompts for input on stdin. Should be used when
                   configured as git credential.helper
    -t, --token    require a 1Password session token in the env variables. 
                   Currently this is required to work when configured as a 
                   git credentials helper.
    -v, --verbose  prints out verbose (debug) messages
    note: -v should only be used while testing as stand-alone script
    
    returns  0  if item exists
</pre>



### References

1. [Git Credential Storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)
2. [1Password Command Line Utility](https://support.1password.com/command-line-getting-started/)


### Licence

Covered by the MIT License
