import 'package:vid/actions_find.dart';
import 'package:vid/actions_insert.dart';
import 'package:vid/actions_line_edit.dart';
import 'package:vid/actions_motions.dart';
import 'package:vid/actions_replace.dart';
import 'package:vid/edit_op.dart';
import 'package:vid/file_buffer_mode.dart';
import 'package:vid/message.dart';
import 'package:vid/modes.dart';
import 'package:vid/regex.dart';

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

  void execute(Editor e, FileBuffer f, String s) {}
}

class NormalCommand extends Command {
  final Function func;

  const NormalCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f, String s) => func(e, f);
}

class OperatorCommand extends Command {
  final Function func;

  const OperatorCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.setMode(e, Mode.operatorPending);
    f.edit.op = func;
  }
}

class SameOperatorCommand extends Command {
  final Function func;

  const SameOperatorCommand(this.func);

  @override
  void execute(Editor e, FileBuffer f, String s) {
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

class CountCommand extends Command {
  const CountCommand(this.count);

  final int count;

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final EditOp edit = f.edit;
    if (edit.count == null && count == 0) {
      f.edit.motion = Motion(Motions.lineStart);
      e.commitEdit(edit);
    } else {
      edit.count = (edit.count ?? 0) * 10 + count;
      e.showMessage(Message.info('count: ${edit.count}'));
    }
  }
}

class MotionCommand extends Command {
  final Motion motion;

  const MotionCommand(this.motion);

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.edit.motion = motion;
    e.commitEdit(f.edit);
  }
}

class DefaultInsertCommand extends Command {
  const DefaultInsertCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.defaultInsert(e, f, s);
  }
}

class BackspaceInsertCommand extends Command {
  const BackspaceInsertCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.backspace(e, f);
  }
}

class EnterInsertCommand extends Command {
  const EnterInsertCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.enter(e, f);
  }
}

class EscapeInsertCommand extends Command {
  const EscapeInsertCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    InsertActions.escape(e, f);
  }
}

class DefaultReplaceCommand extends Command {
  const DefaultReplaceCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    ReplaceActions.defaultReplace(e, f, s);
  }
}

const lineEditCommands = <String, Function>{
  '': LineEdit.noop,
  'q': LineEdit.quit,
  'quit': LineEdit.quit,
  'q!': LineEdit.forceQuit,
  'quit!': LineEdit.forceQuit,
  'o': LineEdit.open,
  'open': LineEdit.open,
  'r': LineEdit.read,
  'read': LineEdit.read,
  'w': LineEdit.write,
  'write': LineEdit.write,
  'wq': LineEdit.writeAndQuit,
  'x': LineEdit.writeAndQuit,
  'exit': LineEdit.writeAndQuit,
  'nowrap': LineEdit.setNoWrap,
  'charwrap': LineEdit.setCharWrap,
  'wordwrap': LineEdit.setWordWrap,
};

class LineEditInputCommand extends Command {
  @override
  void execute(Editor e, FileBuffer f, String s) {
    EditOp edit = f.edit;
    edit.lineEdit += s;
  }
}

class LineEditEnterCommand extends Command {
  const LineEditEnterCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final String command = f.edit.lineEdit;
    List<String> args = command.split(' ');
    String cmd = args.isNotEmpty ? args.first : command;
    // command actions
    if (lineEditCommands.containsKey(cmd)) {
      lineEditCommands[cmd]!(e, f, args);
      return;
    }
    // substitute command
    if (command.startsWith(Regex.substitute)) {
      LineEdit.substitute(e, f, [command]);
      return;
    }
    // unknown command
    f.edit.lineEdit = '';
    f.setMode(e, Mode.normal);
    e.showMessage(Message.error('Unknown command \'$command\''));
  }
}

class LineEditEscapeCommand extends Command {
  const LineEditEscapeCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.setMode(e, Mode.normal);
  }
}

class LineEditBackspaceCommand extends Command {
  const LineEditBackspaceCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final EditOp edit = f.edit;
    if (f.edit.input.isEmpty) {
      f.setMode(e, Mode.normal);
    } else {
      edit.input = edit.input.substring(0, edit.input.length - 1);
    }
  }
}

class LineEditSearchEnterCommand extends Command {
  const LineEditSearchEnterCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    final String pattern = f.edit.lineEdit;
    f.setMode(e, Mode.normal);
    f.edit.motion = FindMotion(FindActions.searchNext);
    f.edit.findStr = pattern;
    e.commitEdit(f.edit);
  }
}
