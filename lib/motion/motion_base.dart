import '../editor.dart';
import '../file_buffer/file_buffer.dart';

/// Base class for motion actions.
///
/// Motions calculate a new cursor position from the current offset.
/// Implement [call] to define the motion behavior.
///
/// All motion actions should be const-constructible for zero allocation.
abstract class MotionAction {
  const MotionAction();

  /// Execute the motion.
  ///
  /// [e] Editor instance
  /// [f] FileBuffer instance
  /// [offset] Current string index (UTF-16 code unit index into [FileBuffer.text])
  /// Returns the new string index (cursor position)
  int call(Editor e, FileBuffer f, int offset);

  /// Sentinel value for desiredColumn meaning "end of line".
  static const int endOfLineColumn = 0x7FFFFFFF;
}
