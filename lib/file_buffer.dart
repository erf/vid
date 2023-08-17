import 'action_typedefs.dart';
import 'line.dart';
import 'modes.dart';
import 'position.dart';
import 'undo.dart';

// all things related to the file buffer
class FileBuffer {
  // the path to the file
  String? path;

  // the text of the file
  String text = '';

  // text split by '\n' character, created by createLines when text is changed
  List<Line> lines = [Line.empty];

  // the cursor position (0 based, in grapheme cluster space)
  Position cursor = Position();

  // the view offset (0 based, in grapheme cluster space)
  Position view = Position();

  // the current mode
  Mode mode = Mode.normal;

  // the pending action to be executed
  OperatorAction? operator;

  // the accumulated text input
  String input = '';

  // the accumulated count input
  String countInput = '';

  // the count of the pending action
  int? count;

  // the register to use for the pending action
  String? yankBuffer;

  // if the file has been modified and not saved
  bool isModified = false;

  // list of undo operations
  List<Undo> undoList = [];

  // the previous input for the operator (used for linewise operator)
  String prevOperatorInput = '';

  // if the previous operator was linewise (used for paste)
  bool prevOperatorLinewise = false;

  // the previous action char (used for dot command)
  String? prevOperatorActionInput;

  // the previous count (used for dot command)
  int? prevCount;

  // the previous find action char (used for dot command)
  String? prevFindNextChar;
}
