/*
 * Filename: /home/hip/StudioProjects/myapp/lib/main.dart
 * Path: /home/hip/StudioProjects/myapp/lib
 * Created Date: Saturday, August 28th 2021, 5:24:31 pm
 * Author: hippy (dmxout->gmail.com)
 * (c) 2021 - WTFPL 
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'confignodescreen.dart';
import 'nodes.dart';

// import 'dart:io';
// import 'package:udp/udp.dart';

/* app */
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Node Configuration Tool',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.lightBlue,
      ),
      home: RCMConfigApp(),
    );
  }
}

class RCMConfigApp extends StatefulWidget {
  @override
  _RCMConfigAppState createState() {
    return _RCMConfigAppState();
  }
}

// first page
class _RCMConfigAppState extends State<RCMConfigApp> {
//

  @override
  void initState() {
    nodes.findDevices().then((value) {
      setState(() {});
    });
    super.initState();
  }

// return a single nodeCard for a node with given ipaddress
  Widget nodeCard(String ipaddress) {
    NodeRecord node = nodes.foundDevices[ipaddress];
    String nodeImg = "graphics/xlr5.jpg";
    if (node.type.contains("LTC")) {
      nodeImg = "graphics/ltc3.jpg";
    }

    return Card(
      child: Container(
        height: 100,
        color: Colors.black,
        child: Row(
          children: [
            Center(
              child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Image(image: AssetImage(nodeImg))),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.topLeft,
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: ListTile(
                        title: Text(node.name),
                        subtitle: Text(node.type),
                        trailing: Text(ipaddress),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
// Identify button
                          TextButton(
                            onPressed: () => nodes.rebootDevice(ipaddress),
                            child: Text("Reboot"),
                          ),
                          SizedBox(
                            width: 8,
                          ),

                          // Identify button
                          TextButton(
                            onPressed: () => showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: const Text('Identify Device'),
                                content: const Text(
                                    'Display or LEDs should now be flashing on the selected device.'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'Done'),
                                    child: const Text('Done'),
                                  ),
                                ],
                              ),
                            ),
                            child: Text("Identify"),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          // Configure button
                          TextButton(
                            child: Text("Configure"),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ConfigScreen(ipaddress: ipaddress),
                                  ));
                            },
                          ),
                          SizedBox(
                            width: 8,
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              flex: 8,
            ),
          ],
        ),
      ),
      elevation: 8,
      margin: EdgeInsets.all(10),
    );
  }

// application front page
// list of discovered nodes (nodeCards)
  Widget build(BuildContext context) {
    //  nodes.findDevices().then((value) {});

    return Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.settings_applications),
          title: Text("Configuration"),
          actions: [
            IconButton(
                onPressed: () {
                  print("Refresh all");
                  // "forget" current node, then start over with...
                  //         nodes.removeDevice(widget.ipaddress);
                  nodes.findDevices();
                  setState(() {});

                  nodes.findDevices().then((value) {
                    setState(() {});
                  });
                },
                icon: Icon(Icons.refresh))
          ],
        ),
        body: (searchingForDevices == true)
            ? SearchingScreen()
            : ListView(
                children: [
                  // draw a card for all nodes found, by ipaddress
                  for (var i in nodes.foundDevices.keys) nodeCard(i),
                ],
              ));
  }
}

// searching for mDNS devices....
class SearchingScreen extends StatefulWidget {
  const SearchingScreen({Key? key}) : super(key: key);

  @override
  _SearchingScreenState createState() => _SearchingScreenState();
}

class _SearchingScreenState extends State<SearchingScreen> {
  String ipsString = "";
  @override
  Widget build(BuildContext context) {
    String count = nodes.foundDevices.length.toString();

    var ips = printIps().then((value) {
      ipsString = value;
      setState(() {});
    });

    return Container(
        height: double.infinity,
        width: double.infinity,
        //color: Colors.purple,
        alignment: Alignment.center,
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(16),
        color: Colors.black.withOpacity(0.8),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _getLoadingIndicator(),
              _getHeading(),
              _getText(nodes.foundDevices.length > 0
                  ? 'Found $count device(s)'
                  : 'Nothing yet…'),
              _getIPs(),
            ]));
  }

  Widget _getLoadingIndicator() {
    return Padding(
        child: Container(
            child: CircularProgressIndicator(strokeWidth: 3),
            width: 64,
            height: 64),
        padding: EdgeInsets.only(bottom: 16));
  }

  Widget _getHeading() {
    return Padding(
        child: Text(
          '\nSearching, please wait…\n',
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        padding: EdgeInsets.only(bottom: 4));
  }

  Widget _getText(String displayedText) {
    return Text(
      displayedText,
      style: TextStyle(color: Colors.white, fontSize: 14),
      textAlign: TextAlign.center,
    );
  }

  Widget _getIPs() {
    return Text(
      "\n\n" + ipsString,
      style: TextStyle(color: Colors.grey, fontSize: 12),
      textAlign: TextAlign.center,
    );
  }
}
