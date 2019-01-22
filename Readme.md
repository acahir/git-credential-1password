# git-credential-1password

Git credential.helper to use the 1Password command line utility to authenticate git
commands. 

### How it works

Git passes in parameters on stdin, and this utility returns a username and 
password on stdout if found. See the references for full details.


### Status

Currently only works with existing, non-expired tokens in the env. Otherwise when 
prompted for the password to sign into 1Password, the following error occurs:
```[LOG] 2019/01/22 06:46:56 (ERROR) inappropriate ioctl for device```

To work around this, script currently includes a flag (requireEvnTokens) that exits
if a valid token isn't found.


### Installation & Usage

The current working version is the python script.

1. [Install](https://support.1password.com/command-line-getting-started/) the 1Password command line tool.
2. Download the script and save it as an executable file somewhere in the PATH. On macOS, ```/usr/local/bin``` would be a good choice.
3. To test the script, you can run it interactively from the command line.
    1. Launch the script: ````/path/to/git-credential-1password --domain=<your domain> get```
    2. You will be prompted to enter the "host" to search for, in the format 
```host=example.com```. This is actually the name of an item in 1Password, such 
as "github.com". You can search for anything as a test, but git will use the host of the remote git service as the search value.
    3. Enter a blank line after you have entered the host.
    4. If you have a valid token, that's it. Otherwise if you have not flagged tokens as required, you will be prompted to enter your password.
4. Configure git to use the script. The domain option defaults to my.1password.com, which 
is the correct setting for individual accounts. If you have a team or business account, you
need to use a different domain.
  ```git config --global credential.helper '1password -q --domain=<domain>'```


Note: it has only been tested on macos, but should work on linux. It is unlikely to 
work on Windows.


### References
1. [Git Credential Storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)
2. [1Password Command Line Utility](https://support.1password.com/command-line-getting-started/)