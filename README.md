# browserstack-local-ruby

[![Build Status](https://travis-ci.org/browserstack/browserstack-local-ruby.svg?branch=master)](https://travis-ci.org/browserstack/browserstack-local-ruby)

## Installation:

```
gem install browserstack-local
```

## Example:

```
require 'browserstack-local'

#creates an instance of Local
bs_local = BrowserStack::Local.new

#arguments for Local instance
bs_local_args = {}

#replace BROWSERSTACK_ACCESS_KEY with your key. 
#you can also use environment variables.
bs_local_args['key'] = "BROWSERSTACK_ACCESS_KEY"

#stops the Local instance with the required options
bs_local.start(bs_local_args)

#checks if Local instance is running
if (bs_local.isRunning)
  #stop the Local instance
  bs_local.stop
end

```

## Additional Arguments

Apart from the key all other arguments are optional. To specify these arguments add them to the inout hash for the BrowserStack::Local constructor.

#### Verbose Logging
To enable verbose logging - 
```
bs_local_args['v'] = "true"
```

#### Folder Testing
To enable folder testing - 
```
bs_local_args['v'] = "true"
```

#### Hosts
To specify hosts and ports for Local testing for eg. localhost,3000 -


#### Force Start 
To kill other running Browserstack Local instances - 

#### Only Automate
To only enable local testing for automate - 

### Proxy
To use a proxy for local testing -  


### Local Identifier
If doing simultaneous multiple local testing connections, set this uniquely for different processes - 

### Hosts

To restrict local testing access to specified local servers and/or folder


### Binary Path
Path to specify local Binary path 

### Logfile 
To specify the path to file where the logs will be saved - 

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
