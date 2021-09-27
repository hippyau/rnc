import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'nodes.dart';

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
