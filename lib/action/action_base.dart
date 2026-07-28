import '../editor.dart';
import '../file_buffer/file_buffer.dart';

/// Base class for general editor actions (normal mode, insert mode, etc.)
///
/// Actions are operations that modify editor state.
/// They take Editor and FileBuffer parameters.
///
/// Note: This is distinct from [MotionAction], [OperatorAction], and
/// [TextObjectAction] which have different call signatures.
///
/// All actions should be const-constructible to avoid runtime allocation.
///
/// Example usage:
///   const MyAction()(editor, fileBuffer);
abstract class Action {
  /// Const constructor for subclasses.
  const Action();

  /// Execute the action.
  void call(Editor e, FileBuffer f);
}
