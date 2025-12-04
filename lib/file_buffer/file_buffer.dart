import '../edit.dart';
import '../modes.dart';
import '../text_op.dart';

// all things related to the file buffer
class FileBuffer {
  // create a new file buffer
  FileBuffer({String text = '\n', this.path, this.absolutePath})
    : _text = text {
    _buildLineIndex();
  }

  // --- Fields ---

  // the text of the file (use setter to rebuild line index)
  String _text;

  // cached line start offsets: _lineOffsets[i] = byte offset where line i starts
  final List<int> _lineOffsets = [];

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

  // --- Getters/Setters ---

  String get text => _text;

  set text(String value) {
    _text = value;
    _buildLineIndex();
  }

  // total number of lines
  int get totalLines => _lineOffsets.isNotEmpty ? _lineOffsets.length - 1 : 1;

  // if the file has been modified (not saved)
  bool get modified => undoList.length != savepoint;

  // --- Methods ---

  // build line index by scanning for newlines - O(n)
  void _buildLineIndex() {
    _lineOffsets.clear();
    _lineOffsets.add(0); // line 0 starts at offset 0
    for (int i = 0; i < _text.length; i++) {
      if (_text[i] == '\n') {
        _lineOffsets.add(i + 1); // next line starts after the newline
      }
    }
  }

  // update text with incremental line index update - faster than full rebuild
  void updateText(int start, int end, String newText) {
    final String oldText = _text.substring(start, end);
    final int delta = newText.length - oldText.length;

    // count newlines removed and added
    int newlinesRemoved = 0;
    for (int i = 0; i < oldText.length; i++) {
      if (oldText[i] == '\n') newlinesRemoved++;
    }
    int newlinesAdded = 0;
    for (int i = 0; i < newText.length; i++) {
      if (newText[i] == '\n') newlinesAdded++;
    }

    // update the text
    _text = _text.replaceRange(start, end, newText);

    // find which line the edit starts on
    int startLine = lineNumberFromOffset(start);

    // remove line offsets for deleted newlines
    if (newlinesRemoved > 0) {
      _lineOffsets.removeRange(startLine + 1, startLine + 1 + newlinesRemoved);
    }

    // insert line offsets for added newlines
    if (newlinesAdded > 0) {
      List<int> newOffsets = [];
      int pos = start;
      for (int i = 0; i < newText.length; i++) {
        if (newText[i] == '\n') {
          newOffsets.add(pos + i + 1);
        }
      }
      _lineOffsets.insertAll(startLine + 1, newOffsets);
    }

    // shift all offsets after the edit point by delta
    if (delta != 0) {
      int firstLineToShift = startLine + 1 + newlinesAdded;
      for (int i = firstLineToShift; i < _lineOffsets.length; i++) {
        _lineOffsets[i] += delta;
      }
    }
  }

  // get line number for offset using binary search - O(log n)
  int lineNumberFromOffset(int offset) {
    int low = 0;
    int high = _lineOffsets.length - 1;
    while (low < high) {
      int mid = (low + high + 1) ~/ 2;
      if (_lineOffsets[mid] <= offset) {
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
    if (lineNum >= _lineOffsets.length) return _text.length;
    return _lineOffsets[lineNum];
  }

  // set if the file has been modified
  void setSavepoint() => savepoint = undoList.length;
}
