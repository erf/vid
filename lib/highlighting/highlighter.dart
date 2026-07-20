import '../features/lsp/lsp_protocol.dart';
import '../line_info.dart';
import 'theme.dart';

import 'languages/bash_tokenizer.dart';
import 'languages/c_tokenizer.dart';
import 'languages/css_tokenizer.dart';
import 'languages/dart_tokenizer.dart';
import 'languages/go_tokenizer.dart';
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
  final _goTokenizer = GoTokenizer();
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

  /// Merged tokens (regex + semantic overlay) for the current visible range.
  /// Precomputed by [tokenizeRange] so [style] is a fast range lookup.
  List<Token> _mergedTokens = [];

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
      'go' => 'go',
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
  /// [lines] is the buffer's line metadata (used to convert LSP semantic
  /// token positions to byte offsets). Pass null or omit if no semantic
  /// tokens are provided.
  ///
  /// Optionally overlay LSP [semanticTokens] for richer highlighting.
  void tokenizeRange(
    String text,
    int start,
    int end,
    String? path, {
    List<LineInfo>? lines,
    List<SemanticToken>? semanticTokens,
  }) {
    final lang = detectLanguage(path);
    if (lang == null) {
      _regexTokens = [];
      _mergedTokens = [];
      return;
    }

    _regexTokens = switch (lang) {
      'bash' => _bashTokenizer.tokenize(text, start, end),
      'c' => _cTokenizer.tokenize(text, start, end),
      'css' => _cssTokenizer.tokenize(text, start, end),
      'dart' => _dartTokenizer.tokenize(text, start, end),
      'go' => _goTokenizer.tokenize(text, start, end),
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

    // Precompute merged tokens: convert LSP semantic tokens (UTF-16
    // positions) to byte offsets once, then overlay them on regex tokens.
    final converted = _convertSemanticTokens(
      text,
      lines,
      semanticTokens,
      start,
      end,
    );
    _mergedTokens = converted.isNotEmpty
        ? _mergeTokens(_regexTokens, converted, start, end)
        : _regexTokens;
  }

  /// Convert LSP semantic tokens to text-offset [Token]s for [start, end).
  ///
  /// Returns an empty list if [semanticTokens] is null/empty or [lines] is
  /// unavailable. LSP positions are UTF-16 code units, which match Dart
  /// String offsets — no conversion needed.
  List<Token> _convertSemanticTokens(
    String text,
    List<LineInfo>? lines,
    List<SemanticToken>? semanticTokens,
    int start,
    int end,
  ) {
    if (semanticTokens == null || semanticTokens.isEmpty) {
      return const [];
    }
    if (lines == null || lines.isEmpty) return const [];

    final result = <Token>[];

    for (final st in semanticTokens) {
      if (st.line < 0 || st.line >= lines.length) continue;

      final lineInfo = lines[st.line];
      // Skip tokens before the visible range; stop after it (tokens are
      // sorted by line).
      if (lineInfo.end < start) continue;
      if (lineInfo.start > end) break;

      // UTF-16 character offsets match Dart String offsets directly.
      final tokenStart =
          lineInfo.start + st.character.clamp(0, lineInfo.length);
      final tokenEnd =
          lineInfo.start + (st.character + st.length).clamp(0, lineInfo.length);

      if (tokenStart < end && tokenEnd > start) {
        result.add(Token(st.type, tokenStart, tokenEnd));
      }
    }
    return result;
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

  /// Get tokens that overlap a byte range.
  ///
  /// Uses the merged token list precomputed by [tokenizeRange], where LSP
  /// semantic tokens have already been overlaid on regex tokens.
  List<Token> _getOverlappingTokens(int start, int end) {
    final overlapping = <Token>[];
    for (final token in _mergedTokens) {
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

    // Sort semantic tokens by start position (stable: tie-break on end so
    // shorter tokens sort first and merged output stays strictly ordered).
    final sortedSemantic = List<Token>.from(semanticTokens)
      ..sort((a, b) {
        final c = a.start.compareTo(b.start);
        return c != 0 ? c : a.end.compareTo(b.end);
      });

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

    // Sort by start position, tie-break on end to keep the merged list
    // strictly ordered even when tokens share a start offset.
    result.sort((a, b) {
      final c = a.start.compareTo(b.start);
      return c != 0 ? c : a.end.compareTo(b.end);
    });

    return result;
  }
}
