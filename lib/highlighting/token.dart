/// Token types for syntax highlighting.
///
/// The first set of types are used by regex-based tokenizers.
/// The LSP semantic token types below provide richer context from language servers.
enum TokenType {
  // Basic regex-based token types
  keyword,
  lineComment,
  blockComment,
  string,
  number,
  literal,
  type,
  plain,

  // LSP semantic token types (richer, context-aware)
  namespace,
  class_,
  enum_,
  interface,
  struct,
  typeParameter,
  parameter,
  variable,
  property,
  enumMember,
  event,
  function,
  method,
  macro,
  modifier,
  regexp,
  operator,
  decorator,
}

/// Standard LSP semantic token type names.
/// Used to map server responses to [TokenType].
class SemanticTokenTypes {
  static const namespace = 'namespace';
  static const type = 'type';
  static const class_ = 'class';
  static const enum_ = 'enum';
  static const interface = 'interface';
  static const struct = 'struct';
  static const typeParameter = 'typeParameter';
  static const parameter = 'parameter';
  static const variable = 'variable';
  static const property = 'property';
  static const enumMember = 'enumMember';
  static const event = 'event';
  static const function = 'function';
  static const method = 'method';
  static const macro = 'macro';
  static const keyword = 'keyword';
  static const modifier = 'modifier';
  static const comment = 'comment';
  static const string = 'string';
  static const number = 'number';
  static const regexp = 'regexp';
  static const operator = 'operator';
  static const decorator = 'decorator';

  /// All standard token types in LSP order (index matters for decoding).
  static const all = [
    namespace,
    type,
    class_,
    enum_,
    interface,
    struct,
    typeParameter,
    parameter,
    variable,
    property,
    enumMember,
    event,
    function,
    method,
    macro,
    keyword,
    modifier,
    comment,
    string,
    number,
    regexp,
    operator,
    decorator,
  ];

  /// Map LSP semantic token type name to [TokenType].
  static TokenType toTokenType(String lspType) {
    return switch (lspType) {
      namespace => TokenType.namespace,
      type || class_ || enum_ || interface || struct => TokenType.type,
      typeParameter => TokenType.typeParameter,
      parameter => TokenType.parameter,
      variable => TokenType.variable,
      property => TokenType.property,
      enumMember => TokenType.enumMember,
      event => TokenType.event,
      function => TokenType.function,
      method => TokenType.method,
      macro => TokenType.macro,
      keyword => TokenType.keyword,
      modifier => TokenType.modifier,
      comment => TokenType.blockComment,
      string => TokenType.string,
      number => TokenType.number,
      regexp => TokenType.regexp,
      operator => TokenType.operator,
      decorator => TokenType.decorator,
      // Dart Analysis Server custom types
      'boolean' => TokenType.literal,
      'annotation' => TokenType.decorator,
      _ => TokenType.plain,
    };
  }

  /// Map token type index to [TokenType].
  static TokenType fromIndex(int index, List<String> legend) {
    if (index < 0 || index >= legend.length) return TokenType.plain;
    return toTokenType(legend[index]);
  }
}

/// A token representing a span of text with absolute byte positions.
class Token {
  final TokenType type;
  final int start; // byte offset (inclusive)
  final int end; // byte offset (exclusive)

  const Token(this.type, this.start, this.end);

  int get length => end - start;

  /// Check if this token overlaps with a byte range.
  bool overlaps(int rangeStart, int rangeEnd) {
    return start < rangeEnd && end > rangeStart;
  }

  @override
  String toString() => 'Token($type, $start-$end)';
}
