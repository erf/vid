enum InputMatch {
  none,
  partial,
  match,
}

InputMatch matchKeys(String input, Map<String, Object> bindings) {
  // we have a match if input is a key
  if (bindings.containsKey(input)) {
    return InputMatch.match;
  }
  // check if input is part of a key
  final partialKey = bindings.keys
      .firstWhere((key) => key.startsWith(input), orElse: () => '');
  // if partialKey is not empty, we have a partial match
  return partialKey.isEmpty ? InputMatch.none : InputMatch.partial;
}
