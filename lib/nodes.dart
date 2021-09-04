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

  void findDevices() {
    // TODO: Search for devices

    // add to the Map,
    addDevice("192.168.1.96", name: "E131 Linux", type: "Application");
    // simulate some devices....
    addDevice("127.0.0.2", name: "This Device2", type: "Application");
    addDevice("127.0.0.3", name: "This Device3", type: "Application");
    addDevice("127.0.0.4", name: "This Device3", type: "Application");
  }
}
