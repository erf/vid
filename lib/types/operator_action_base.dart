import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/range.dart';

/// Base class for operator actions.
///
/// Operators perform actions on a range of text (delete, change, yank, etc.).
/// Implement [call] to define the operator behavior.
///
/// All operator actions should be const-constructible for zero allocation.
abstract class OperatorAction {
  const OperatorAction();

  /// Execute the operator.
  ///
  /// [e] Editor instance
  /// [f] FileBuffer instance
  /// [range] The range to operate on (always normalized: start <= end)
  /// [linewise] Whether the operation affects whole lines
  void call(Editor e, FileBuffer f, Range range, {bool linewise = false});
}
