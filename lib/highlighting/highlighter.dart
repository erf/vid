import 'package:vid/features/lsp/lsp_protocol.dart';
import 'package:vid/highlighting/theme.dart';

import 'languages/bash_tokenizer.dart';
import 'languages/c_tokenizer.dart';
import 'languages/css_tokenizer.dart';
import 'languages/dart_tokenizer.dart';
import 'languages/javascript_tokenizer.dart';
import 'languages/json_tokenizer.dart';
import 'languages/lua_tokenizer.dart';
import 'languages/markdown_tokenizer.dart';
import 'languages/swift_tokenizer.dart';
import 'languages/typescript_tokenizer.dart';
import 'languages/xml_tokenizer.dart';
import 'languages/yaml_tokenizer.dart';
import 'token.dart';

/// Main syntax highlighter that tokenizes text and applies styling.
///
/// Supports two sources of tokens:
/// - Regex-based tokenization (always available, fast)
/// - LSP semantic tokens (richer, context-aware, when available)
///
/// When both are available, LSP tokens overlay regex tokens.
class Highlighter {
  Theme theme;
  final _bashTokenizer = BashTokenizer();
  final _cTokenizer = CTokenizer();
  final _cssTokenizer = CssTokenizer();
  final _dartTokenizer = DartTokenizer();
  final _javascriptTokenizer = JavaScriptTokenizer();
  final _jsonTokenizer = JsonTokenizer();
  final _luaTokenizer = LuaTokenizer();
  final _markdownTokenizer = MarkdownTokenizer();
  final _swiftTokenizer = SwiftTokenizer();
  final _typescriptTokenizer = TypeScriptTokenizer();
  final _xmlTokenizer = XmlTokenizer();
  final _yamlTokenizer = YamlTokenizer();

  /// Regex-based tokens for current visible range.
  List<Token> _regexTokens = [];

  /// LSP semantic tokens (if available).
  List<SemanticToken> _semanticTokens = [];

  /// Line offsets for converting semantic token positions to byte offsets.
  List<int> _lineOffsets = [];

  Highlighter({ThemeType themeType = .mono}) : theme = themeType.theme;

  set themeType(ThemeType type) => theme = type.theme;

  /// Detect language from file extension.
  String? detectLanguage(String? path) {
    if (path == null) return null;
    final dot = path.lastIndexOf('.');
    if (dot == -1) return null;
    final ext = path.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'bash' || 'sh' || 'zsh' => 'bash',
      'c' || 'h' => 'c',
      'css' => 'css',
      'dart' => 'dart',
      'js' || 'mjs' || 'cjs' || 'jsx' => 'javascript',
      'lua' => 'lua',
      'md' || 'markdown' => 'markdown',
      'swift' => 'swift',
      'ts' || 'mts' || 'tsx' => 'typescript',
      'yaml' || 'yml' => 'yaml',
      'json' => 'json',
      'xml' ||
      'html' ||
      'htm' ||
      'xhtml' ||
      'svg' ||
      'xsl' ||
      'xslt' ||
      'plist' ||
      'xcworkspacedata' ||
      'xcscheme' => 'xml',
      _ => null,
    };
  }

  /// Tokenize a range of the document using regex-based tokenization.
  ///
  /// Optionally overlay LSP [semanticTokens] for richer highlighting.
  void tokenizeRange(
    String text,
    int start,
    int end,
    String? path, {
    List<SemanticToken>? semanticTokens,
  }) {
    final lang = detectLanguage(path);
    if (lang == null) {
      _regexTokens = [];
      _semanticTokens = [];
      return;
    }

    _regexTokens = switch (lang) {
      'bash' => _bashTokenizer.tokenize(text, start, end),
      'c' => _cTokenizer.tokenize(text, start, end),
      'css' => _cssTokenizer.tokenize(text, start, end),
      'dart' => _dartTokenizer.tokenize(text, start, end),
      'javascript' => _javascriptTokenizer.tokenize(text, start, end),
      'lua' => _luaTokenizer.tokenize(text, start, end),
      'markdown' => _markdownTokenizer.tokenize(text, start, end),
      'swift' => _swiftTokenizer.tokenize(text, start, end),
      'typescript' => _typescriptTokenizer.tokenize(text, start, end),
      'yaml' => _yamlTokenizer.tokenize(text, start, end),
      'json' => _jsonTokenizer.tokenize(text, start, end),
      'xml' => _xmlTokenizer.tokenize(text, start, end),
      _ => [],
    };

    // Store semantic tokens and build line offset table if provided
    if (semanticTokens != null && semanticTokens.isNotEmpty) {
      _semanticTokens = semanticTokens;
      _buildLineOffsets(text);
    } else {
      _semanticTokens = [];
      _lineOffsets = [];
    }
  }

  /// Build a table of line start offsets for position conversion.
  void _buildLineOffsets(String text) {
    _lineOffsets = [0];
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0A) {
        _lineOffsets.add(i + 1);
      }
    }
  }

  /// Convert LSP line/character position to byte offset.
  int _positionToOffset(int line, int character) {
    if (line < 0 || line >= _lineOffsets.length) return -1;
    return _lineOffsets[line] + character;
  }

  /// Apply styling to a visible substring.
  ///
  /// [buffer] is the output buffer to write to.
  /// [text] is the original text to style (may contain tabs).
  /// [start] is the byte offset where this text starts in the document.
  /// [tabWidth] is the number of spaces to use for tab expansion.
  /// [selectionRanges] is a list of (selStart, selEnd) pairs for highlighting.
  /// [secondaryCursorRanges] is a list of (start, end) pairs for secondary
  /// cursor positions (shown with distinct color from selection).
  void style(
    StringBuffer buffer,
    String text,
    int start, {
    int tabWidth = 2,
    List<(int, int)> selectionRanges = const [],
    List<(int, int)> secondaryCursorRanges = const [],
  }) {
    if (text.isEmpty) {
      buffer.write(text);
      return;
    }

    // Get tokens that overlap this text range
    final textEndByte = start + text.length;
    final tokens = _getOverlappingTokens(start, textEndByte);

    if (tokens.isEmpty &&
        selectionRanges.isEmpty &&
        secondaryCursorRanges.isEmpty) {
      buffer.write(_expandTabs(text, tabWidth));
      return;
    }

    // Get selection and secondary cursor background colors for highlighting
    final selBg = theme.selectionBackground;
    final secondaryCursorBg = theme.secondaryCursorBackground;

    // Build styled output
    var pos = 0;
    final textLen = text.length;

    for (final token in tokens) {
      // Clamp token positions to valid range (tokens may be stale after edits)
      final tokenStart = (token.start <= start ? 0 : token.start - start).clamp(
        0,
        textLen,
      );
      final tokenEnd = (token.end >= textEndByte ? textLen : token.end - start)
          .clamp(0, textLen);

      // Skip invalid tokens (can happen with stale LSP semantic tokens)
      if (tokenStart >= tokenEnd) continue;

      // Add unstyled text before token
      if (tokenStart > pos) {
        _writeWithSelections(
          buffer,
          _expandTabs(text.substring(pos, tokenStart), tabWidth),
          start + pos,
          selectionRanges,
          selBg,
          null, // no syntax color for plain text
          secondaryCursorRanges,
          secondaryCursorBg,
        );
      }

      // Add styled token
      final syntaxColor = token.type != TokenType.plain
          ? theme.colorFor(token.type)
          : null;
      _writeWithSelections(
        buffer,
        _expandTabs(text.substring(tokenStart, tokenEnd), tabWidth),
        start + tokenStart,
        selectionRanges,
        selBg,
        syntaxColor,
        secondaryCursorRanges,
        secondaryCursorBg,
      );

      pos = tokenEnd;
    }

    // Add remaining unstyled text
    if (pos < text.length) {
      _writeWithSelections(
        buffer,
        _expandTabs(text.substring(pos), tabWidth),
        start + pos,
        selectionRanges,
        selBg,
        null,
        secondaryCursorRanges,
        secondaryCursorBg,
      );
    }
  }

  /// Write text to buffer, applying selection and secondary cursor highlighting.
  void _writeWithSelections(
    StringBuffer buffer,
    String text,
    int byteOffset,
    List<(int, int)> selectionRanges,
    String? selBg,
    String? syntaxColor,
    List<(int, int)> secondaryCursorRanges,
    String? secondaryCursorBg,
  ) {
    final hasSelections = selBg != null && selectionRanges.isNotEmpty;
    final hasSecondaryCursors =
        secondaryCursorBg != null && secondaryCursorRanges.isNotEmpty;

    if (!hasSelections && !hasSecondaryCursors) {
      // No selection or cursor highlighting needed
      if (syntaxColor != null) {
        buffer.write(syntaxColor);
        buffer.write(text);
        theme.resetCode(buffer);
      } else {
        buffer.write(text);
      }
      return;
    }

    // Check if any part of this text is in a selection or secondary cursor
    final textEnd = byteOffset + text.length;
    bool anySelection = false;
    bool anySecondaryCursor = false;
    for (final (selStart, selEnd) in selectionRanges) {
      if (selStart < textEnd && selEnd > byteOffset) {
        anySelection = true;
        break;
      }
    }
    for (final (curStart, curEnd) in secondaryCursorRanges) {
      if (curStart < textEnd && curEnd > byteOffset) {
        anySecondaryCursor = true;
        break;
      }
    }

    if (!anySelection && !anySecondaryCursor) {
      // No selection or secondary cursor overlap, write normally
      if (syntaxColor != null) {
        buffer.write(syntaxColor);
        buffer.write(text);
        theme.resetCode(buffer);
      } else {
        buffer.write(text);
      }
      return;
    }

    // Need to handle character-by-character for selection/cursor boundaries
    var pos = 0;
    var currentByte = byteOffset;

    while (pos < text.length) {
      // Check if current byte is in any secondary cursor (takes precedence)
      bool nowInSecondaryCursor = false;
      for (final (curStart, curEnd) in secondaryCursorRanges) {
        if (currentByte >= curStart && currentByte < curEnd) {
          nowInSecondaryCursor = true;
          break;
        }
      }

      // Check if current byte is in any selection
      bool nowInSelection = false;
      if (!nowInSecondaryCursor) {
        for (final (selStart, selEnd) in selectionRanges) {
          if (currentByte >= selStart && currentByte < selEnd) {
            nowInSelection = true;
            break;
          }
        }
      }

      // Find extent of current run (same selection/cursor state)
      var runEnd = pos + 1;
      var runByte = currentByte + 1;
      while (runEnd < text.length) {
        bool nextInSecondaryCursor = false;
        for (final (curStart, curEnd) in secondaryCursorRanges) {
          if (runByte >= curStart && runByte < curEnd) {
            nextInSecondaryCursor = true;
            break;
          }
        }
        bool nextInSelection = false;
        if (!nextInSecondaryCursor) {
          for (final (selStart, selEnd) in selectionRanges) {
            if (runByte >= selStart && runByte < selEnd) {
              nextInSelection = true;
              break;
            }
          }
        }
        if (nextInSecondaryCursor != nowInSecondaryCursor ||
            nextInSelection != nowInSelection) {
          break;
        }
        runEnd++;
        runByte++;
      }

      // Write this run with appropriate styling
      final runText = text.substring(pos, runEnd);
      if (nowInSecondaryCursor) {
        // Secondary cursor takes precedence - use distinct cursor color
        buffer.write(secondaryCursorBg);
        if (syntaxColor != null) buffer.write(syntaxColor);
        buffer.write(runText);
        theme.resetCode(buffer);
      } else if (nowInSelection) {
        buffer.write(selBg);
        if (syntaxColor != null) buffer.write(syntaxColor);
        buffer.write(runText);
        theme.resetCode(buffer);
      } else {
        if (syntaxColor != null) {
          buffer.write(syntaxColor);
          buffer.write(runText);
          theme.resetCode(buffer);
        } else {
          buffer.write(runText);
        }
      }

      pos = runEnd;
      currentByte = runByte;
    }
  }

  /// Expand tabs to spaces.
  String _expandTabs(String text, int tabWidth) {
    if (!text.contains('\t')) return text;
    return text.replaceAll('\t', ' ' * tabWidth);
  }

  /// Get tokens that overlap a byte range, merging regex and semantic tokens.
  ///
  /// LSP semantic tokens take precedence over regex tokens for overlapping
  /// regions, providing richer context-aware highlighting.
  List<Token> _getOverlappingTokens(int start, int end) {
    // Convert semantic tokens to regular tokens with byte positions
    final semanticConverted = <Token>[];
    for (final st in _semanticTokens) {
      final tokenStart = _positionToOffset(st.line, st.character);
      if (tokenStart < 0) continue;
      final tokenEnd = tokenStart + st.length;

      // Only include tokens that overlap our range
      if (tokenStart < end && tokenEnd > start) {
        semanticConverted.add(Token(st.type, tokenStart, tokenEnd));
      }
    }

    // If we have semantic tokens, merge them with regex tokens
    // Semantic tokens take precedence
    if (semanticConverted.isNotEmpty) {
      return _mergeTokens(_regexTokens, semanticConverted, start, end);
    }

    // Fall back to regex tokens only
    final overlapping = <Token>[];
    for (final token in _regexTokens) {
      if (token.start >= end) break;
      if (token.overlaps(start, end)) {
        overlapping.add(token);
      }
    }
    return overlapping;
  }

  /// Merge regex and semantic tokens, with semantic taking precedence.
  ///
  /// For any region covered by a semantic token, the regex token is
  /// replaced/split.
  List<Token> _mergeTokens(
    List<Token> regexTokens,
    List<Token> semanticTokens,
    int start,
    int end,
  ) {
    final result = <Token>[];

    // Sort semantic tokens by start position
    final sortedSemantic = List<Token>.from(semanticTokens)
      ..sort((a, b) => a.start.compareTo(b.start));

    // Process regex tokens, splitting around semantic tokens
    for (final regex in regexTokens) {
      if (regex.start >= end) break;
      if (!regex.overlaps(start, end)) continue;

      var currentStart = regex.start;
      final regexEnd = regex.end;

      for (final semantic in sortedSemantic) {
        if (semantic.start >= regexEnd) break;
        if (!semantic.overlaps(currentStart, regexEnd)) continue;

        // Add regex portion before semantic token
        if (currentStart < semantic.start) {
          result.add(Token(regex.type, currentStart, semantic.start));
        }

        // Add semantic token (it takes precedence)
        final semStart = semantic.start < currentStart
            ? currentStart
            : semantic.start;
        final semEnd = semantic.end > regexEnd ? regexEnd : semantic.end;
        if (semStart < semEnd) {
          result.add(Token(semantic.type, semStart, semEnd));
        }

        currentStart = semantic.end;
      }

      // Add remaining regex portion after all semantic tokens
      if (currentStart < regexEnd) {
        result.add(Token(regex.type, currentStart, regexEnd));
      }
    }

    // Add any semantic tokens that don't overlap any regex token
    // (these weren't handled in the merge loop above)
    for (final semantic in sortedSemantic) {
      if (!semantic.overlaps(start, end)) continue;

      // Check if this semantic token overlaps any regex token
      // If it does, it was already processed in the merge loop
      bool overlapsRegex = false;
      for (final regex in regexTokens) {
        if (semantic.overlaps(regex.start, regex.end)) {
          overlapsRegex = true;
          break;
        }
      }
      if (!overlapsRegex) {
        result.add(semantic);
      }
    }

    // Sort by start position
    result.sort((a, b) => a.start.compareTo(b.start));

    return result;
  }
}
