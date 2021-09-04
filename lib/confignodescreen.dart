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
    var response = await http.get(a, headers: {"Accept": "application/json"});
    this.setState(() {
      var fileName = (filename.split('/').last);

      Map<String, dynamic> decode = json.decode(response.body);

      if (fileName.contains(".txt")) {
        nodes.foundDevices[ipaddress].configData[filename] = decode[fileName];
      } else {
        nodes.foundDevices[ipaddress].configData[filename] = decode;
      }
    });
    return "Success!";
  }

  @override
  void initState() {
    super.initState();
    // testing
    this.getJSONData("192.168.1.96", "/get/version");
    this.getJSONData("192.168.1.96", "/get/uptime");
    //this.getJSONData("192.168.1.96", "/get/display");

    this.getJSONData("192.168.1.96", "/json/rconfig.txt");
    this.getJSONData("192.168.1.96", "/json/network.txt");
    this.getJSONData("192.168.1.96", "/json/e131.txt");
  }

  // return an editable list of all the available settings in the
  // given configuration filename
  List<Widget> configList(BuildContext context, String filename) {
    List<Widget> wlist = [];

    var configMap = nodes.foundDevices[widget.ipaddress].configData[filename];
    //configMap.forEach((k, v) => print('$k : $v'));
    configMap?.forEach((k, v) {
      wlist.add(ListTile(
        title: Text(prettyConfigText(k)),
        subtitle: Text("$v"),
        onTap: () async {
          var res = await prompt(
            context,
            title: Text(prettyConfigText(k)),
            initialValue: v.toString(),
            textOK: Text('Set'),
            textCancel: Text('Cancel'),
            hintText: k,
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a value';
              }
              return null;
            },
            minLines: 1,
            maxLines: 1,
            autoFocus: true,
            barrierDismissible: true,
          );

          if (res != null) {
            //  print("set new value: $res");
            configMap[k] = res;
            setState(() {});
          }
        },
      ));
    });
    return wlist;
  }

  // return an editable list of all the available settings in the
  // given configuration filename
  List<Widget> spacerList(BuildContext context, String title, String sub) {
    List<Widget> wlist = [];

    wlist.add(ListTile(
      title: Text(title + " {" + sub + "}"),
      //    subtitle: Text(sub),
    ));
    return wlist;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.ipaddress),
        ),

        // TODO: Select which config.txt to edit
        // with some tabs or something, select between the files
        // eg. network.txt, e131.txt, rconfig.txt etc..
        body: ListView(
            children: spacerList(context, "Device Version", "Device") +
                configList(context, "/get/version") +
                spacerList(context, "Network", "Settings about the network") +
                configList(context, "/json/network.txt") +
                spacerList(context, "E131", "Settings about the sACN") +
                configList(context, "/json/e131.txt") +
                spacerList(context, "Advanced", "Settings about the node...") +
                configList(context, "/json/rconfig.txt")));
  }
}
