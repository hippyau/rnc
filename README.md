# RNC - Remote Node Configuration


![image](https://github.com/hippyau/RNC/blob/main/LastestDemo.gif?raw=true)


# What is it??
An application for configuration of remote devices such the firmwares produced by Arjan Van Vaught in his project [DMX512 / RDM / Art-Net 4 / sACN E1.31 / OSC / SMPTE / Pixel controller / RDMNet LLRP Only nodes](https://github.com/vanvught/rpidmx512).

The app should work across Android/IOS mobiles, and Linux/Mac/Windows desktops.  It is based on [Flutter](https://flutter.dev) SDK and written in Dart.

## Binaries 

Binary alpha build releases are availabile for MacOS, GNU/Linux, Windows. 
https://github.com/hippyau/RNC/tags

These are alpha, so the working prototype....

## How To Use

Be on same Local Area Network (LAN Ethernet or WiFi) as your Orange Pi (et al) devices which support AvV's JSON Configuration Framework.   

Then run the app.  

It should detect nodes (devices) on the via mDNS (Bonjour), and you should be able to configure the listed devices.

#### REMEBER TO SAVE & REBOOT

If you change something, the tab changes from a "v" icon to "Save".  Click Save.  You should reboot for changes to take effect.
If you close then open the tab again, it reloads the stored settings for that tab from the device.
 

Working with latest development branch, can detect devices via mDNS and retrieve and store .txt files via the HTTP server.


...


## Getting Started Developing

A few resources to get you started if this is your first Flutter project:

- [Installing Flutter](https://flutter.dev/docs/get-started/install)

- Clone the git repo and try flutter build windows

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
