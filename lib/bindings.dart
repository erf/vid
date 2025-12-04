import 'package:vid/commands/alias_command.dart';
import 'package:vid/commands/mode_command.dart';
import 'package:vid/motions/char_next_motion.dart';
import 'package:vid/motions/char_prev_motion.dart';
import 'package:vid/motions/file_end_motion.dart';
import 'package:vid/motions/find_next_char_motion.dart';
import 'package:vid/motions/find_prev_char_motion.dart';
import 'package:vid/motions/first_non_blank_motion.dart';
import 'package:vid/motions/line_down_motion.dart';
import 'package:vid/motions/line_end_motion.dart';
import 'package:vid/motions/line_up_motion.dart';
import 'package:vid/motions/paragraph_next_motion.dart';
import 'package:vid/motions/paragraph_prev_motion.dart';
import 'package:vid/motions/same_word_next_motion.dart';
import 'package:vid/motions/same_word_prev_motion.dart';
import 'package:vid/motions/sentence_next_motion.dart';
import 'package:vid/motions/sentence_prev_motion.dart';
import 'package:vid/motions/word_end_motion.dart';
import 'package:vid/motions/word_end_prev_motion.dart';
import 'package:vid/motions/word_prev_motion.dart';

import 'actions/line_edit.dart';
import 'actions/normal.dart';
import 'actions/operators.dart';
import 'commands/command.dart';
import 'commands/count_command.dart';
import 'commands/insert_backspace_command.dart';
import 'commands/insert_default_command.dart';
import 'commands/insert_enter_command.dart';
import 'commands/insert_escape_command.dart';
import 'commands/line_edit_delete_command.dart';
import 'commands/line_edit_enter_command.dart';
import 'commands/line_edit_input_command.dart';
import 'commands/line_edit_search_command.dart';
import 'commands/motion_command.dart';
import 'commands/normal_command.dart';
import 'commands/operator_command.dart';
import 'commands/operator_escape_command.dart';
import 'commands/operator_pending_same_command.dart';
import 'commands/replace_default_command.dart';
import 'keys.dart';
import 'modes.dart';
import 'motions/file_start_motion.dart';
import 'motions/find_till_next_char_motion.dart';
import 'motions/find_till_prev_char_motion.dart';
import 'motions/word_cap_next_motion.dart';
import 'motions/word_cap_prev_motion.dart';
import 'motions/word_next_motion.dart';

const normalCommands = <String, Command>{
  'q': NormalCommand(Normal.quit),
  'S': AliasCommand('^C'),
  's': NormalCommand(Normal.save),
  'i': ModeCommand(.insert),
  'a': NormalCommand(Normal.appendCharNext),
  'A': AliasCommand('\$a'),
  'I': AliasCommand('^i'),
  'o': AliasCommand('A\n'),
  'O': AliasCommand('^i\n${Keys.escape}ki'),
  'r': ModeCommand(.replace),
  'D': AliasCommand('d\$'),
  'x': AliasCommand('dl'),
  'p': NormalCommand(Normal.pasteAfter),
  'P': NormalCommand(Normal.pasteBefore),
  Keys.ctrlD: NormalCommand(Normal.moveDownHalfPage),
  Keys.ctrlU: NormalCommand(Normal.moveUpHalfPage),
  'J': NormalCommand(Normal.joinLines),
  'C': AliasCommand('c\$'),
  'u': NormalCommand(Normal.undo),
  'U': NormalCommand(Normal.redo),
  '.': NormalCommand(Normal.repeat),
  ';': NormalCommand(Normal.repeatFindStr),
  'n': NormalCommand(Normal.repeatFindStr),
  Keys.ctrlA: NormalCommand(Normal.increase),
  Keys.ctrlX: NormalCommand(Normal.decrease),
  ':': ModeCommand(.command),
  '/': ModeCommand(.search),
  Keys.ctrlW: NormalCommand(Normal.toggleWrap),
  'zz': NormalCommand(Normal.centerView),
};

const insertCommands = <String, Command>{
  Keys.backspace: InsertBackspaceCommand(),
  Keys.newline: InsertEnterCommand(),
  Keys.escape: InsertEscapeCommand(),
  '[*]': InsertDefaultCommand(),
};

const replaceCommands = <String, Command>{'[*]': ReplaceDefaultCommand()};

const countCommands = <String, Command>{
  '0': CountCommand(0),
  '1': CountCommand(1),
  '2': CountCommand(2),
  '3': CountCommand(3),
  '4': CountCommand(4),
  '5': CountCommand(5),
  '6': CountCommand(6),
  '7': CountCommand(7),
  '8': CountCommand(8),
  '9': CountCommand(9),
};

const motionCommands = <String, Command>{
  'h': MotionCommand(CharPrevMotion()),
  'l': MotionCommand(CharNextMotion()),
  ' ': MotionCommand(CharNextMotion()),
  'k': MotionCommand(LineUpMotion()),
  'j': MotionCommand(LineDownMotion()),
  'w': MotionCommand(WordNextMotion()),
  'W': MotionCommand(WordCapNextMotion()),
  'b': MotionCommand(WordPrevMotion()),
  'B': MotionCommand(WordCapPrevMotion()),
  'e': MotionCommand(WordEndMotion()),
  'ge': MotionCommand(WordEndPrevMotion()),
  '#': MotionCommand(SameWordPrevMotion()),
  '*': MotionCommand(SameWordNextMotion()),
  '^': MotionCommand(FirstNonBlankMotion()),
  '\$': MotionCommand(LineEndMotion(inclusive: true)),
  'gg': MotionCommand(FileStartMotion()),
  'G': MotionCommand(FileEndMotion()),
  'f': MotionCommand(FindNextCharMotion()),
  'F': MotionCommand(FindPrevCharMotion()),
  't': MotionCommand(FindTillNextCharMotion()),
  'T': MotionCommand(FindTillPrevCharMotion()),
  '{': MotionCommand(ParagraphPrevMotion()),
  '}': MotionCommand(ParagraphNextMotion()),
  '(': MotionCommand(SentencePrevMotion()),
  ')': MotionCommand(SentenceNextMotion()),
};

const operatorCommands = <String, Command>{
  'c': OperatorCommand(Operators.change),
  'd': OperatorCommand(Operators.delete),
  'y': OperatorCommand(Operators.yank),
  'gu': OperatorCommand(Operators.lowerCase),
  'gU': OperatorCommand(Operators.upperCase),
};

const operatorPendingSameCommands = <String, Command>{
  'c': OperatorPendingSameCommand(Operators.change),
  'd': OperatorPendingSameCommand(Operators.delete),
  'y': OperatorPendingSameCommand(Operators.yank),
};

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

const lineEditInputCommands = <String, Command>{
  Keys.escape: ModeCommand(.normal),
  Keys.backspace: LineEditDeleteCommand(),
  Keys.newline: LineEditEnterCommand(),
  '[*]': LineEditInputCommand(),
};

const lineEditSearchCommands = <String, Command>{
  Keys.escape: ModeCommand(.normal),
  Keys.backspace: LineEditDeleteCommand(),
  Keys.newline: LineEditSearchCommand(),
  '[*]': LineEditInputCommand(),
};

const keyBindings = <Mode, Map<String, Command>>{
  .normal: {
    ...countCommands,
    ...normalCommands,
    ...motionCommands,
    ...operatorCommands,
  },
  .operatorPending: {
    Keys.escape: OperatorEscapeCommand(),
    ...countCommands,
    ...motionCommands,
    ...operatorPendingSameCommands,
  },
  .insert: insertCommands,
  .replace: replaceCommands,
  .command: lineEditInputCommands,
  .search: lineEditSearchCommands,
};
