import 'package:characters/characters.dart';

import 'modes.dart';
import 'position.dart';
import 'undo.dart';

// all things related to the file buffer
class FileBuffer {
  // the path to the file
  String? path;

  // the text of the file
  String text = '';

  // the lines of the file, generated from the text based on '\n' characters, with the last line always being empty
  // when text changes, lines is recreated by calling updateLines()
  var lines = [Characters.empty];

  // the current cursor position (0 based, in human-readable symbol space as opposed to byte space)
  var cursor = Position();

  // the view offset in the file (0 based, in human-readable symbol space as opposed to byte space)
  var view = Position();

  // the current mode
  var mode = Mode.normal;

  // the pending action to be executed
  Function? pendingAction;

  // the count of the pending action
  int? count;

  // the register to use for the pending action
  String? yankBuffer;

  // if the file has been modified and not saved
  bool isModified = false;

  // list of undo operations
  List<UndoOp> undoList = [];
}
