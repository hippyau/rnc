import 'package:multicast_dns/multicast_dns.dart';

/* global nodes register */
NodeRecords nodes = NodeRecords();

// record of a single node
class NodeRecord {
  String name = "Node";
  String type = "None";
  final Map<String, dynamic> configData = {}; // filename.txt JSON strings
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

  void findDevices() async {
    addDevice("192.168.1.96", name: "E131 Linux", type: "Application");

    // TODO: Search for devices

    const String name = '_http._tcp.local';
    final MDnsClient client = MDnsClient();
    await client.start();
    // Get the PTR recod for the service.
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
        print('found: '
            '${srv.target}:${srv.port} for "$bundleId".');
      }
    }
    client.stop();

    print('Done.');

    // // add to the Map,
    // // simulate some devices....
    // addDevice("127.0.0.3", name: "This Device3", type: "Application");
    // addDevice("127.0.0.4", name: "This Device3", type: "Application");
    return;
  }
}
