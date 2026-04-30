import 'package:termio/termio.dart';

import 'highlighting/highlighter.dart';
import 'highlighting/theme.dart';
import 'highlighting/token.dart';

/// Types of signs that can appear in the gutter.
/// Ordered by display priority (higher priority signs shown when multiple exist).
enum GutterSignType {
  /// LSP error diagnostic.
  error,

  /// LSP warning diagnostic.
  warning,

  /// LSP hint or info diagnostic.
  hint,

  /// Code action available (lightbulb).
  codeAction,
}

/// A sign to display in the gutter for a specific line.
class GutterSign {
  /// The type of sign to display.
  final GutterSignType type;

  /// Optional message associated with this sign (e.g., diagnostic message).
  final String? message;

  /// Whether code actions are available on this line (combined indicator).
  final bool hasCodeAction;

  const GutterSign({
    required this.type,
    this.message,
    this.hasCodeAction = false,
  });

  /// Get the character to display for this sign type.
  /// Shows '!' when diagnostic has code actions available.
  String get char {
    // If this is a diagnostic with code actions, show combined indicator
    if (hasCodeAction) {
      return switch (type) {
        GutterSignType.error => '!',
        GutterSignType.warning => '!',
        GutterSignType.hint => '*',
        _ => '*',
      };
    }
    return switch (type) {
      GutterSignType.error => '●',
      GutterSignType.warning => '●',
      GutterSignType.hint => '●',
      GutterSignType.codeAction => '*',
    };
  }

  /// Get the ANSI color code for this sign type.
  String colorCode(Theme theme) => switch (type) {
    GutterSignType.error => theme.diagnosticError ?? Ansi.fg(Color.red),
    GutterSignType.warning => theme.diagnosticWarning ?? Ansi.fg(Color.yellow),
    GutterSignType.hint => theme.diagnosticHint ?? Ansi.fg(Color.blue),
    GutterSignType.codeAction => Ansi.fg(Color.cyan),
  };

  /// Priority for display when multiple signs exist on same line.
  /// Lower number = higher priority.
  int get priority => type.index;
}

/// Gutter information for all visible lines.
/// Maps line number (0-based) to the sign to display.
class GutterSigns {
  final Map<int, GutterSign> _signs = {};

  /// Add a sign for a line. If a sign already exists, keeps the higher priority one.
  void add(int lineNum, GutterSign sign) {
    final existing = _signs[lineNum];
    if (existing == null || sign.priority < existing.priority) {
      _signs[lineNum] = sign;
    }
  }

  /// Get the sign for a line, if any.
  GutterSign? operator [](int lineNum) => _signs[lineNum];

  /// Check if there are any signs.
  bool get isEmpty => _signs.isEmpty;

  /// Check if there are any signs.
  bool get isNotEmpty => _signs.isNotEmpty;

  /// Get all signs (for iteration).
  Map<int, GutterSign> get all => _signs;

  /// Clear all signs.
  void clear() => _signs.clear();
}

/// Renders the line-number / sign gutter and the end-of-line newline symbol.
///
/// Owns [width], which is recomputed each frame via [calculateWidth] before
/// rendering line content.
class GutterRenderer {
  final Highlighter highlighter;

  /// Current gutter width in characters (0 if gutter is disabled).
  /// Updated by [calculateWidth] each draw.
  int width = 0;

  GutterRenderer({required this.highlighter});

  /// Calculate gutter width based on total line count and sign column,
  /// and store the result in [width].
  ///
  /// Format: "● 123 " where ● is optional sign, 123 is line number.
  /// Returns 0 if gutter is disabled. Can show signs only (no line numbers)
  /// with width of 2 (sign + space).
  int calculateWidth(int totalLines, bool showLineNumbers, bool showSigns) {
    if (!showLineNumbers && !showSigns) {
      width = 0;
      return 0;
    }
    final signWidth = showSigns ? 2 : 0; // 1 char for sign + 1 space
    if (!showLineNumbers) {
      width = signWidth;
      return width;
    }
    // Digits + 1 space before + 1 space after = digits + 2
    final digits = totalLines.toString().length;
    width = signWidth + digits + 2; // e.g., "● 42 " = 5 chars with sign
    return width;
  }

  /// Render the gutter (line number column) for a screen row into [buffer].
  /// [lineNum] is 0-based, -1 for empty rows (past end of file).
  /// [isFirstWrap] indicates if this is the first row of a wrapped line.
  /// [sign] is an optional gutter sign to display (e.g., diagnostic indicator).
  /// [showSigns] indicates whether sign column is enabled.
  void render(
    StringBuffer buffer,
    int lineNum,
    int cursorLine,
    int totalLines, {
    bool isFirstWrap = true,
    GutterSign? sign,
    bool showSigns = false,
    bool showLineNumbers = true,
  }) {
    if (width == 0) return;

    final theme = highlighter.theme;

    // Render sign column if enabled
    if (showSigns) {
      if (sign != null && isFirstWrap) {
        buffer.write(sign.colorCode(theme));
        buffer.write(sign.char);
        theme.resetCode(buffer);
      } else {
        buffer.write(' ');
      }
      buffer.write(' ');
    }

    // Render line numbers if enabled
    if (showLineNumbers) {
      final digits = totalLines.toString().length;
      String gutterContent;
      if (lineNum < 0 || !isFirstWrap) {
        // Empty line or wrapped continuation - just spaces
        gutterContent = ' ' * (digits + 1);
      } else {
        // Format line number (1-based for display)
        final numStr = (lineNum + 1).toString().padLeft(digits);
        gutterContent = ' $numStr';

        // Apply active line highlight or muted color
        if (lineNum == cursorLine) {
          if (theme.gutterActiveLine != null) {
            buffer.write(theme.gutterActiveLine);
          }
        } else {
          if (theme.gutterForeground != null) {
            buffer.write(theme.gutterForeground);
          } else {
            // Fallback: use dim for non-active lines
            buffer.write(Ansi.dim());
          }
        }
      }

      buffer.write(gutterContent);
      buffer.write(' ');

      // Reset colors back to theme defaults
      theme.resetCode(buffer);
    }
  }

  /// Render the newline symbol at the end of a line, with optional
  /// highlighting for selections or secondary cursors.
  void renderNewlineSymbol(
    StringBuffer buffer, {
    required String newlineSymbol,
    required int lineStartByte,
    required int originalLength,
    required List<(int, int)> selectionRanges,
    required List<(int, int)> secondaryCursorRanges,
  }) {
    final newlineOffset = lineStartByte + originalLength;

    // Check if a secondary cursor is on the newline (takes precedence)
    final hasSecondaryCursor = secondaryCursorRanges.any(
      (range) => range.$1 == newlineOffset && range.$2 > range.$1,
    );

    // Check if newline is in any selection
    final inSelection = selectionRanges.any(
      (range) => range.$1 <= newlineOffset && newlineOffset < range.$2,
    );

    if (hasSecondaryCursor) {
      // Use distinct secondary cursor color
      final cursorBg =
          highlighter.theme.secondaryCursorBackground ??
          Ansi.bg(Color.brightBlack);
      buffer.write(cursorBg);
      buffer.write(newlineSymbol);
      highlighter.theme.resetCode(buffer);
    } else if (inSelection) {
      final selBg =
          highlighter.theme.selectionBackground ?? Ansi.bg(Color.brightBlack);
      buffer.write(selBg);
      buffer.write(newlineSymbol);
      highlighter.theme.resetCode(buffer);
    } else {
      final newlineColor = highlighter.theme.colorFor(TokenType.lineComment);
      buffer.write(newlineColor);
      buffer.write(newlineSymbol);
      highlighter.theme.resetCode(buffer);
    }
  }
}
