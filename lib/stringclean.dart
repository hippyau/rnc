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
  result = result.replaceAll("Sacn", "sACN");
  return result;
}

String printDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}
