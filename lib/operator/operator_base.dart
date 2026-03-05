import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../range.dart';
import '../selection.dart';

/// Base class for operator actions.
///
/// Operators perform actions on a range of text (delete, change, yank, etc.).
/// Implement [call] to define the operator behavior.
///
/// All operator actions should be const-constructible for zero allocation.
abstract class OperatorAction {
  const OperatorAction();

  /// Execute the operator on a single range.
  ///
  /// [e] Editor instance
  /// [f] FileBuffer instance
  /// [range] The range to operate on (always normalized: start <= end)
  /// [linewise] Whether the operation affects whole lines
  void call(Editor e, FileBuffer f, Range range, {bool linewise = false});

  /// Execute the operator on multiple ranges (multi-cursor / visual mode).
  ///
  /// [e] Editor instance
  /// [f] FileBuffer instance
  /// [ranges] Sorted list of selections defining the ranges to operate on
  /// [mainIndex] Index of the primary cursor's range in [ranges]
  /// [linewise] Whether the operation affects whole lines
  ///
  /// Default implementation delegates to [call] for single-range case.
  void applyToRanges(
    Editor e,
    FileBuffer f,
    List<Selection> ranges,
    int mainIndex, {
    bool linewise = false,
  }) {
    if (ranges.length == 1) {
      final r = ranges.first;
      call(e, f, Range(r.start, r.end), linewise: linewise);
      return;
    }
    // Subclasses should override for proper multi-range behavior.
    // Fallback: apply to first range only (should not happen in practice).
    final r = ranges[mainIndex];
    call(e, f, Range(r.start, r.end), linewise: linewise);
  }
}
