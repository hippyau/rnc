# RNC - Remote Node Configuration

## Application
An application for configuration of remote nodes running the firmware produced by [Arjan van Vught](https://github.com/vanvught) from his awesome project.  He has written an impressive array of very powerful and rock solid, baremetal firmwares for:

*  The OrangePi Zero (Allwinner H3) low-cost devices.
*  The GigaDevice GD32Fx07 MCU's.

OrangePi Bare-Metal Appliances such as:  
[DMX512 / RDM / Art-Net 4 / sACN E1.31 / OSC / SMPTE / Pixel controller / RGB Panel / RDMNet](https://github.com/vanvught/rpidmx512#readme).

RNC is a configuration tool for those devices. It should work across Android/IOS mobiles, and Linux/Mac/Windows desktops, to configure nodes over the network.  It is based on [Flutter](https://flutter.dev) SDK and written in Dart.

![image](https://github.com/hippyau/RNC/blob/main/LastestDemo.gif?raw=true)

![image](https://github.com/hippyau/RNC/blob/main/gd32f107r?raw=true)

## Binaries 

Binary alpha build releases are availabile for Android, GNU/Linux, MacOS & Windows. 

https://github.com/hippyau/RNC/tags

These are alpha, so the working prototype.... no signing or anything yet.

## How To Use

Currently working with latest development branch of Arjan van Vaught's awesome array of [OPi DMX RDM SACN ARTNET SMPTE LTC MIDI NTP GPS LED](https://github.com/vanvught/rpidmx512#readme) firmware appliances, this application can detect devices via mDNS and will retrieve and store configuration settings via Wifi or Ethernet. 

Be on same Local Area Network (LAN Ethernet or WiFi) as your Orange Pi (et al) devices which support AvV's JSON Configuration Framework.   

Then run the app.  

It should detect nodes (devices) on the via mDNS (Bonjour), and you should be able to configure the listed devices.

#### REMEBER TO SAVE & REBOOT

If you change something, the tab changes from a "v" icon to "Save".  Click Save.  You should reboot for changes to take effect.
If you close then open the tab again, it reloads the stored settings for that tab from the device.
 


## Getting Started Compiling & Developing

A few tips / resources to get you started if this is your first Flutter project:

- [Installing Flutter](https://flutter.dev/docs/get-started/install) - This is a really good guide, follow step by step, have working environment in less than half an hour.

```flutter doctor``` is very useful tool, but you don't need everything depending on what your are doing....

* To build the MacOS Desktop app or IOS app, you'll need a running MacOS instance with xcode installed.
* To build Windows Desktop app, you'll need to be on Windows and have at least Community Visual Studio 2019 with C++ 
* To build GNU/Linux Desktop, you'll need to be on GNU/Linux.
* To build Android APK's, you'll need Android Studio installed on any platform.

When developing with Android, using `adb connect ip.of.my.phone` after enabling Development Options for Android phone is a quick way to get connected to real hardware.

Microsoft VS Code is a great IDE for developing with Flutter (IMHO).  Install the Flutter extention, it just makes life so much easier.  You can select device in bottom left corner, and F5 to compile/debug... Almost turn-key.


- Clone this repo into something like `~/development/rnc` and try ```flutter build windows``` for example.

Note:  you may need to rename the folder from `RNC` to `rnc` if you have some weird build issued.

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

