enum KeyMatch { none, partial, match }

/// Check if [input] is a key in [map] or if it's the start of a key
KeyMatch mapPartialMatch(Map map, String input) {
  // is input a key in map?
  if (map.containsKey(input)) {
    return KeyMatch.match;
  }

  // check if input is the start of a key in map
  final String partialKey =
      map.keys.firstWhere((key) => key.startsWith(input), orElse: () => '');

  // if partialKey is not empty, we have a partial match
  return partialKey.isEmpty ? KeyMatch.none : KeyMatch.partial;
}

extension MapExt on Map {
  /// Check if [input] is a key in [this] Map or if it's the start of a key
  KeyMatch partialMatch(String input) => mapPartialMatch(this, input);
}
