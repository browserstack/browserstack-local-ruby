# browserstack-local-ruby

[![Build Status](https://travis-ci.org/browserstack/browserstack-local-ruby.svg?branch=master)](https://travis-ci.org/browserstack/browserstack-local-ruby)

## Installation:

```
gem install browserstack-local
```

## Examples:

```
require 'browserstack-local'

#creates an instance of Local
bs_local = BrowserStack::Local.new

#options for Local instance
bs_local_options = {}

#replace BROWSERSTACK_ACCESS_KEY with your key. 
#you can also use environment variables.
bs_local_options['key'] = "BROWSERSTACK_ACCESS_KEY"

#stops the Local instance with the required options
bs_local.start(bs_local_options)

#checks if Local instance is running
if (bs_local.isRunning)
  #stop the Local instance
  bs_local.stop
end

```

## Additional Options

To specify other options, add it to the options hash while creating a new instance

### Verbose Logging 

To enable verbose logging - 

```
bs_local_options['v'] = "true"
```

### Folder Testing
```
bs_local_options['v'] = "true"
```


### Force 
* `force`: Kill other running Browserstack Local

```
bs_local_options['v'] = "true"
```


### Proxy 
* `proxyHost`: Hostname/IP of proxy, remaining proxy options are ignored if this option is absent
* `proxyPort`: Port for the proxy, defaults to 3128 when -proxyHost is used
* `proxyUser`: Username for connecting to proxy (Basic Auth Only)
* `proxyPass`: Password for USERNAME, will be ignored if USERNAME is empty or not specified


### Local Identifier

### Hosts

### Binary Path

### Logfile 

* `key`: BrowserStack Access Key
* `v`: Provides verbose logging
* `f`: If you want to test local folder rather internal server, provide path to folder as value of this option
* `force`: Kill other running Browserstack Local
* `only`: Restricts Local Testing access to specified local servers and/or folders
* `forcelocal`: Route all traffic via local machine
* `onlyAutomate`: Disable Live Testing and Screenshots, just test Automate

* `localIdentifier`: If doing simultaneous multiple local testing connections, set this uniquely for different processes
* `hosts`: List of hosts and ports where Local must be enabled for eg. localhost,3000,1,localhost,3001,0
* `logfile`: Path to file where Local logs be saved to
* `binarypath`: Optional path to Local binary


## Contribute

### Build Instructions

To build gem, `rake build`.

To run the test suite run, `rake test`.

### Reporting bugs

You can submit bug reports either in the Github issue tracker.

Before submitting an issue please check if there is already an existing issue. If there is, please add any additional information give it a "+1" in the comments.

When submitting an issue please describe the issue clearly, including how to reproduce the bug, which situations it appears in, what you expect to happen, what actually happens, and what platform (operating system and version) you are using.

### Pull Requests

We love pull requests! We are very happy to work with you to get your changes merged in, however please keep the following in mind.

* Adhere to the coding conventions you see in the surrounding code.
* Include tests, and make sure all tests pass.
* Before submitting a pull-request, clean up the history by going over your commits and squashing together minor changes and fixes into the corresponding commits. You can do this using the interactive rebase command.