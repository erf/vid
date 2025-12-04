import '../edit.dart';
import '../modes.dart';
import '../text_op.dart';

// all things related to the file buffer
class FileBuffer {
  // create a new file buffer
  FileBuffer({this.text = '\n', this.path, this.absolutePath});

  // the text of the file
  String text;

  // the path to the file
  String? path;

  // the absolute path to the file
  String? absolutePath;

  // the cursor position (byte offset, always at grapheme cluster boundary)
  int cursor = 0;

  // the viewport position (byte offset of first visible character)
  int viewport = 0;

  // the current mode
  Mode mode = .normal;

  // the current edit action
  Edit edit = Edit();

  // the previous edit operation
  Edit? prevEdit;

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
