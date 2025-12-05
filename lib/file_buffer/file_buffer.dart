import '../edit.dart';
import '../keys.dart';
import '../line_info.dart';
import '../modes.dart';
import '../text_op.dart';

// all things related to the file buffer
class FileBuffer {
  // create a new file buffer
  FileBuffer({String text = Keys.newline, this.path, this.absolutePath})
    : _text = text {
    _buildLineIndex();
  }

  // --- Fields ---

  // the text of the file (use setter to rebuild line index)
  String _text;

  // line metadata: lines[i] contains start/end offsets for line i
  final List<LineInfo> lines = [];

  // the path to the file
  String? path;

  // the absolute path to the file
  String? absolutePath;

  // the cursor position (byte offset, always at grapheme cluster boundary)
  int cursor = 0;

  // the line number the cursor is on (0-based)
  int cursorLine = 0;

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

  // --- Getters/Setters ---

  String get text => _text;

  set text(String value) {
    _text = value;
    _buildLineIndex();
  }

  // total number of lines
  int get totalLines => lines.length;

  // if the file has been modified (not saved)
  bool get modified => undoList.length != savepoint;

  // --- Methods ---

  // build line index by scanning for newlines - O(n)
  void _buildLineIndex() {
    lines.clear();
    int start = 0;
    int idx = _text.indexOf(Keys.newline);
    while (idx != -1) {
      lines.add(LineInfo(start, idx));
      start = idx + 1;
      idx = _text.indexOf(Keys.newline, start);
    }
    // Handle text without trailing newline (shouldn't happen, but be safe)
    if (start < _text.length) {
      lines.add(LineInfo(start, _text.length));
    }
  }

  // update text and rebuild line index
  void updateText(int start, int end, String newText) {
    _text = _text.replaceRange(start, end, newText);
    _buildLineIndex();
    cursorLine = lineNumberFromOffset(cursor);
  }

  // get line number for offset using binary search - O(log n)
  int lineNumberFromOffset(int offset) {
    if (lines.isEmpty) return 0;
    int low = 0;
    int high = lines.length - 1;
    while (low < high) {
      int mid = (low + high + 1) ~/ 2;
      if (lines[mid].start <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  // get byte offset for line number - O(1)
  int offsetFromLineNumber(int lineNum) {
    if (lineNum < 0) return 0;
    if (lineNum >= lines.length) return _text.length;
    return lines[lineNum].start;
  }

  // set if the file has been modified
  void setSavepoint() => savepoint = undoList.length;
}
