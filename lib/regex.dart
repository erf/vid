class Regex {
  static final word = RegExp(r'([\wæøå]+|[^\w\s]+|(?<=\n)\n)');
  static final wordCap = RegExp(r'(\S+|(?<=\n)\n)');
  static final number = RegExp(r'((?:-)?\d+)');
  static final scrollEvents = RegExp('\x1b[O[][A-D]');
  static final nonSpace = RegExp(r'\S');
  static final substitute = RegExp(r's/.+[/]?.*');

  /// Matches the start of an empty line (for } motion)
  static final paragraph = RegExp(r'(?<=\n)(?=\n)');

  /// Matches the start of an empty line or start of file (for { motion)
  /// Parts:
  ///   (?<=\n)(?=\n)  - empty line (between two newlines)
  ///   ^              - start of file
  static final paragraphPrev = RegExp(r'(?<=\n)(?=\n)|^');

  /// Matches the start of a sentence (for ) and ( motions)
  /// Parts:
  ///   (?<=[.!?][\s]+)\S  - first char after .!? and whitespace
  ///   ^\S                - first char at start of file
  ///   (?<=\n)(?=\n)      - empty line (paragraph boundary)
  ///   (?<=\n\n)\S        - first char after empty line
  static final sentence = RegExp(
    r'(?<=[.!?][\s]+)\S|^\S|(?<=\n)(?=\n)|(?<=\n\n)\S',
  );
}
