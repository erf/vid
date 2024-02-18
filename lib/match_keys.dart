enum InputMatch { none, partial, match }

/// Check if [input] is a key in [map] or if it is part of a key
InputMatch matchKeys(Map map, String input) {
  // check if input is a key
  if (map.containsKey(input)) {
    return InputMatch.match;
  }
  // check if input is part of a key
  String partialKey =
      map.keys.firstWhere((key) => key.startsWith(input), orElse: () => '');
  // if partialKey is not empty, we have a partial match
  return partialKey.isEmpty ? InputMatch.none : InputMatch.partial;
}

extension MapExt on Map {
  /// Check if [input] is a key in this map or if it is part of a key
  InputMatch partialMatch(String input) => matchKeys(this, input);
}
