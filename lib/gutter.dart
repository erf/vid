import 'package:termio/termio.dart';

import 'highlighting/theme.dart';

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

  /// Git: line was added (future).
  gitAdded,

  /// Git: line was modified (future).
  gitModified,

  /// Git: line was deleted (future).
  gitDeleted,

  /// Debugger breakpoint (future).
  breakpoint,

  /// User bookmark (future).
  bookmark,
}

/// A sign to display in the gutter for a specific line.
class GutterSign {
  /// The type of sign to display.
  final GutterSignType type;

  /// Optional message associated with this sign (e.g., diagnostic message).
  final String? message;

  const GutterSign({required this.type, this.message});

  /// Get the character to display for this sign type.
  String get char => switch (type) {
    GutterSignType.error => '●',
    GutterSignType.warning => '●',
    GutterSignType.hint => '●',
    GutterSignType.codeAction => '*',
    GutterSignType.gitAdded => '┃',
    GutterSignType.gitModified => '┃',
    GutterSignType.gitDeleted => '▁',
    GutterSignType.breakpoint => '●',
    GutterSignType.bookmark => '★',
  };

  /// Get the ANSI color code for this sign type.
  String colorCode(Theme theme) => switch (type) {
    GutterSignType.error => theme.diagnosticError ?? Ansi.fg(Color.red),
    GutterSignType.warning => theme.diagnosticWarning ?? Ansi.fg(Color.yellow),
    GutterSignType.hint => theme.diagnosticHint ?? Ansi.fg(Color.blue),
    GutterSignType.codeAction => Ansi.fg(Color.cyan),
    GutterSignType.gitAdded => Ansi.fg(Color.green),
    GutterSignType.gitModified => Ansi.fg(Color.yellow),
    GutterSignType.gitDeleted => Ansi.fg(Color.red),
    GutterSignType.breakpoint => Ansi.fg(Color.red),
    GutterSignType.bookmark => Ansi.fg(Color.blue),
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
