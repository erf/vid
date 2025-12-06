enum KeyMatch { none, partial, match }

/// Bindings for a mode, with an optional fallback command for unmatched keys.
class ModeBindings<T> {
  final Map<String, T> bindings;
  final T? fallback;

  const ModeBindings(this.bindings, {this.fallback});
}

/// Check if [input] is a key in [modeBindings] or if it's the start of a key.
/// Falls back to [modeBindings.fallback] if no match is found.
(KeyMatch, T?) matchKeys<T>(ModeBindings<T> modeBindings, String input) {
  final map = modeBindings.bindings;

  // is input a key in map?
  if (map.containsKey(input)) {
    return (.match, map[input]);
  }

  // check if we have a fallback command
  if (modeBindings.fallback != null) {
    return (.match, modeBindings.fallback);
  }

  // check if input is the start of a key in map
  for (var key in map.keys) {
    if (key.startsWith(input)) {
      return (.partial, null);
    }
  }

  // no match found
  return (.none, null);
}
