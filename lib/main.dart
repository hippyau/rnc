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
        primarySwatch: Colors.blue,
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
    super.initState();
  }

// return a single nodeCard for a node with given ipaddress
  Widget nodeCard(String ipaddress) {
    NodeRecord node = nodes.foundDevices[ipaddress];
    return Card(
      child: Container(
        height: 100,
        color: Colors.white,
        child: Row(
          children: [
            Center(
              child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Image(image: AssetImage('graphics/xlr5.jpg'))),
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
    return Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.settings_applications),
          title: Text("Remote Node Configuration"),
        ),
        body: ListView(
          children: [
            // draw a card for all nodes found, by ipaddress
            for (var i in nodes.foundDevices.keys) nodeCard(i),
          ],
        ));
  }
}
