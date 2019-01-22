# git-credential-1password

Git credential.helper to use the 1Password command line utility to authenticate git
commands. 

### How it works

Git passes in parameters on stdin, and this utility returns a username and 
password on stdout if found. See the references for full details


### Status

Currently only works with existing, non-expired tokens in the env. Otherwise when 
prompted for the password to sign into 1Password, the following error occurs:
```[LOG] 2019/01/22 06:46:56 (ERROR) inappropriate ioctl for device```

To work around this, script currently includes a flag (requireEvnTokens) that exits
if a valid token isn't found.


### Installation & Usage

The current working version is the python script.

1. Download the script and save it as an executable file. On macOS, git stores the 
helpers included in the standard distribution in:
	```/Library/Developer/CommandLineTools/usr/libexec/git-core/```
2. Configure git to use the script. The domain option defaults to my.1password.com, which 
is the correct setting for individual accounts. If you have a team or business account, you
need to use a different domain.
  ```git config --global credential.helper '1password -q --domain=<domain>'```


Note: it has only been tested on macos, but should work on linux. It is unlikely to 
work on Windows.


### References
[Git Credential Storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)
[1Password Command Line Utility](https://support.1password.com/command-line-getting-started/)