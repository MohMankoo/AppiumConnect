# AppiumConnect
AppiumConnect simplifies the proccess of creating connecting mobile devices to SeleniumGrid through Appium.  AppiumConnect
will scan connected usb devices for Android or iOS phones and tablets and automatically create the necessary node configs
to register with the grid.

#Install
If on mac use libimobile `brew install libimobiledevice`
AppiumConnect is available to install from RubyGems.
```ruby
gem install appium_connect
```
This will add an executable that can be run from command line
```
AppiumConnect
```

For Android devices this will use ADB to detect any devices currently connected and create a seperate AppiumNode for each one. When Appium Connect first starts it will ask for the IP address to use for the hub, and the node.  Once these are provided they will be remembered (saved in config.json) and it can automatically connect.

iOS devices can be detected on Mac by parsing through all connected usb devices. An iOS WebKit Debug Proxy will also be started for each iOS Device connected to the Mac.  This will enable Native App Testing as well as Mobile Web testing.  IOS Webkit Debug proxy must be installed seperatly. Android devices connected to a Mac will not be detected.

Config files will be saved to the users home directory in an AppiumConnect folder.  This will also archive all node config files created as well as output logs from Appium.
***********************************************************


# Orasi Software Inc
Orasi is a software and professional services company focused on software quality testing and management.  As an organization, we are dedicated to best-in-class QA tools, practices and processes. We are agile and drive continuous improvement with our customers and within our own business.

# License
Licensed under [BSD License](/License)
