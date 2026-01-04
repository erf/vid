enum KeyMatch { none, partial, match }

/// Bindings for a mode, with an optional fallback command for unmatched keys.
class ModeBindings<T> {
  final Map<String, T> bindings;
  final T? fallback;

  const ModeBindings(this.bindings, {this.fallback});

  /// Check if [input] is a key in bindings or if it's the start of a key.
  /// Falls back to [fallback] if no match is found.
  (KeyMatch, T?) match(String input) {
    // is input a key in map?
    if (bindings.containsKey(input)) {
      return (.match, bindings[input]);
    }

    // check if we have a fallback command
    if (fallback != null) {
      return (.match, fallback);
    }

    // check if input is the start of a key in map
    for (var key in bindings.keys) {
      if (key.startsWith(input)) {
        return (.partial, null);
      }
    }

    // no match found
    return (.none, null);
  }
}
