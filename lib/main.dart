/*
 * Filename: /home/hip/StudioProjects/myapp/lib/main.dart
 * Path: /home/hip/StudioProjects/myapp/lib
 * Created Date: Saturday, August 28th 2021, 5:24:31 pm
 * Author: hippy (dmxout->gmail.com)
 * (c) 2021 - WTFPL 
 */

import 'package:flutter/material.dart';

import 'confignodescreen.dart';
import 'controlnodescreen.dart';
import 'searchingscreen.dart';
import 'nodes.dart';

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
  @override
  void initState() {
    // start searching for devices first thing on app start...
    nodes.findDevices().then((value) {
      setState(() {});
    });
    super.initState();
  }

// draw an entry in the node list
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
// Reboot button
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
// Control button
                          TextButton(
                            child: Text("Control"),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ControlScreen(ipaddress: ipaddress),
                                  ));
                            },
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
                          ),
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
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.settings_applications),
          title: Text("Configuration"),
          actions: [
            IconButton(
                onPressed: () {
                  print("Refresh all");
                  // need to "forget" current node, then start over with...
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
        body:
            // if we are searching for devices, show the search screen ...
            (searchingForDevices == true)
                ? SearchingScreen()
                // ... otherwise, show the node list
                : ListView(
                    children: [
                      // Each node, by IP address
                      for (var i in nodes.foundDevices.keys) nodeCard(i),
                    ],
                  ));
  }
}
