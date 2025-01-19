enum KeyMatch { none, partial, match }

/// Check if [input] is a key in [map] or if it's the start of a key
(KeyMatch, T?) matchKeys<T>(Map<String, T> map, String input) {
  // is input a key in map?
  if (map.containsKey(input)) {
    return (KeyMatch.match, map[input]);
  }

  // check if we matches special characters
  if (map.containsKey('[*]')) {
    return (KeyMatch.match, map['[*]']);
  }

  // check if input is the start of a key in map
  for (var key in map.keys) {
    if (key.startsWith(input)) {
      return (KeyMatch.partial, null);
    }
  }

  // if partialKey is not empty, we have a partial match
  return (KeyMatch.none, null);
}
