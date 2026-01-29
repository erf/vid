import '../token.dart';
import 'javascript_tokenizer.dart';

/// Regex-based tokenizer for TypeScript source code.
///
/// Extends [JavaScriptTokenizer] with TypeScript-specific keywords,
/// type annotations, and decorator support.
class TypeScriptTokenizer extends JavaScriptTokenizer {
  static const _tsKeywords = {
    // All JS keywords inherited, plus:
    'abstract',
    'as',
    'asserts',
    'declare',
    'enum',
    'implements',
    'infer',
    'interface',
    'is',
    'keyof',
    'module',
    'namespace',
    'never',
    'override',
    'private',
    'protected',
    'public',
    'readonly',
    'satisfies',
    'type',
    'unknown',
  };

  static const _tsBuiltinTypes = {
    'any',
    'boolean',
    'never',
    'number',
    'object',
    'string',
    'symbol',
    'unknown',
    'void',
    'Partial',
    'Required',
    'Readonly',
    'Record',
    'Pick',
    'Omit',
    'Exclude',
    'Extract',
    'NonNullable',
    'Parameters',
    'ConstructorParameters',
    'ReturnType',
    'InstanceType',
    'ThisParameterType',
    'OmitThisParameter',
    'ThisType',
    'Awaited',
  };

  @override
  Set<String> get keywords => {...super.keywords, ..._tsKeywords};

  @override
  Set<String> get builtinTypes => {...super.builtinTypes, ..._tsBuiltinTypes};

  static final _decoratorPattern = RegExp(r'@[a-zA-Z_$][a-zA-Z0-9_$]*');

  @override
  TokenMatch? matchToken(
    String text,
    int pos,
    int endByte,
    List<Token> tokens,
  ) {
    // Check for decorator (@decorator) before other tokens
    if (pos < text.length && text[pos] == '@') {
      final match = _decoratorPattern.matchAsPrefix(text, pos);
      if (match != null) {
        return TokenMatch(
          Token(TokenType.decorator, pos, match.end),
          match.end,
          null,
        );
      }
    }

    // Delegate to parent for all other tokens
    return super.matchToken(text, pos, endByte, tokens);
  }
}
