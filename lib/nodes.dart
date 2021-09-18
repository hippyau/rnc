import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';

/* global nodes register */
NodeRecords nodes = NodeRecords();

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
    findDevices();
  }

  void addDevice(String ip, {String? type, String? name}) {
    foundDevices[ip] = new NodeRecord();
    foundDevices[ip].name = name;
    foundDevices[ip].type = type;
  }

  void removeDevice(String ip) {
    foundDevices.remove(ip);
  }

  void findDevices() async {
    addDevice("192.168.1.96", name: "E131 Linux", type: "Application");
    //  addDevice("192.168.1.95", name: "Display Name", type: "Board");

    // might be required for android et al.
    var factory = (dynamic host, int port,
        {bool? reuseAddress, bool? reusePort, int? ttl}) {
      var tll = 5;
      return RawDatagramSocket.bind(host, port,
          reuseAddress: true, reusePort: true, ttl: tll);
    };

    final MDnsClient client = MDnsClient(rawDatagramSocketFactory: factory);

    // final MDnsClient client = MDnsClient();

    // Search for devices
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
          print(
              'mDNS: found: (${record.address.address}) ${srv.target}:${srv.port} for "$bundleId".');
          addDevice(record.address.address.toString(),
              name: "Unknown", type: "mDNS");
        }
      }
    }
    client.stop();
    print('mDNS: Done.');

    // // add to the Map,
    // // simulate some devices....
    // addDevice("127.0.0.3", name: "This Device3", type: "Application");
    // addDevice("127.0.0.4", name: "This Device3", type: "Application");
    return;
  }
}
