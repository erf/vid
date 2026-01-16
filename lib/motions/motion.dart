import '../actions/motions.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';

/// Signature for motion functions.
/// [e] Editor instance
/// [f] FileBuffer instance
/// [offset] Current byte offset
/// Returns the new byte offset (cursor position)
typedef MotionFunction = int Function(Editor e, FileBuffer f, int offset);

/// Types of motions - used for identification and reversing.
enum MotionType {
  // Character motions
  charNext,
  charPrev,

  // Line motions
  lineDown,
  lineUp,
  lineStart,
  lineEnd,
  firstNonBlank,

  // Word motions
  wordNext,
  wordPrev,
  wordEnd,
  wordEndPrev,
  wordCapNext,
  wordCapPrev,
  wordCapEnd,
  wordCapEndPrev,

  // File motions
  fileStart,
  fileEnd,

  // Find char motions (f/F/t/T)
  findNextChar,
  findPrevChar,
  findTillNextChar,
  findTillPrevChar,

  // Paragraph/sentence motions
  paragraphNext,
  paragraphPrev,
  sentenceNext,
  sentencePrev,

  // Same word motions (* / #)
  sameWordNext,
  sameWordPrev,

  // Search motions (n/N)
  searchNext,
  searchPrev,

  // Match bracket (%)
  matchBracket,

  // Special - for dd/yy/cc
  linewise,
}

extension MotionTypeExt on MotionType {
  /// The function that implements this motion
  MotionFunction get fn => switch (this) {
    .charNext => Motions.charNext,
    .charPrev => Motions.charPrev,
    .lineDown => Motions.lineDown,
    .lineUp => Motions.lineUp,
    .lineStart => Motions.lineStart,
    .lineEnd => Motions.lineEnd,
    .firstNonBlank => Motions.firstNonBlank,
    .wordNext => Motions.wordNext,
    .wordPrev => Motions.wordPrev,
    .wordEnd => Motions.wordEnd,
    .wordEndPrev => Motions.wordEndPrev,
    .wordCapNext => Motions.wordCapNext,
    .wordCapPrev => Motions.wordCapPrev,
    .wordCapEnd => Motions.wordCapEnd,
    .wordCapEndPrev => Motions.wordCapEndPrev,
    .fileStart => Motions.fileStart,
    .fileEnd => Motions.fileEnd,
    .findNextChar => Motions.findNextChar,
    .findPrevChar => Motions.findPrevChar,
    .findTillNextChar => Motions.findTillNextChar,
    .findTillPrevChar => Motions.findTillPrevChar,
    .paragraphNext => Motions.paragraphNext,
    .paragraphPrev => Motions.paragraphPrev,
    .sentenceNext => Motions.sentenceNext,
    .sentencePrev => Motions.sentencePrev,
    .sameWordNext => Motions.sameWordNext,
    .sameWordPrev => Motions.sameWordPrev,
    .searchNext => Motions.searchNext,
    .searchPrev => Motions.searchPrev,
    .matchBracket => Motions.matchBracket,
    .linewise => Motions.linewise,
  };

  /// The reversed motion type, or null if not reversible
  MotionType? get reversed => switch (this) {
    .charNext => .charPrev,
    .charPrev => .charNext,
    .lineDown => .lineUp,
    .lineUp => .lineDown,
    .wordNext => .wordPrev,
    .wordPrev => .wordNext,
    .wordEnd => .wordEndPrev,
    .wordEndPrev => .wordEnd,
    .wordCapNext => .wordCapPrev,
    .wordCapPrev => .wordCapNext,
    .wordCapEnd => .wordCapEndPrev,
    .wordCapEndPrev => .wordCapEnd,
    .fileStart => .fileEnd,
    .fileEnd => .fileStart,
    .findNextChar => .findPrevChar,
    .findPrevChar => .findNextChar,
    .findTillNextChar => .findTillPrevChar,
    .findTillPrevChar => .findTillNextChar,
    .paragraphNext => .paragraphPrev,
    .paragraphPrev => .paragraphNext,
    .sentenceNext => .sentencePrev,
    .sentencePrev => .sentenceNext,
    .sameWordNext => .sameWordPrev,
    .sameWordPrev => .sameWordNext,
    .searchNext => .searchPrev,
    .searchPrev => .searchNext,
    _ => null,
  };
}

/// A motion defined by type.
///
/// Motions move the cursor or define a range for operators.
/// - [inclusive]: If true, the character at the end position is included
///   in operator ranges. For cursor movement, this has no effect.
/// - [linewise]: If true, operators expand the range to full lines.
class Motion {
  const Motion(this.type, {this.inclusive = false, this.linewise = false});

  final MotionType type;

  /// Whether the end character is included in operator ranges (e.g., e, $, f).
  /// Inclusive motions: the cursor lands ON the last affected character.
  /// Exclusive motions: the cursor lands AFTER the last affected character.
  final bool inclusive;

  /// Whether this motion operates on whole lines (e.g., j, k, gg, G).
  final bool linewise;

  /// Execute this motion - makes Motion callable
  int call(Editor e, FileBuffer f, int offset) => type.fn(e, f, offset);

  /// Returns the reversed motion, or null if not reversible
  Motion? get reversed {
    final rev = type.reversed;
    if (rev == null) return null;
    return Motion(rev, inclusive: inclusive, linewise: linewise);
  }
}
