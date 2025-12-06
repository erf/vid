import '../editor.dart';
import '../file_buffer/file_buffer.dart';

abstract class Command {
  const Command();

  void execute(Editor e, FileBuffer f, String s) {}
}

/// Command that executes an action without needing the input character.
/// Use for actions like escape, backspace, enter, etc.
class ActionCommand extends Command {
  final void Function(Editor, FileBuffer) action;

  const ActionCommand(this.action);

  @override
  void execute(Editor e, FileBuffer f, String s) => action(e, f);
}

/// Command that executes an action with the input character.
/// Use for default insert handlers, replace mode, etc.
class InputCommand extends Command {
  final void Function(Editor, FileBuffer, String) action;

  const InputCommand(this.action);

  @override
  void execute(Editor e, FileBuffer f, String s) => action(e, f, s);
}
