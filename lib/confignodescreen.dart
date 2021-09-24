import 'dart:async';
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:prompt_dialog/prompt_dialog.dart';

import 'nodes.dart';
import 'stringclean.dart';

// configuration screen for a node
class ConfigScreen extends StatefulWidget {
  final String ipaddress;

  const ConfigScreen({Key? key, required this.ipaddress}) : super(key: key);
  @override
  _ConfigScreenState createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  // retrieve JSON from a node at ipaddress, looking for filename
  // special treatment for /json/directory
  // decodes it into the nodes.foundDevices[ipaddress].configData[filename] map.
  String getJSONData(String ipaddress, String filename) {
    var a = Uri.http(ipaddress, filename);
    try {
      var response = http.get(a, headers: {"Accept": "application/json"});

      response.then((value) {
        //print(value.body);

        this.setState(() {
          var fileName = (filename.split('/').last);

          Map<String, dynamic> decode = json.decode(value.body);
          print("GET " + filename + ": " + decode.toString());

          if (fileName.contains(".txt")) {
            nodes.foundDevices[ipaddress].configData[filename] =
                decode[fileName];
          } else if (fileName.contains("directory")) {
            nodes.foundDevices[ipaddress].configData[filename] =
                decode["files"];
          } else {
            nodes.foundDevices[ipaddress].configData[filename] = decode;
          }
          nodes.foundDevices[widget.ipaddress].configChanged[filename] = false;
        });
      });
    } catch (e) {
      print("Error fetching $filename from $ipaddress : $e");
      return "Error!";
    }
    return "Success!";
  }

  // post a JSON file
  // save the memory of the edited txt file back to the device
  Future<http.Response> _setJSONData(String ipaddress, String filename) async {
    var fileName = (filename.split('/').last);

    var postbody = "{\"$fileName\": " +
        jsonEncode(nodes.foundDevices[ipaddress].configData[filename]) +
        "}";

    String addr = "http://" + ipaddress + "/json";
    print("Post to '$addr': " + postbody);

    var res;
    res = await http.post(
      Uri.parse(addr),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: postbody,
    );
    print("Post Return: " + res.body);
    if (!res.body.contains("OK")) {
      // failed
      print("Post Failed!");
    }
    return res;
  }

  @override
  void initState() {
    // attempt to get the directory json file for the device
    this.getJSONData(widget.ipaddress, "/json/directory");
    super.initState();
  }

  // store the changed setting in memory
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

  // return an editable list of all the available settings in the
  // given configuration filename
  List<Widget> configList(BuildContext context, String filename) {
    List<Widget> wlist = [];

    var configMap = nodes.foundDevices[widget.ipaddress].configData[filename];
    //configMap.forEach((k, v) => print('$k : $v'));

    configMap?.forEach((k, v) {
      // decide what tile to add, based on the field type (k)
      var res;

      // boolean "switch"
      if (k.contains("use_") ||
          k.contains("disable_") ||
          k.contains("enable") ||
          ((k.contains("auto_start") || k.contains("show_systime")) &&
              filename.contains("ltc"))) {
        wlist.add(ListTile(
          title: Text(prettyConfigText(k)),
          trailing: Switch(
            value: (v != 0),
            onChanged: (value) {
              setState(() {
                if (value) {
                  _setNewValue(filename, k, "1");
                } else {
                  _setNewValue(filename, k, "0");
                }
              });
            },
          ),
        ));
      }

      // Colour picker
      else if (k.contains("colour")) {
        final Color hcolor = HexColor.fromHex(v.toString());
        var outclr = null;
        wlist.add(ListTile(
            title: Text(prettyConfigText(k)),
            subtitle: Text("$v"),
            trailing: Padding(
                padding: EdgeInsets.all(24.0),
                child: DecoratedBox(
                    decoration: BoxDecoration(
                  // shape: BoxShape.circle,
                  border: Border.all(width: 16.0, color: hcolor),
                ))),
            onTap: () async {
              res = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    titlePadding: const EdgeInsets.all(0.0),
                    contentPadding: const EdgeInsets.all(0.0),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: hcolor,
                        onColorChanged: (changeColor) {
                          outclr = changeColor.toHex();
                        },
                        colorPickerWidth: 300.0,
                        pickerAreaHeightPercent: 0.7,
                        enableAlpha: false,
                        displayThumbColor: true,
                        showLabel: true,
                        paletteType: PaletteType.hsv,
                        pickerAreaBorderRadius: const BorderRadius.only(
                          topLeft: const Radius.circular(2.0),
                          topRight: const Radius.circular(2.0),
                        ),
                      ),
                    ),
                  );
                },
              );

              if (outclr != null) {
                var newString = outclr.substring(outclr.length - 6);
                _setNewValue(filename, k, newString);
                nodes.foundDevices[widget.ipaddress].configChanged[filename] =
                    true;
                this.setState(() {});
              }
            }));
      }

      // direction selection
      else if (k.contains("direction")) {
        String direction = v;
        wlist.add(ListTile(
            title: Text(prettyConfigText(k)),
            subtitle: Text("$v"),
            trailing: Switch(
                value: (direction.contains("output")),
                onChanged: (value) {
                  this.setState(() {
                    if (value == false) {
                      _setNewValue(filename, k, "input");
                    } else {
                      _setNewValue(filename, k, "output");
                    }
                  });
                })));
      }

      // ArtNet4 protocol selection
      else if (k.contains("protocol") && filename.contains("artnet")) {
        String direction = v;
        wlist.add(ListTile(
            title: Text(prettyConfigText(k)),
            subtitle: Text(prettyConfigText(v)),
            trailing: Switch(
                value: (direction.contains("artnet")),
                onChanged: (value) {
                  this.setState(() {
                    if (value == false) {
                      _setNewValue(filename, k, "sacn");
                    } else {
                      _setNewValue(filename, k, "artnet");
                    }
                  });
                })));
      }

      // LTC source selection
      else if (k.contains("source") && filename.contains("ltc")) {
        String _srcname = v;

        wlist.add(ListTile(
            title: Text(prettyConfigText(k)),
            subtitle: Text("$v"),
            trailing: PopupMenuButton(
              icon: Icon(Icons.lock_clock),
              iconSize: 28,
              color: Colors.black,
              onSelected: (value) {
                setState(() {
                  if (value != null &&
                      value != v &&
                      value.runtimeType == String) {
                    _setNewValue(filename, k, value.toString());
                  }
                });
              },
              itemBuilder: (_) => [
                ///  ltc, midi, artnet, tcnet, internal, rtp-midi, systime
                new CheckedPopupMenuItem(
                  checked: _srcname == 'ltc',
                  value: 'ltc',
                  child: new Text('LTC'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'midi',
                  value: 'midi',
                  child: new Text('Midi'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'artnet',
                  value: 'artnet',
                  child: new Text('Art-Net'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'rtp-midi',
                  value: 'rtp-midi',
                  child: new Text('RTP-Midi'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'tcnet',
                  value: 'tcnet',
                  child: new Text('TC-Net'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'internal',
                  value: 'internal',
                  child: new Text('Internal Generator'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'systime',
                  value: 'systime',
                  child: new Text('System Time'),
                ),
              ],
            )));
        if (_srcname != v) {
          _setNewValue(filename, k, _srcname);
        }
      }

      // GPS module selection
      else if (k.contains("module") && filename.contains("gps")) {
        String _srcname = v;

        wlist.add(ListTile(
            title: Text(prettyConfigText(k)),
            subtitle: Text("$v"),
            trailing: PopupMenuButton(
              icon: Icon(Icons.gps_fixed),
              iconSize: 28,
              color: Colors.black,
              onSelected: (value) {
                setState(() {
                  if (value != null &&
                      value != v &&
                      value.runtimeType == String) {
                    _setNewValue(filename, k, value.toString());
                  }
                });
              },
              itemBuilder: (_) => [
                new CheckedPopupMenuItem(
                  checked: _srcname == 'Undefined',
                  value: 'Undefined',
                  child: new Text('None'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'ATGM336H',
                  value: 'ATGM336H',
                  child: new Text('ATGM336H'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'ublox-NEO7',
                  value: 'ublox-NEO7',
                  child: new Text('ublox-NEO7'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'MTK3339',
                  value: 'MTK3339',
                  child: new Text('MTK3339'),
                ),
              ],
            )));
        if (_srcname != v) {
          _setNewValue(filename, k, _srcname);
        }
      }

      // Colon Blink Modes
      else if (k.contains("colon_blink") && filename.contains("display")) {
        String _srcname = v;

        wlist.add(ListTile(
            title: Text(prettyConfigText(k)),
            subtitle: Text(prettyConfigText(v)),
            trailing: PopupMenuButton(
              icon: Icon(Icons.signal_cellular_4_bar_sharp),
              iconSize: 28,
              color: Colors.black,
              onSelected: (value) {
                setState(() {
                  if (value != null &&
                      value != v &&
                      value.runtimeType == String) {
                    _setNewValue(filename, k, value.toString());
                  }
                });
              },
              itemBuilder: (_) => [
                new CheckedPopupMenuItem(
                  checked: _srcname == 'off',
                  value: 'off',
                  child: new Text('Solid'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'down',
                  value: 'down',
                  child: new Text('Fade down'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'up',
                  value: 'up',
                  child: new Text('Fade up'),
                ),
              ],
            )));
        if (_srcname != v) {
          _setNewValue(filename, k, _srcname);
        }
      }

      // max7219 type
      else if (k.contains("max7219_type") && filename.contains("display")) {
        String _srcname = v;

        wlist.add(ListTile(
            title: Text(prettyConfigText(k)),
            subtitle: Text(prettyConfigText(v)),
            trailing: PopupMenuButton(
              icon: Icon(Icons.settings_display),
              iconSize: 28,
              color: Colors.black,
              onSelected: (value) {
                setState(() {
                  if (value != null &&
                      value != v &&
                      value.runtimeType == String) {
                    _setNewValue(filename, k, value.toString());
                  }
                });
              },
              itemBuilder: (_) => [
                new CheckedPopupMenuItem(
                  checked: _srcname == 'matrix',
                  value: 'matrix',
                  child: new Text('Matrix'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == '7segment',
                  value: '7segment',
                  child: new Text('7 Segment'),
                ),
              ],
            )));
        if (_srcname != v) {
          _setNewValue(filename, k, _srcname);
        }
      }

      // ws28xx type
      else if (k.contains("ws28xx_type") && filename.contains("display")) {
        String _srcname = v;

        wlist.add(ListTile(
            title: Text(prettyConfigText(k)),
            subtitle: Text(prettyConfigText(v)),
            trailing: PopupMenuButton(
              icon: Icon(Icons.settings_display),
              iconSize: 28,
              color: Colors.black,
              onSelected: (value) {
                setState(() {
                  if (value != null &&
                      value != v &&
                      value.runtimeType == String) {
                    _setNewValue(filename, k, value.toString());
                  }
                });
              },
              itemBuilder: (_) => [
                new CheckedPopupMenuItem(
                  checked: _srcname == 'matrix',
                  value: 'matrix',
                  child: new Text('Matrix'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == '7segment',
                  value: '7segment',
                  child: new Text('7 Segment'),
                ),
              ],
            )));
        if (_srcname != v) {
          _setNewValue(filename, k, _srcname);
        }
      }

      // LED type
      else if (k.contains("led_type") && filename.contains("display")) {
        String _srcname = v;

        wlist.add(ListTile(
            title: Text(prettyConfigText(k)),
            subtitle: Text(v),
            trailing: PopupMenuButton(
              icon: Icon(Icons.settings_display),
              iconSize: 28,
              color: Colors.black,
              onSelected: (value) {
                setState(() {
                  if (value != null &&
                      value != v &&
                      value.runtimeType == String) {
                    _setNewValue(filename, k, value.toString());
                  }
                });
              },
              itemBuilder: (_) => [
                new CheckedPopupMenuItem(
                  checked: _srcname == 'WS2801',
                  value: 'WS2801',
                  child: new Text('WS2801'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'WS2811',
                  value: 'WS2811',
                  child: new Text('WS2811'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'WS2812',
                  value: 'WS2812',
                  child: new Text('WS2812'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'WS2812B',
                  value: 'WS2812B',
                  child: new Text('WS2811B'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'WS2813',
                  value: 'WS2813',
                  child: new Text('WS2813'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'WS2815',
                  value: 'WS2815',
                  child: new Text('WS2815'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'SK6812',
                  value: 'SK6812',
                  child: new Text('SK6812'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'SK6812W',
                  value: 'SK6812W',
                  child: new Text('SK6812W'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'SK9822',
                  value: 'SK9822',
                  child: new Text('SK9822'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'APA102',
                  value: 'APA102',
                  child: new Text('APA102'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'TLC59711',
                  value: 'TLC59711',
                  child: new Text('TLC59711'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'UCS1903',
                  value: 'UCS1903',
                  child: new Text('UCS1903'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'UCS2903',
                  value: 'UCS2903',
                  child: new Text('UCS2903'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'CS8812',
                  value: 'CS8812',
                  child: new Text('CS8812'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'P9813',
                  value: 'P9813',
                  child: new Text('P9813'),
                )
              ],
            )));
        if (_srcname != v) {
          _setNewValue(filename, k, _srcname);
        }
      }

      // LED RGB mapping
      else if (k.contains("led_rgb_mapping") && filename.contains("display")) {
        String _srcname = v;

        wlist.add(ListTile(
            title: Text(prettyConfigText(k)),
            subtitle: Text(v),
            trailing: PopupMenuButton(
              icon: Icon(Icons.sort),
              iconSize: 28,
              color: Colors.black,
              onSelected: (value) {
                setState(() {
                  if (value != null &&
                      value != v &&
                      value.runtimeType == String) {
                    _setNewValue(filename, k, value.toString());
                  }
                });
              },
              // "RGB", "RBG", "GRB", "GBR", "BRG", "BGR"
              itemBuilder: (_) => [
                new CheckedPopupMenuItem(
                  checked: _srcname == 'RGB',
                  value: 'RGB',
                  child: new Text('RGB'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'RBG',
                  value: 'RBG',
                  child: new Text('RBG'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'GRB',
                  value: 'GRB',
                  child: new Text('GRB'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'GBR',
                  value: 'GBR',
                  child: new Text('GBR'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'BRG',
                  value: 'BRG',
                  child: new Text('BRG'),
                ),
                new CheckedPopupMenuItem(
                  checked: _srcname == 'BGR',
                  value: 'BGR',
                  child: new Text('BGR'),
                ),
              ],
            )));
        if (_srcname != v) {
          _setNewValue(filename, k, _srcname);
        }
      }

      // Intensity sliders
      else if (k.contains("intensity")) {
        var level = 1.0 * v.toInt(); //= v.toInt();
        String strval = level.round().toString();
        var minv = 0.0;
        var maxv = 255.0;
        if (k.contains("max7219")) {
          maxv = 15;
        }

        wlist.add(ListTile(
          title: Text(prettyConfigText(k)),
          subtitle: Slider(
            value: level,
            min: minv,
            max: maxv,
//              divisions: 5,
            label: strval,
            onChanged: (double value) {
              setState(() {
                _setNewValue(filename, k, value.round().toString());
              });
            },
          ),
          trailing: Text("$v"),
        ));
      }

      // Merge mode selection
      else if (k.contains("merge_mode")) {
        String direction = v;
        wlist.add(ListTile(
            title: Text(prettyConfigText(k)),
            subtitle: Text(prettyConfigText(v)),
            trailing: Switch(
                value: (direction.contains("htp")),
                onChanged: (value) {
                  this.setState(() {
                    if (value == false) {
                      _setNewValue(filename, k, "ltp");
                    } else {
                      _setNewValue(filename, k, "htp");
                    }
                  });
                })));
      }
      //
      else {
        // default response is to always ask for text edit
        //
        wlist.add(ListTile(
            title: Text(prettyConfigText(k)),
            subtitle: Text("$v"),
            onTap: () async {
              res = await prompt(
                context,
                title: Text(prettyConfigText(k)),
                initialValue: v.toString(),
                textOK: Text('Set'),
                textCancel: Text('Cancel'),
                hintText: k,
                // keyboardType: TextInputType.number,
                // TODO: Only numbers can be entered
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return null; //'Please enter a value';
                  }
                  return value;
                },
                minLines: 1,
                maxLines: 1,
                autoFocus: true,
                barrierDismissible: true,
              );

              if (res != null) {
                _setNewValue(filename, k, res);
                nodes.foundDevices[widget.ipaddress].configChanged[filename] =
                    true;
                this.setState(() {});
              }
            }));
      }
    });

    return wlist;
  }

// should return a sve button or a "V" button
  Widget _dropOrSave(String filename) {
    if (filename.contains(".txt") &&
        nodes.foundDevices[widget.ipaddress].configChanged[filename] == true) {
      return TextButton(
        child: Text("Save"),
        onPressed: () {
          print("Post $filename to the device...");
          nodes.foundDevices[widget.ipaddress].configChanged[filename] = false;

          // SUBMIT THE CHANGES
          _setJSONData(widget.ipaddress, filename);

          // Read back the configuration
          //    getJSONData(widget.ipaddress, filename);
          this.setState(() {});
        },
      );
    } else {
      return Icon(Icons.arrow_drop_down);
    }
  }

  List<Widget> _buildDirectoryList() {
    List<Widget> llist = [];

    // read the node directory (locally cached)
    Map? dirMap =
        nodes.foundDevices[widget.ipaddress].configData["/json/directory"];

    // present a section for all directory entries... (if any)
    dirMap?.forEach((k, v) {
      llist.add(Card(
        child: ExpansionTile(
          title: Text(
            //prettyConfigText(v),
            v, // use the labels in the directory
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
          ),
          children: configList(context, "/json/" + k),
          trailing: _dropOrSave("/json/" + k),
          onExpansionChanged: (value) {
            if (value == true) {
              getJSONData(widget.ipaddress, "/json/" + k);
            }
          },
        ),
      ));
    });

// Every device has a version
    llist.add(Card(
      child: ExpansionTile(
        title: Text(
          prettyConfigText("Version"),
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
        ),
        children: configList(context, "/json/version"),
        trailing: _dropOrSave("/json/version"),
        onExpansionChanged: (value) {
          if (value == true) {
            getJSONData(widget.ipaddress, "/json/version");
          }
        },
      ),
    ));

    if (llist.isEmpty) llist.add(Text("Device not recognized."));

    return llist;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.ipaddress),
          actions: [
            IconButton(
                onPressed: () {
                  print("Refresh all");
                  // "forget" current node, then start over with...
                  //         nodes.removeDevice(widget.ipaddress);
                  this.getJSONData(widget.ipaddress, "/json/directory");
                  setState(() {});
                },
                icon: Icon(Icons.refresh))
          ],
        ),
        body: ListView(children: _buildDirectoryList()));
  }
}
