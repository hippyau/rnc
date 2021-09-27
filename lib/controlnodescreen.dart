import 'dart:async';
//import 'dart:convert';
//import 'package:flutter_colorpicker/flutter_colorpicker.dart';
//import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
//import 'package:prompt_dialog/prompt_dialog.dart';
import 'package:segment_display/segment_display.dart';

import 'nodes.dart';
import 'stringclean.dart';

// configuration screen for a node
class ControlScreen extends StatefulWidget {
  final String ipaddress;

  const ControlScreen({Key? key, required this.ipaddress}) : super(key: key);
  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  String now = "";
  Timer? everySecond;

  @override
  void initState() {
    // start the ArtNet TC receiver
    nodes.rxArtnetTimecode();

    // sets first value
    now = DateTime.now().second.toString();

    // defines a timer
    everySecond = Timer.periodic(Duration(milliseconds: 33), (Timer t) {
      setState(() {
        now = DateTime.now().second.toString();
      });
    });

    super.initState();
  }

  // store the changed setting in memory
  // still relies on user to configure the device
  void _setNewValue(String filename, String setting, String value) {
    print("set new value: Setting $setting = $value in $filename");
    nodes.foundDevices[widget.ipaddress].configChanged[filename] = true;
    // import for JSON formating, parse text to numbers if they are numeric
    if (isNumeric(value)) {
      if (value.contains(".")) {
        nodes.foundDevices[widget.ipaddress].configData[filename][setting] =
            double.parse(value);
      } else {
        nodes.foundDevices[widget.ipaddress].configData[filename][setting] =
            int.parse(value);
      }
    } else
      nodes.foundDevices[widget.ipaddress].configData[filename][setting] =
          value;
    setState(() {}); // refresh the display
  }

  // return an editable control of realtime settings
  List<Widget> controlType(String name) {
    List<Widget> wlist = [];

    // wlist.add(TextButton(
    //     onPressed: () {
    //       realtimeUDP(widget.ipaddress, 10501, "?list#", true);
    //     },
    //     child: Text("Fire List")));

    wlist.add(Center(
        child: Container(
      margin: const EdgeInsets.all(10.0),
      color: Colors.black,
      width: 400.0,
      height: 96.0,
      child: Center(
          child: SevenSegmentDisplay(
              size: 4.0,
              value: nodes.foundDevices[widget.ipaddress].timeCodeString)),
    )));

    wlist.add(Center(
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      IconButton(
          onPressed: () {
            realtimeUDP(widget.ipaddress, 21571, "ltc!start", false);
          },
          icon: Icon(Icons.play_arrow),
          iconSize: 48),
      IconButton(
          onPressed: () {
            realtimeUDP(widget.ipaddress, 21571, "ltc!stop", false);
          },
          icon: Icon(Icons.stop),
          iconSize: 48),
    ])));

    // wlist.add(IconButton(
    //   onPressed: () {
    //     realtimeUDP(widget.ipaddress, 21571, "ltc!stop", false);
    //   },
    //   icon: Icon(Icons.stop),
    // ));

    return wlist;
  }

  List<Widget> _buildControlList() {
    List<Widget> llist = [];

    // determined device type
    NodeRecord nodeType = nodes.foundDevices[widget.ipaddress];

    if (nodeType.type.toUpperCase().contains("LTC")) {
      // present LTC controls
      llist.add(Card(
        child: ExpansionTile(
          title: Text(
            "LTC Controls",
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
          ),

          children: controlType("A Slider?"),

          //trailing: _dropOrSave("/json/" + k),

          onExpansionChanged: (value) {
            if (value == true) {
              //    getJSONData(widget.ipaddress, "/json/" + k);
              // send a command?
            }
          },
        ),
      ));
    }

    // No realtime controls available
    if (llist.isEmpty) llist.add(Text("No Realtime Settings Available"));
    return llist;
  }

  String _oldTC = "00:00:00:00";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.ipaddress),
          actions: [
            IconButton(
                onPressed: () {
                  if (nodes.foundDevices[widget.ipaddress].timeCodeString !=
                      _oldTC) {
                    _oldTC =
                        nodes.foundDevices[widget.ipaddress].timeCodeString;
                    setState(() {});
                  }
                },
                icon: Icon(Icons.refresh))
          ],
        ),
        body: ListView(children: _buildControlList()));
  }
}
