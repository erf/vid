class Regex {
  /// Matches vim "word" units for w, e, b motions.
  /// A word is either:
  ///   - A sequence of word characters (Unicode letters, numbers, underscore)
  ///   - A sequence of other non-blank characters (punctuation, symbols)
  ///   - An empty line
  /// Emojis are treated as punctuation (separate word units), matching vim.
  static final word = RegExp(
    r'([\p{L}\p{N}_]+|[^\p{L}\p{N}_\s]+|(?<=\n)\n)',
    unicode: true,
  );

  /// Matches vim "WORD" units for W, B motions.
  /// A WORD is simply any sequence of non-whitespace characters.
  /// Unlike [word], punctuation and letters are not separated.
  static final wordCap = RegExp(r'(\S+|(?<=\n)\n)');

  /// Matches decimal integers with optional leading minus for Ctrl+A/Ctrl+X.
  static final number = RegExp(r'((?:-)?\d+)');

  /// Matches any non-whitespace character.
  static final nonSpace = RegExp(r'\S');

  /// Matches vim substitute command syntax: s/pattern/replacement
  static final substitute = RegExp(r's/.+[/]?.*');

  /// Matches the start of an empty line (for } motion)
  static final paragraph = RegExp(r'(?<=\n)(?=\n)');

  /// Matches the start of an empty line or start of file (for { motion)
  /// Parts:
  ///   (?<=\n)(?=\n)  - empty line (between two newlines)
  ///   ^              - start of file
  static final paragraphPrev = RegExp(r'(?<=\n)(?=\n)|^');

  /// Matches the start of a sentence for ')' and '(' motions
  /// Parts:
  ///   (?<=[.!?][\s]+)\S  - first char after .!? and whitespace
  ///   ^\S                - first char at start of file
  ///   (?<=\n)(?=\n)      - empty line (paragraph boundary)
  ///   (?<=\n\n)\S        - first char after empty line
  static final sentence = RegExp(
    r'(?<=[.!?][\s]+)\S|^\S|(?<=\n)(?=\n)|(?<=\n\n)\S',
  );
}
