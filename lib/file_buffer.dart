import 'edit_event.dart';
import 'line.dart';
import 'modes.dart';
import 'motion.dart';
import 'position.dart';
import 'undo.dart';

// all things related to the file buffer
class FileBuffer {
  // the path to the file
  String? path;

  // the text of the file
  String text = '';

  // the lines of the file with metadata, built by createLines() on text changes
  List<Line> lines = [];

  // the cursor position (0 based, in grapheme cluster space)
  Position cursor = Position();

  // the view offset (0 based, in grapheme cluster space)
  Position view = Position();

  // the current mode
  Mode mode = Mode.normal;

  // the current action to be executed
  EditEvent editEvent = EditEvent();

  // the previous operator action
  EditEvent? prevEditEvent;

  // the previous find action
  Motion<Function>? prevMotion;

  // the previous find character
  String? prevFindStr;

  // the yanked text
  String? yankBuffer;

  // list of undo operations
  List<Undo> undoList = [];

  // list of redo operations
  List<Undo> redoList = [];

  // the savepoint for undo operations
  int savepoint = 0;

  // if the file has been modified (not saved)
  bool get modified => undoList.length != savepoint;

  // set if the file has been modified
  void setSavepoint() => savepoint = undoList.length;
}
