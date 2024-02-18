enum InputMatch { none, partial, match }

// check if input is a key or part of a key
InputMatch matchKeys(Map<String, Object> bindings, String input) {
  // we have a match if input is a key
  if (bindings.containsKey(input)) {
    return InputMatch.match;
  }
  // check if input is part of a key
  String partialKey = bindings.keys
      .firstWhere((key) => key.startsWith(input), orElse: () => '');
  // if partialKey is not empty, we have a partial match
  return partialKey.isEmpty ? InputMatch.none : InputMatch.partial;
}
