import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
//import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';
import 'package:osc/osc.dart';
import 'package:udp/udp.dart';

//import 'dart:io';
//import 'package:udp/udp.dart';

/* global nodes register */
NodeRecords nodes = NodeRecords();

/* global flag - when true, we are searching for devices */
bool searchingForDevices = false;

// contains the record of a single node
class NodeRecord {
  String name = "Node";
  String type = "None";

  String timeCodeString = "00:00:00:00";
  int timeCodeType = 0;

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
    searchingForDevices = true; // global signal
    List<String> foundips = [];

    // simulate this device
    //addDevice("192.168.1.96", name: "E131 Linux", type: "Application");

    var addedAny = false; // found anything?

    // required for android et al.
    var factory = (dynamic host, int port,
        {bool? reuseAddress, bool? reusePort, int? ttl}) {
      var tll = 5;
      return RawDatagramSocket.bind(host, port,
          reuseAddress: true, reusePort: true, ttl: tll);
    };
    final MDnsClient client = MDnsClient(rawDatagramSocketFactory: factory);

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

          // found a new device?
          if (foundips.contains(ipaddress) != true) {
            // try to get /json/list then add to device list
            if (_getJSONlist(ipaddress)) {
              addedAny = true;
            }
          }

          // add the IP to the temporary found list
          foundips.add(ipaddress);
        }
      }
    }
    client.stop();
    print('mDNS: Search Complete.');
    searchingForDevices = false;
    return addedAny;
  }

// command a device to reboot
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

  void rxArtnetTimecode() async {
    // creates a UDP instance and binds it to the first available network

    var socket = await UDP.bind(Endpoint.any(port: Port(6454)));

    // receiving\listening
    await socket.listen((datagram) {
      if (nodes.foundDevices[datagram?.address.address] != null) {
        var str = String.fromCharCodes(datagram!.data);
        if (str.contains("Art-Net")) {
          var bytes = new ByteData.view(datagram.data.buffer);
          if (bytes.getUint16(9) == 0x9700) {
            var fr = datagram.data[14].toString().padLeft(2, '0');
            var sc = datagram.data[15].toString().padLeft(2, '0');
            var mn = datagram.data[16].toString().padLeft(2, '0');
            var hr = datagram.data[17].toString().padLeft(2, '0');
            var ty = datagram.data[18];

            str = "$hr:$mn:$sc:$fr";
            nodes.foundDevices[datagram.address.address].timeCodeString = str;
            nodes.foundDevices[datagram.address.address].timeCodeType = ty;

            //print("Artnet recieved TC: $str");
          }
        }
      }
    }, timeout: Duration(hours: 24));

    // close the UDP instances and their sockets.
    socket.close();
  }
}

// we are looking for our local IP(s)
Future<String> printIps() async {
  String ips = "";
  for (var interface in await NetworkInterface.list()) {
    print('== Interface: ${interface.name} ==');
    for (var addr in interface.addresses) {
      ips = ips + "${addr.address}\n";

      print(
          '${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}');
    }
  }
  return ips;
}

// realtimeLTC("192.168.1.44","")
void realtimeLTC(String ipaddress, String path, String cmd, String val) {
  final destination = InternetAddress(ipaddress);
  final port = 8000;

  final address = path;

  List<String> args = [];
  if (cmd != "") args.add(cmd);
  if (val != "") args.add(val);

  final arguments = <Object>[];

  for (var i = 3; i < args.length; i += 2) {
    arguments.add(DataCodec.forType(args[i]).toValue(args[i + 1]));
  }

  final message = OSCMessage(address, arguments: arguments);

  RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
    final bytes = message.toBytes();
    socket.send(bytes, destination, port);
    print("OSC Sent $bytes bytes");
  });
}

void realtimeUDP(
    String ipaddress, int port, String cmd, bool expectResponse) async {
  // creates a UDP instance and binds it to the first available network
  // interface on port 65000.
  var sender = await UDP.bind(Endpoint.any(port: Port(port)));

  // send a simple string to a broadcast endpoint on port 65001.
  var dataLength =
      await sender.send(cmd.codeUnits, Endpoint.broadcast(port: Port(port)));

  print("UDP String '$cmd' (${dataLength} bytes) sent.");

  if (expectResponse) {
    // creates a new UDP instance and binds it to the local address and the port
    // 65002.
    //var receiver = await UDP.bind(Endpoint.loopback(port: Port(65002)));

    // receiving\listening
    await sender.listen((datagram) {
      var str = String.fromCharCodes(datagram!.data);

      if (str != cmd) // ignore loopback
        print("UDP recieved '$str'");
    }, timeout: Duration(seconds: 2));
  }

  // close the UDP instances and their sockets.
  sender.close();
}












/*

Frame 45959: 61 bytes on wire (488 bits), 61 bytes captured (488 bits) on interface enp2s0, id 0
Ethernet II, Src: 02:42:10:33:08:d3 (02:42:10:33:08:d3), Dst: Broadcast (ff:ff:ff:ff:ff:ff)
Internet Protocol Version 4, Src: 192.168.1.44, Dst: 192.168.1.255
User Datagram Protocol, Src Port: 6454, Dst Port: 6454
Art-Net, Opcode: ArtTimeCode (0x9700)
    Descriptor Header
        ID: Art-Net
        OpCode: ArtTimeCode (0x9700)
        ProtVer: 14
    ArtTimeCode packet
    Excess Bytes: 00000000000001

0000   ff ff ff ff ff ff 02 42 10 33 08 d3 08 00 45 00   .......B.3....E.
0010   00 2f 41 02 40 00 40 11 75 40 c0 a8 01 2c c0 a8   ./A.@.@.u@...,..
0020   01 ff 19 36 19 36 00 1b 00 00 41 72 74 2d 4e 65   ...6.6....Art-Ne
0030   74 00 00 97 00 0e 00 00 02 07 00 00 01            t............
*/