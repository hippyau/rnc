import 'dart:async';
import 'dart:convert';
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
  // retrieve JSON from a node at ipaddress, looking for /json/filename.txt
  // decodes it into the nodes.foundDevices[ipaddress].configData[filename] map.
  Future<String> getJSONData(String ipaddress, String filename) async {
    var a = Uri.http(ipaddress, filename);
    var response;
    try {
      response = await http.get(a, headers: {"Accept": "application/json"});
      this.setState(() {
        var fileName = (filename.split('/').last);

        Map<String, dynamic> decode = json.decode(response.body);
        print(filename + ": " + decode.toString());

        if (fileName.contains(".txt")) {
          nodes.foundDevices[ipaddress].configData[filename] = decode[fileName];
        } else if (fileName.contains("directory")) {
          nodes.foundDevices[ipaddress].configData[filename] =
              decode["directory"];
        } else {
          nodes.foundDevices[ipaddress].configData[filename] = decode;
        }
        nodes.foundDevices[widget.ipaddress].configChanged[filename] = false;
      });
    } catch (e) {
      print("Error fetching $filename from $ipaddress");
      return "Error!";
    }
    return "Success!";
  }

  @override
  void initState() {
    // attempt to get the directory json file
    this.getJSONData(widget.ipaddress, "/json/directory");
    super.initState();
  }

  // store the changed setting
  void _setNewValue(String filename, String setting, String value) {
    print("set new value: Setting $setting = $value in $filename");
    nodes.foundDevices[widget.ipaddress].configChanged[filename] = true;
    nodes.foundDevices[widget.ipaddress].configData[filename][setting] = value;
    setState(() {}); // refresh the display
  }

  // return an editable list of all the available settings in the
  // given configuration filename
  List<Widget> configList(BuildContext context, String filename) {
    List<Widget> wlist = [];

    var configMap = nodes.foundDevices[widget.ipaddress].configData[filename];
    //
    if (configMap == null) {
      this.getJSONData(widget.ipaddress, filename);
      configMap = nodes.foundDevices[widget.ipaddress].configData[filename];
      if (configMap == null) {
        print("not yet fetched... $filename");
        //nodes.foundDevices[widget.ipaddress].configData[filename]
      }
    }

    //configMap.forEach((k, v) => print('$k : $v'));
    configMap?.forEach((k, v) {
      // decide what tile to add, based on the field type (k)
      var res;

      // boolean "switch"
      if (k.contains("use_")) {
        wlist.add(ListTile(
          title: Text(prettyConfigText(k)),
          trailing: Switch(
            value: (v != "0"),
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
//       else if (k.contains("time")) {
// // ask text edit (default)
//         wlist.add(ListTile(
//             title: Text(prettyConfigText(k)),
//             subtitle: Text("$v" + " Seconds"),
//             onTap: () async {
//               res = await prompt(
//                 context,
//                 title: Text(prettyConfigText(k)),
//                 initialValue: v.toString(),
//                 textOK: Text('Set'),
//                 textCancel: Text('Cancel'),
//                 hintText: "Seconds",
//                 validator: (String? value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a value';
//                   }
//                   return null;
//                 },
//                 minLines: 1,
//                 maxLines: 1,
//                 autoFocus: true,
//                 barrierDismissible: true,
//               );
//             }));
//       }
      else {
// ask text edit (default)

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

      // or ask ip address
    });

    return wlist;
  }

// should return a sve button or a "V" button
  Widget _dropOrSave(String filename) {
    if (filename.contains(".txt") &&
        nodes.foundDevices[widget.ipaddress].configChanged[filename] == true) {
      // TODO: fix: pretty
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            child: Text("Revert"),
            onPressed: () {
              print("Undo changed");
              nodes.foundDevices[widget.ipaddress].configChanged[filename] =
                  false;
              getJSONData(widget.ipaddress, filename);
              this.setState(() {});
            },
          ),
          TextButton(
            child: Text("Save"),
            onPressed: () {
              print("Post $filename to the device...");
              nodes.foundDevices[widget.ipaddress].configChanged[filename] =
                  false;

              // TODO: SUBMIT THE CHANGES

              // Read back the configuration
              getJSONData(widget.ipaddress, filename);
              this.setState(() {});
            },
          ),
        ],
      );
    } else {
      return Icon(Icons.arrow_drop_down);
    }
  }

  List<Widget> _buildDirectoryList() {
    List<Widget> llist = [];

    // read the node directory (locally cached)
    var dirMap =
        nodes.foundDevices[widget.ipaddress].configData["/json/directory"];

    // present a section for all directory entries... (if any)
    dirMap?.forEach((k, v) {
      llist.add(Card(
        child: ExpansionTile(
            title: Text(
              prettyConfigText(v),
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            ),
            children: configList(context, "/json/" + k),
            trailing: _dropOrSave("/json/" + k)),
      ));
    });

    if (llist.isEmpty) llist.add(Text("Empty"));

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
                  print("refresh all");
                  // TODO: "forget" current node, then start over with...
                  this.getJSONData(widget.ipaddress, "/json/directory");
                  setState(() {});
                },
                icon: Icon(Icons.refresh))
          ],
        ),
        body: ListView(children: _buildDirectoryList()));
  }
}
