import 'package:vid/edit_builder.dart';

import '../actions/operators.dart';
import '../actions/text_objects.dart';
import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../modes.dart';
import '../motions/motion.dart';

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

/// Command that re-executes a sequence of keys.
class AliasCommand extends Command {
  final String alias;

  const AliasCommand(this.alias);

  @override
  void execute(Editor e, FileBuffer f, String s) => e.alias(alias);
}

/// Command that switches to a different mode.
class ModeCommand extends Command {
  final Mode mode;

  const ModeCommand(this.mode);

  @override
  void execute(Editor e, FileBuffer f, String s) => f.setMode(e, mode);
}

/// Command that handles count prefix (0-9).
/// '0' without a count moves to line start, otherwise accumulates digits.
class CountCommand extends Command {
  final int count;

  const CountCommand(this.count);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final EditBuilder edit = f.edit;
    if (edit.count == null && count == 0) {
      edit.motion = Motion(.lineStart, linewise: true);
      e.commitEdit(edit.build());
    } else {
      edit.count = (edit.count ?? 0) * 10 + count;
      e.showMessage(.info('count: ${edit.count}'));
    }
  }
}

/// Command that executes a motion.
class MotionCommand extends Command {
  final Motion motion;

  const MotionCommand(this.motion);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.edit.motion = motion;
    e.commitEdit(f.edit.build());
  }
}

/// Command that starts an operator (d, c, y, etc.).
class OperatorCommand extends Command {
  final OperatorFunction func;

  const OperatorCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    // If there are visual selections, operate on them immediately
    if (Operators.handleVisualSelections(e, f, func)) {
      return;
    }
    // Otherwise, enter operator-pending mode to wait for a motion
    f.setMode(e, .operatorPending);
    f.edit.op = func;
  }
}

/// Command that handles repeated operator (dd, yy, cc).
/// Applies the operator to the current line.
class OperatorPendingSameCommand extends OperatorCommand {
  const OperatorPendingSameCommand(super.func);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    if (f.edit.op == func) {
      f.edit.motion = Motion(.linewise, linewise: true);
      e.commitEdit(f.edit.build());
    } else {
      f.setMode(e, .normal);
      f.edit.reset();
    }
  }
}

/// Command that cancels operator-pending mode.
class OperatorEscapeCommand extends Command {
  const OperatorEscapeCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.setMode(e, .normal);
    f.edit.reset();
  }
}

/// Command that executes a line edit command with parsed arguments.
class LineEditCommand extends Command {
  final void Function(Editor, FileBuffer, List<String>) action;

  const LineEditCommand(this.action);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final String command = f.input.lineEdit;
    List<String> args = command.split(' ');
    action(e, f, args);
    f.input.lineEdit = '';
  }
}

/// Command for text objects (i(, a{, iw, etc.) used in operator-pending mode.
/// Returns a Range for the operator to act on.
class TextObjectCommand extends Command {
  final TextObjectFunction func;

  const TextObjectCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    // Text objects only work in operator-pending mode
    if (f.mode != .operatorPending) return;

    final op = f.edit.op;
    if (op == null) {
      f.setMode(e, .normal);
      f.edit.reset();
      return;
    }

    // Get the range from the text object
    final range = func(e, f, f.cursor);

    // If range is empty (no match found), cancel
    if (range.start == range.end) {
      f.setMode(e, .normal);
      f.edit.reset();
      return;
    }

    // Apply count by expanding range (for text objects, count usually means
    // include more levels of nesting, but for simplicity we just apply once)
    // TODO: Support count for nested brackets

    // Execute the operator on the range
    op(e, f, range.norm, linewise: false);
    f.edit.reset();
  }
}
