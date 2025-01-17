import 'package:vid/edit_op.dart';
import 'package:vid/actions_insert.dart';
import 'package:vid/actions_motions.dart';
import 'package:vid/actions_replace.dart';
import 'package:vid/file_buffer_mode.dart';
import 'package:vid/modes.dart';

import 'editor.dart';
import 'file_buffer.dart';

class Motion {
  final Function func;
  final bool linewise;
  final bool? incl;
  const Motion(this.func, {this.linewise = false, this.incl});
}

class FindMotion extends Motion {
  FindMotion(super.func);
}

abstract class Command {
  const Command();

  void execute(Editor e, FileBuffer f) {}
}

class NormalCommand extends Command {
  final Function func;

  const NormalCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f) => func(e, f);
}

class OperatorCommand extends Command {
  final Function func;

  const OperatorCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f) {
    f.setMode(e, Mode.operatorPending);
    f.edit.op = func;
  }
}

class SameOperatorCommand extends Command {
  final Function func;

  const SameOperatorCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f) {
    if (f.edit.op == func) {
      f.edit.linewise = true;
      f.edit.motion = Motion(Motions.lineStart, linewise: true);
      e.commitEdit(f.edit);
      f.cursor = Motions.lineStart(f, f.cursor, true);
    } else {
      f.setMode(e, Mode.normal);
      f.edit = EditOp();
    }
  }
}

class MotionCommand extends Command {
  final Motion motion;

  const MotionCommand(this.motion);

  @override
  void execute(Editor e, FileBuffer f) {
    f.edit.motion = motion;
    e.commitEdit(f.edit);
  }
}

class DefaultInsertCommand extends Command {
  const DefaultInsertCommand();

  @override
  void execute(Editor e, FileBuffer f) {
    final String char = f.edit.input;
    InsertActions.defaultInsert(e, f, char);
  }
}

class BackspaceInsertCommand extends Command {
  const BackspaceInsertCommand();

  @override
  void execute(Editor e, FileBuffer f) {
    InsertActions.backspace(e, f);
  }
}

class EnterInsertCommand extends Command {
  const EnterInsertCommand();

  @override
  void execute(Editor e, FileBuffer f) {
    InsertActions.enter(e, f);
  }
}

class EscapeInsertCommand extends Command {
  const EscapeInsertCommand();

  @override
  void execute(Editor e, FileBuffer f) {
    InsertActions.escape(e, f);
  }
}

class DefaultReplaceCommand extends Command {
  const DefaultReplaceCommand();

  @override
  void execute(Editor e, FileBuffer f) {
    final String char = f.edit.input;
    ReplaceActions.defaultReplace(e, f, char);
  }
}
