import '../token.dart';
import '../tokenizer.dart';

/// Regex-based tokenizer for Bash/shell scripts.
///
/// Produces tokens with absolute byte positions for a given text range.
class BashTokenizer extends Tokenizer {
  // Shell keywords
  static const _keywords = {
    'if',
    'then',
    'else',
    'elif',
    'fi',
    'case',
    'esac',
    'for',
    'while',
    'until',
    'do',
    'done',
    'in',
    'function',
    'select',
    'time',
    'coproc',
  };

  // Shell builtins and common commands
  static const _builtins = {
    // Shell builtins
    'alias',
    'bg',
    'bind',
    'break',
    'builtin',
    'caller',
    'cd',
    'command',
    'compgen',
    'complete',
    'compopt',
    'continue',
    'declare',
    'dirs',
    'disown',
    'echo',
    'enable',
    'eval',
    'exec',
    'exit',
    'export',
    'fc',
    'fg',
    'getopts',
    'hash',
    'help',
    'history',
    'jobs',
    'kill',
    'let',
    'local',
    'logout',
    'mapfile',
    'popd',
    'printf',
    'pushd',
    'pwd',
    'read',
    'readarray',
    'readonly',
    'return',
    'set',
    'shift',
    'shopt',
    'source',
    'suspend',
    'test',
    'times',
    'trap',
    'type',
    'typeset',
    'ulimit',
    'umask',
    'unalias',
    'unset',
    'wait',
    // Common external commands
    'cat',
    'chmod',
    'chown',
    'cp',
    'curl',
    'cut',
    'date',
    'df',
    'diff',
    'du',
    'find',
    'grep',
    'head',
    'less',
    'ln',
    'ls',
    'man',
    'mkdir',
    'mktemp',
    'more',
    'mv',
    'ps',
    'rm',
    'rmdir',
    'rsync',
    'scp',
    'sed',
    'sort',
    'ssh',
    'tail',
    'tar',
    'tee',
    'touch',
    'tr',
    'uniq',
    'wc',
    'wget',
    'which',
    'xargs',
  };

  // Boolean literals
  static const _literals = {'true', 'false'};

  // Patterns
  static final _lineComment = RegExp(r'#.*');
  static final _shebang = RegExp(r'^#!.*');
  static final _doubleString = RegExp(r'"(?:[^"\\]|\\.)*"');
  static final _singleString = RegExp(r"'[^']*'");
  static final _dollarString = RegExp(r"\$'(?:[^'\\]|\\.)*'");
  static final _backtickCommand = RegExp(r'`[^`]*`');
  static final _variable = RegExp(
    r'\$(?:\{[^}]+\}|[a-zA-Z_][a-zA-Z0-9_]*|\d+|[@*#?$!-])',
  );
  static final _number = RegExp(r'\b(?:0x[0-9a-fA-F]+|0[0-7]*|[0-9]+)\b');
  static final _identifier = RegExp(r'[a-zA-Z_][a-zA-Z0-9_]*');
  static final _hereDocStart = RegExp(r"<<-?\s*'?(\w+)'?");

  @override
  List<Token> tokenize(String text, int start, int end) {
    final tokens = <Token>[];
    var pos = start;

    // Check if we're inside a here-doc
    final multiline = findMultiline(text, start);
    if (multiline != null && multiline.delimiter != null) {
      // Find the end of the here-doc
      final delimiter = multiline.delimiter!;
      final delimiterPos = text.indexOf(
        RegExp('^$delimiter\$', multiLine: true),
        pos,
      );
      if (delimiterPos == -1 || delimiterPos >= end) {
        // Entire range is inside here-doc
        tokens.add(Token(TokenType.string, pos, end));
        return tokens;
      } else {
        // Here-doc ends within range
        tokens.add(Token(TokenType.string, pos, delimiterPos));
        pos = delimiterPos + delimiter.length;
        if (pos < text.length && text[pos] == '\n') pos++;
      }
    }

    while (pos < end) {
      // Skip whitespace
      if (isWhitespace(text, pos)) {
        pos++;
        continue;
      }

      // Shebang (first line only)
      if (pos == 0 && matchesAt(text, pos, '#!')) {
        final match = _shebang.matchAsPrefix(text, pos);
        if (match != null) {
          final endPos = match.end > end ? end : match.end;
          tokens.add(Token(TokenType.lineComment, pos, endPos));
          pos = endPos;
          continue;
        }
      }

      // Line comment
      if (text[pos] == '#') {
        final match = _lineComment.matchAsPrefix(text, pos);
        if (match != null) {
          final endPos = match.end > end ? end : match.end;
          tokens.add(Token(TokenType.lineComment, pos, endPos));
          pos = endPos;
          continue;
        }
      }

      // Here-doc start
      if (matchesAt(text, pos, '<<')) {
        final match = _hereDocStart.matchAsPrefix(text, pos);
        if (match != null) {
          tokens.add(Token(TokenType.keyword, pos, match.end));
          pos = match.end;
          continue;
        }
      }

      // ANSI-C style string $'...'
      if (matchesAt(text, pos, "\$'")) {
        final match = _dollarString.matchAsPrefix(text, pos);
        if (match != null) {
          tokens.add(Token(TokenType.string, pos, match.end));
          pos = match.end;
          continue;
        }
      }

      // Variable $VAR, ${VAR}, $1, $@, etc.
      if (text[pos] == '\$' && pos + 1 < text.length && text[pos + 1] != '(') {
        final match = _variable.matchAsPrefix(text, pos);
        if (match != null) {
          tokens.add(Token(TokenType.variable, pos, match.end));
          pos = match.end;
          continue;
        }
      }

      // Double-quoted string
      if (text[pos] == '"') {
        final match = _doubleString.matchAsPrefix(text, pos);
        if (match != null) {
          tokens.add(Token(TokenType.string, pos, match.end));
          pos = match.end;
          continue;
        }
      }

      // Single-quoted string (literal, no escapes)
      if (text[pos] == "'") {
        final match = _singleString.matchAsPrefix(text, pos);
        if (match != null) {
          tokens.add(Token(TokenType.string, pos, match.end));
          pos = match.end;
          continue;
        }
      }

      // Backtick command substitution
      if (text[pos] == '`') {
        final match = _backtickCommand.matchAsPrefix(text, pos);
        if (match != null) {
          tokens.add(Token(TokenType.string, pos, match.end));
          pos = match.end;
          continue;
        }
      }

      // Number
      final numMatch = _number.matchAsPrefix(text, pos);
      if (numMatch != null) {
        tokens.add(Token(TokenType.number, pos, numMatch.end));
        pos = numMatch.end;
        continue;
      }

      // Identifier (keyword, builtin, or plain)
      final identMatch = _identifier.matchAsPrefix(text, pos);
      if (identMatch != null) {
        final word = identMatch.group(0)!;
        TokenType type;
        if (_keywords.contains(word)) {
          type = TokenType.keyword;
        } else if (_literals.contains(word)) {
          type = TokenType.literal;
        } else if (_builtins.contains(word)) {
          type = TokenType.type;
        } else {
          type = TokenType.plain;
        }
        tokens.add(Token(type, pos, identMatch.end));
        pos = identMatch.end;
        continue;
      }

      // Test brackets [[ and [
      if (matchesAt(text, pos, '[[')) {
        tokens.add(Token(TokenType.keyword, pos, pos + 2));
        pos += 2;
        continue;
      }
      if (matchesAt(text, pos, ']]')) {
        tokens.add(Token(TokenType.keyword, pos, pos + 2));
        pos += 2;
        continue;
      }

      // Skip other characters
      pos++;
    }

    return tokens;
  }

  @override
  Multiline? findMultiline(String text, int startByte) {
    // Scan backwards to find if we're inside a here-doc
    // This is a simplified implementation - full here-doc tracking is complex

    // Look for <<DELIMITER before our position
    var pos = 0;
    String? currentDelimiter;
    var insideHereDoc = false;

    while (pos < startByte) {
      // Skip to next line if we're not at line start
      final lineEnd = text.indexOf('\n', pos);
      if (lineEnd == -1) break;

      // Check for here-doc start on this line
      final lineText = text.substring(pos, lineEnd);
      final match = _hereDocStart.firstMatch(lineText);
      if (match != null && !insideHereDoc) {
        currentDelimiter = match.group(1);
        insideHereDoc = true;
        pos = lineEnd + 1;
        continue;
      }

      // Check for here-doc end
      if (insideHereDoc && currentDelimiter != null) {
        final trimmedLine = lineText.trim();
        if (trimmedLine == currentDelimiter) {
          insideHereDoc = false;
          currentDelimiter = null;
        }
      }

      pos = lineEnd + 1;
    }

    if (insideHereDoc && currentDelimiter != null) {
      return Multiline(currentDelimiter);
    }

    return null;
  }
}
