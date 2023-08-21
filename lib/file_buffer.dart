import 'action_typedefs.dart';
import 'line.dart';
import 'modes.dart';
import 'position.dart';
import 'undo.dart';

class Action {
  // the pending action to be executed
  OperatorAction? operator;

  // the accumulated text input
  String input = '';

  // the pending operator input
  String operatorInput = '';

  // the accumulated count input
  String countInput = '';

  // the count of the pending action
  int? count;

  // the pending find action
  String? findChar;

  // if the pending operator is linewise
  bool operatorLineWise = false;
}

// all things related to the file buffer
class FileBuffer {
  // the path to the file
  String? path;

  // the text of the file
  String text = '';

  // text split by '\n' character, created by createLines when text is changed
  List<Line> lines = [];

  // the cursor position (0 based, in grapheme cluster space)
  Position cursor = Position();

  // the view offset (0 based, in grapheme cluster space)
  Position view = Position();

  // the current mode
  Mode mode = Mode.normal;

  // the current action to be executed
  Action action = Action();

  // the previous action
  Action? prevAction;

  // the register to use for the pending action
  String? yankBuffer;

  // if the file has been modified and not saved
  bool isModified = false;

  // list of undo operations
  List<Undo> undoList = [];
}
