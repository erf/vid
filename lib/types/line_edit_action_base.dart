import '../editor.dart';
import '../file_buffer/file_buffer.dart';

/// Base class for line edit actions (`:` commands).
///
/// Line edit actions are command-line commands like `:w`, `:q`, `:e`, etc.
/// They receive parsed command arguments.
///
/// All line edit actions should be const-constructible for zero allocation.
///
/// Example usage:
///   const CmdWrite()(editor, fileBuffer, ['w', 'filename.txt']);
abstract class LineEditAction {
  const LineEditAction();

  /// Execute the line edit command.
  ///
  /// [e] Editor instance
  /// [f] FileBuffer instance
  /// [args] Parsed command arguments (first element is command name)
  void call(Editor e, FileBuffer f, List<String> args);
}
