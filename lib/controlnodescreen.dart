import 'dart:async';

import 'package:flutter/material.dart';

import 'package:segment_display/segment_display.dart';
import 'package:numberpicker/numberpicker.dart';

import 'nodes.dart';

// configuration screen for a node
class ControlScreen extends StatefulWidget {
  final String ipaddress;

  const ControlScreen({Key? key, required this.ipaddress}) : super(key: key);
  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  Timer? frameTimer;
  String timeCodeIn = "--:--:--:--";

// input, not the current received art-net time code
  int _currentHrValue = 0;
  int _currentMnValue = 0;
  int _currentScValue = 0;
  int _currentFrValue = 0;
  String _currentTC = "00:00:00:00";
  String _Direction = "forward";

  @override
  void initState() {
    // start the ArtNet TC receiver
    nodes.rxArtnetTimecode();

    // defines a timer
    frameTimer = Timer.periodic(Duration(milliseconds: 30), (Timer t) {
      setState(() {
        timeCodeIn = nodes.foundDevices[widget.ipaddress]?.timeCodeString;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    frameTimer?.cancel();
    super.dispose();
  }

  // return an editable control of realtime settings
  List<Widget> controlType(String name) {
    List<Widget> wlist = [];

    wlist.add(Center(
        child: Container(
      margin: const EdgeInsets.all(10.0),
      color: Colors.black,
      width: 400.0,
      height: 96.0,
      child: Center(child: SevenSegmentDisplay(size: 6.0, value: timeCodeIn)),
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

            _currentTC = _currentHrValue.toString().padLeft(2, "0") +
                ":" +
                _currentMnValue.toString().padLeft(2, "0") +
                ":" +
                _currentScValue.toString().padLeft(2, "0") +
                ":" +
                _currentFrValue.toString().padLeft(2, "0");
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

// ltc!rate#rr              Sets the rate of the TimeCode. Valid values: 24, 25, 29 and 30.
// Art-Net Time Code Type: 0=24, 1=25, 2=29.97, 3=30

    String tcType = nodes.foundDevices[widget.ipaddress].timeCodeType;

    wlist.add(ListTile(
        title: Text("Rate"),
        subtitle: Text("Rate@FPS"),
        trailing: PopupMenuButton(
          icon: Icon(Icons.settings_display),
          iconSize: 28,
          color: Colors.black,
          onSelected: (value) {
            setState(() {
              if (value != null &&
                  value != tcType &&
                  value.runtimeType == String) {
                nodes.foundDevices[widget.ipaddress].timeCodeType =
                    value.toString();
                String cmd = "ltc!rate#";

                switch (value) {
                  case '0':
                    cmd += "24";
                    break;
                  case '1':
                    cmd += "25";
                    break;
                  case '2':
                    cmd += "29";
                    break;
                  case '3':
                    cmd += "30";
                    break;

                  default:
                    cmd += "30";
                    break;
                }
                // ltc!rate#rr              Sets the rate of the TimeCode. Valid values: 24, 25, 29 and 30.
                realtimeUDP(widget.ipaddress, 21571, cmd, false);
              }
            });
          },
          itemBuilder: (_) => [
            new CheckedPopupMenuItem(
              checked: tcType == '0',
              value: '0',
              child: new Text('24 FPS'),
            ),
            new CheckedPopupMenuItem(
              checked: tcType == '1',
              value: '1',
              child: new Text('25 FPS'),
            ),
            new CheckedPopupMenuItem(
              checked: tcType == '2',
              value: '2',
              child: new Text('29.97 FPS'),
            ),
            new CheckedPopupMenuItem(
              checked: tcType == '3',
              value: '3',
              child: new Text('30 FPS'),
            ),
          ],
        )));

    _currentTC = _currentHrValue.toString().padLeft(2, "0") +
        ":" +
        _currentMnValue.toString().padLeft(2, "0") +
        ":" +
        _currentScValue.toString().padLeft(2, "0") +
        ":" +
        _currentFrValue.toString().padLeft(2, "0");
    wlist.add(Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          NumberPicker(
            textMapper: (value) {
              String result = "";
              result = value.padLeft(2, '0');
              return result;
            },
            value: _currentHrValue,
            minValue: 0,
            maxValue: 23,
            onChanged: (value) => setState(() => _currentHrValue = value),
            itemWidth: 48,
          ),
          Text(":"),
          NumberPicker(
            textMapper: (value) {
              String result = "";
              result = value.padLeft(2, '0');
              return result;
            },
            value: _currentMnValue,
            minValue: 0,
            maxValue: 59,
            itemWidth: 48,
            onChanged: (value) => setState(() => _currentMnValue = value),
          ),
          Text(":"),
          NumberPicker(
            textMapper: (value) {
              String result = "";
              result = value.padLeft(2, '0');
              return result;
            },
            value: _currentScValue,
            minValue: 0,
            maxValue: 59,
            itemWidth: 48,
            onChanged: (value) => setState(() => _currentScValue = value),
          ),
          Text(":"),
          NumberPicker(
            textMapper: (value) {
              String result = "";
              result = value.padLeft(2, '0');
              return result;
            },
            value: _currentFrValue,
            minValue: 0,
            maxValue: 29,
            itemWidth: 48,
            onChanged: (value) => setState(() => _currentFrValue = value),
          ),
          IconButton(
              onPressed: () {
                realtimeUDP(
                    widget.ipaddress, 21571, "ltc!start#" + _currentTC, false);
              },
              icon: Icon(Icons.align_horizontal_left_sharp)),
          IconButton(
              onPressed: () {
                realtimeUDP(
                    widget.ipaddress, 21571, "ltc!stop#" + _currentTC, false);
              },
              icon: Icon(Icons.align_horizontal_right_sharp)),
          IconButton(
              onPressed: () {
                realtimeUDP(
                    widget.ipaddress, 21571, "ltc!start@" + _currentTC, false);
              },
              icon: Icon(Icons.alternate_email)),
        ],
      ),
    ));

    wlist.add(ListTile(
        title: Text("Direction"),
        subtitle: Text("$_Direction"),
        trailing: Switch(
            value: (_Direction.contains("forward")),
            onChanged: (value) {
              this.setState(() {
                if (value == false) {
                  _Direction = "backward";
                } else {
                  _Direction = "forward";
                }
                realtimeUDP(widget.ipaddress, 21571,
                    "ltc!direction#" + _Direction, false);
              });
            })));

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
