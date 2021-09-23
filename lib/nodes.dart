import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';

/* global nodes register */
NodeRecords nodes = NodeRecords();

bool searchingForDevices = false;

// record of a single node
class NodeRecord {
  String name = "Node";
  String type = "None";
  final Map<String, dynamic> configData = {}; // filename.txt JSON strings
  final Map<String, bool> configChanged = {}; // has config changed

}

class NodeRecords {
  // where we keep the map of node records..
  Map foundDevices = new Map<String, NodeRecord>();

  // constructor
  NodeRecords() {
    // findDevices();
  }

  void addDevice(String ip, {String? type, String? name}) {
    foundDevices[ip] = new NodeRecord();
    foundDevices[ip].name = name;
    foundDevices[ip].type = type;
  }

  void removeDevice(String ip) {
    foundDevices.remove(ip);
  }

  bool _getJSONlist(String ipaddress) {
    var a = Uri.http(ipaddress, "/json/list");
    try {
      var response = http.get(a, headers: {"Accept": "application/json"});

      response.then((value) {
        print(value.body);

        Map<String, dynamic> decode = json.decode(value.body);
        print("LIST: " + decode.toString());

        var nodename = decode["list"]?["name"];
        var nodetype = decode["list"]?["node"]?["type"];
        if (nodetype != null && nodename != null) {
          addDevice(ipaddress, name: nodename, type: nodetype);
          return true;
        }
      });
    } catch (e) {
      print("Error fetching LIST from $ipaddress : $e");
    }
    return false;
  }

  Future<bool> findDevices() async {
    searchingForDevices = true;
    addDevice("192.168.1.96", name: "E131 Linux", type: "Application");
    // addDevice("192.168.1.44", name: "Note", type: "Type");
    //  addDevice("192.168.1.95", name: "Display Name", type: "Board");
    var addedAny = false;

    // might be required for android et al.
    var factory = (dynamic host, int port,
        {bool? reuseAddress, bool? reusePort, int? ttl}) {
      var tll = 5;
      return RawDatagramSocket.bind(host, port,
          reuseAddress: true, reusePort: true, ttl: tll);
    };

    final MDnsClient client = MDnsClient(rawDatagramSocketFactory: factory);

    // final MDnsClient client = MDnsClient();

    List<String> foundips = [];

    // Search for devices
    print("mDNS: Search...");
    const String name = '_http._tcp.local';
    await client.start();
    // Get the PTR record for the service.
    await for (PtrResourceRecord ptr in client
        .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name))) {
      // Use the domainName from the PTR record to get the SRV record,
      // which will have the port and local hostname.
      // Note that duplicate messages may come through, especially if any
      // other mDNS queries are running elsewhere on the machine.
      await for (SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName))) {
        // Domain name will be something like "io.flutter.example@some-iphone.local._dartobservatory._tcp.local"
        final String bundleId =
            ptr.domainName; //.substring(0, ptr.domainName.indexOf('@'));
        // get the IPv4 address
        await for (final IPAddressResourceRecord record
            in client.lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target))) {
          // we now have an IP, a PORT and a node name
          var ipaddress = record.address.address;
          print(
              'mDNS: -> found: ($ipaddress) ${srv.target}:${srv.port} for "$bundleId".');

          if (foundips.contains(ipaddress) != true) {
            // try to get /json/list then add to device list
            if (_getJSONlist(ipaddress)) {
              addedAny = true;
            }
          }

          foundips.add(ipaddress);
        }
      }
    }
    client.stop();
    print('mDNS: Search Complete.');
    searchingForDevices = false;
    return addedAny;
  }

  void rebootDevice(String ipaddress) async {
    var postbody = "{\"reboot\":1}";

    String addr = "http://" + ipaddress + "/json/action";
    print("rebootDevice: Post to '$addr': " + postbody);

    var res;
    res = await http.post(
      Uri.parse(addr),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: postbody,
    );
    print("rebootDevice: Post Return: " + res.body);
    if (!res.body.contains("OK")) {
      // failed
      print("rebootDevice: Post Failed!");
    }
    return;
  }
}
