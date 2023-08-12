import 'command.dart';
import 'line.dart';
import 'modes.dart';
import 'position.dart';
import 'undo.dart';

// all things related to the file buffer
class FileBuffer {
  // the path to the file
  String? path;

  // the text of the file
  var text = '';

  // text split by '\n' character, created by createLines when text is changed
  var lines = [Line.empty];

  // the cursor position (0 based, in grapheme cluster space)
  var cursor = Position();

  // the view offset (0 based, in grapheme cluster space)
  var view = Position();

  // the current mode
  var mode = Mode.normal;

  // the pending action to be executed
  OperatorAction? operator;

  // find action
  FindAction? find;

  // the accumulated text input
  var input = '';

  // the previous input for the operator (used for linewise operator)
  var prevOperatorInput = '';

  // the accumulated count input
  var countInput = '';

  // the count of the pending action
  int? count;

  // the register to use for the pending action
  String? yankBuffer;

  // if the file has been modified and not saved
  bool isModified = false;

  // list of undo operations
  List<Undo> undoList = [];
}
