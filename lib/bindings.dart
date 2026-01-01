import 'package:termio/termio.dart';

import 'actions/insert_actions.dart';
import 'actions/line_edit.dart';
import 'actions/motions.dart';
import 'actions/normal.dart';
import 'actions/operators.dart';
import 'actions/replace_actions.dart';
import 'commands/command.dart';
import 'modes.dart';

enum KeyMatch { none, partial, match }

/// Bindings for a mode, with an optional fallback command for unmatched keys.
class ModeBindings<T> {
  final Map<String, T> bindings;
  final T? fallback;

  const ModeBindings(this.bindings, {this.fallback});

  /// Check if [input] is a key in bindings or if it's the start of a key.
  /// Falls back to [fallback] if no match is found.
  (KeyMatch, T?) match(String input) {
    // is input a key in map?
    if (bindings.containsKey(input)) {
      return (.match, bindings[input]);
    }

    // check if we have a fallback command
    if (fallback != null) {
      return (.match, fallback);
    }

    // check if input is the start of a key in map
    for (var key in bindings.keys) {
      if (key.startsWith(input)) {
        return (.partial, null);
      }
    }

    // no match found
    return (.none, null);
  }
}

const normalCommands = <String, Command>{
  'q': ActionCommand(Normal.quit),
  'S': AliasCommand('^C'),
  's': ActionCommand(Normal.save),
  'i': ModeCommand(.insert),
  'a': ActionCommand(Normal.appendCharNext),
  'A': AliasCommand('\$a'),
  'I': AliasCommand('^i'),
  'o': AliasCommand('A\n'),
  'O': AliasCommand('^i\n${Keys.escape}ki'),
  'r': ModeCommand(.replace),
  'D': AliasCommand('d\$'),
  'x': AliasCommand('dl'),
  'p': ActionCommand(Normal.pasteAfter),
  'P': ActionCommand(Normal.pasteBefore),
  Keys.ctrlD: ActionCommand(Normal.moveDownHalfPage),
  Keys.ctrlU: ActionCommand(Normal.moveUpHalfPage),
  'J': ActionCommand(Normal.joinLines),
  'C': AliasCommand('c\$'),
  'u': ActionCommand(Normal.undo),
  'U': ActionCommand(Normal.redo),
  '.': ActionCommand(Normal.repeat),
  ';': ActionCommand(Normal.repeatFindStr),
  'n': ActionCommand(Normal.repeatFindStr),
  Keys.ctrlA: ActionCommand(Normal.increase),
  Keys.ctrlX: ActionCommand(Normal.decrease),
  ':': ModeCommand(.command),
  '/': ModeCommand(.search),
  Keys.ctrlW: ActionCommand(Normal.toggleWrap),
  'zz': ActionCommand(Normal.centerView),
  'zh': ActionCommand(Normal.toggleSyntax),
  'zt': ActionCommand(Normal.cycleTheme),
};

const insertBindings = <String, Command>{
  Keys.backspace: ActionCommand(InsertActions.backspace),
  Keys.newline: ActionCommand(InsertActions.enter),
  Keys.escape: ActionCommand(InsertActions.escape),
};
const insertFallback = InputCommand(InsertActions.insert);

const replaceBindings = <String, Command>{};
const replaceFallback = InputCommand(ReplaceActions.replace);

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

final motionCommands = <String, Command>{
  'h': MotionCommand.fn(Motions.charPrev),
  'l': MotionCommand.fn(Motions.charNext),
  ' ': MotionCommand.fn(Motions.charNext),
  'k': MotionCommand.fn(Motions.lineUp, inclusive: true, linewise: true),
  'j': MotionCommand.fn(Motions.lineDown, inclusive: true, linewise: true),
  'w': MotionCommand.fn(Motions.wordNext),
  'W': MotionCommand.fn(Motions.wordCapNext),
  'b': MotionCommand.fn(Motions.wordPrev),
  'B': MotionCommand.fn(Motions.wordCapPrev),
  'e': MotionCommand.fn(Motions.wordEnd, inclusive: true),
  'ge': MotionCommand.fn(Motions.wordEndPrev),
  '#': MotionCommand.fn(Motions.sameWordPrev),
  '*': MotionCommand.fn(Motions.sameWordNext),
  '^': MotionCommand.fn(Motions.firstNonBlank, linewise: true),
  '\$': MotionCommand.fn(Motions.lineEnd, inclusive: true),
  'gg': MotionCommand.fn(Motions.fileStart, inclusive: true, linewise: true),
  'G': MotionCommand.fn(Motions.fileEnd, inclusive: true, linewise: true),
  'f': MotionCommand.fn(Motions.findNextChar, inclusive: true),
  'F': MotionCommand.fn(Motions.findPrevChar),
  't': MotionCommand.fn(Motions.findTillNextChar),
  'T': MotionCommand.fn(Motions.findTillPrevChar),
  '{': MotionCommand.fn(Motions.paragraphPrev),
  '}': MotionCommand.fn(Motions.paragraphNext),
  '(': MotionCommand.fn(Motions.sentencePrev),
  ')': MotionCommand.fn(Motions.sentenceNext),
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

const lineEditCommands = <String, LineEditCommand>{
  '': LineEditCommand(LineEdit.noop),
  'q': LineEditCommand(LineEdit.quit),
  'quit': LineEditCommand(LineEdit.quit),
  'q!': LineEditCommand(LineEdit.forceQuit),
  'quit!': LineEditCommand(LineEdit.forceQuit),
  'o': LineEditCommand(LineEdit.open),
  'open': LineEditCommand(LineEdit.open),
  'e': LineEditCommand(LineEdit.open),
  'edit': LineEditCommand(LineEdit.open),
  'r': LineEditCommand(LineEdit.read),
  'read': LineEditCommand(LineEdit.read),
  'w': LineEditCommand(LineEdit.write),
  'write': LineEditCommand(LineEdit.write),
  'wq': LineEditCommand(LineEdit.writeAndQuit),
  'x': LineEditCommand(LineEdit.writeAndQuit),
  'exit': LineEditCommand(LineEdit.writeAndQuit),
  'nowrap': LineEditCommand(LineEdit.setNoWrap),
  'charwrap': LineEditCommand(LineEdit.setCharWrap),
  'wordwrap': LineEditCommand(LineEdit.setWordWrap),
  // Buffer commands
  'bn': LineEditCommand(BufferCommands.nextBuffer),
  'bnext': LineEditCommand(BufferCommands.nextBuffer),
  'bp': LineEditCommand(BufferCommands.prevBuffer),
  'bprev': LineEditCommand(BufferCommands.prevBuffer),
  'bprevious': LineEditCommand(BufferCommands.prevBuffer),
  'b': LineEditCommand(BufferCommands.switchToBuffer),
  'buffer': LineEditCommand(BufferCommands.switchToBuffer),
  'bd': LineEditCommand(BufferCommands.closeBuffer),
  'bdelete': LineEditCommand(BufferCommands.closeBuffer),
  'bd!': LineEditCommand(BufferCommands.forceCloseBuffer),
  'bdelete!': LineEditCommand(BufferCommands.forceCloseBuffer),
  'ls': LineEditCommand(BufferCommands.listBuffers),
  'buffers': LineEditCommand(BufferCommands.listBuffers),
};

const lineEditInputBindings = <String, Command>{
  Keys.escape: ModeCommand(.normal),
  Keys.backspace: ActionCommand(LineEditInput.backspace),
  Keys.newline: ActionCommand(LineEditInput.executeCommand),
};
const lineEditInputFallback = InputCommand(LineEditInput.input);

const lineEditSearchBindings = <String, Command>{
  Keys.escape: ModeCommand(.normal),
  Keys.backspace: ActionCommand(LineEditInput.backspace),
  Keys.newline: ActionCommand(LineEditInput.executeSearch),
};
const lineEditSearchFallback = InputCommand(LineEditInput.input);

final keyBindings = <Mode, ModeBindings<Command>>{
  .normal: ModeBindings({
    ...countCommands,
    ...normalCommands,
    ...motionCommands,
    ...operatorCommands,
  }),
  .operatorPending: ModeBindings({
    Keys.escape: OperatorEscapeCommand(),
    ...countCommands,
    ...motionCommands,
    ...operatorPendingSameCommands,
  }),
  .insert: ModeBindings(insertBindings, fallback: insertFallback),
  .replace: ModeBindings(replaceBindings, fallback: replaceFallback),
  .command: ModeBindings(
    lineEditInputBindings,
    fallback: lineEditInputFallback,
  ),
  .search: ModeBindings(
    lineEditSearchBindings,
    fallback: lineEditSearchFallback,
  ),
};
