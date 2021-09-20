import 'package:flutter/material.dart';
/* string helpers */

// Capitalizes Each Word
String normaliseName(String name) {
  final stringBuffer = StringBuffer();

  var capitalizeNext = true;
  for (final letter in name.toLowerCase().codeUnits) {
    // UTF-16: A-Z => 65-90, a-z => 97-122.
    if (capitalizeNext && letter >= 97 && letter <= 122) {
      stringBuffer.writeCharCode(letter - 32);
      capitalizeNext = false;
    } else {
      // UTF-16: 32 == space, 46 == period
      if (letter == 32 || letter == 46) capitalizeNext = true;
      stringBuffer.writeCharCode(letter);
    }
  }
  return stringBuffer.toString();
}

// eg. 'dhcp_retry_time' returns 'DHCP Retry Time'
String prettyConfigText(String input) {
  String result = input.replaceAll("_", " ");
  result = normaliseName(result);
  result = result.replaceAll("Dhcp", "DHCP");
  result = result.replaceAll("Ip", "IP");
  result = result.replaceAll("Ntp", "NTP");
  result = result.replaceAll("Utc", "UTC");
  result = result.replaceAll("Dmx", "DMX");
  result = result.replaceAll("Rdm", "RDM");
  result = result.replaceAll("Sacn", "sACN");
  result = result.replaceAll("Artnet", "Art-Net");
  result = result.replaceAll("Ltc", "LTC");
  result = result.replaceAll("Led", "LED");
  result = result.replaceAll("Fps", "FPS");
  result = result.replaceAll("Rgb", "RGB");
  result = result.replaceAll("Oled", "OLED");
  result = result.replaceAll("Osc", "OSC");
  result = result.replaceAll("Oem", "OEM");
  result = result.replaceAll("Max7219", "MAX7219");

  return result;
}

String printDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}

// returns true if string is a number
bool isNumeric(String s) {
  if (s == "") {
    return false;
  }
  return double.tryParse(s) != null;
}

// convert colours to hex and back
extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
