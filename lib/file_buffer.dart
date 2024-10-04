import 'edit.dart';
import 'line.dart';
import 'modes.dart';
import 'position.dart';
import 'text_op.dart';

// all things related to the file buffer
class FileBuffer {
  // the text of the file
  String text;

  // the path to the file
  String? path;

  // create a new file buffer
  FileBuffer({this.text = '', this.path});

  // the lines of the file with metadata, built by createLines() on text changes
  List<Line> lines = [];

  // the cursor position (0 based, in grapheme cluster space)
  Position cursor = Position();

  // the view offset (0 based, in grapheme cluster space)
  Position view = Position();

  // the current mode
  Mode mode = Mode.normal;

  // the current edit
  EditOp editOp = EditOp();

  // the previous edit
  EditOp? prevEditOp;

  // the yanked text
  String? yankBuffer;

  // list of undo operations
  List<TextOp> undoList = [];

  // list of redo operations
  List<TextOp> redoList = [];

  // the savepoint for undo operations
  int savepoint = 0;

  // if the file has been modified (not saved)
  bool get modified => undoList.length != savepoint;

  // set if the file has been modified
  void setSavepoint() => savepoint = undoList.length;
}
