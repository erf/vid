import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../selection.dart';

/// Base class for operator actions.
///
/// Operators perform actions on a range of text (delete, change, yank, etc.).
/// Implement [applyToRanges] to define the operator behavior.
///
/// All operator actions should be const-constructible for zero allocation.
abstract class OperatorAction {
  const OperatorAction();

  /// Execute the operator on one or more ranges.
  ///
  /// [e] Editor instance
  /// [f] FileBuffer instance
  /// [ranges] Sorted list of selections defining the ranges to operate on
  /// [mainIndex] Index of the primary cursor's range in [ranges]
  /// [linewise] Whether the operation affects whole lines
  void applyToRanges(
    Editor e,
    FileBuffer f,
    List<Selection> ranges,
    int mainIndex, {
    bool linewise = false,
  });
}
