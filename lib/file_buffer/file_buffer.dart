// Barrel file - exports all file_buffer extensions
import 'package:termio/termio.dart';
import 'package:vid/edit_builder.dart';
import 'package:vid/edit_operation.dart';
import 'package:vid/input_state.dart';
import 'package:vid/selection.dart';

import '../line_info.dart';
import '../modes.dart';
import '../text_op.dart';
import '../error_or.dart';
import 'file_buffer_io.dart';

export 'file_buffer_edits.dart';
export 'file_buffer_io.dart';
export 'file_buffer_nav.dart';
export 'file_buffer_text.dart';

/// Callback for text changes in a [FileBuffer].
typedef TextChangeListener =
    void Function(
      FileBuffer buffer,
      int start,
      int end,
      String newText,
      String oldText,
    );

/// A file buffer that maintains text with a trailing newline invariant.
///
/// The [text] field always ends with a newline character. This invariant
/// is enforced by [FileBufferIo.load] on file read and [FileBufferText.replace]
/// on text modifications.
class FileBuffer {
  // create a new file buffer
  FileBuffer({
    String text = Keys.newline,
    this.path,
    this.absolutePath,
    this.cwd,
  }) : _text = text {
    assert(text.endsWith(Keys.newline), 'Text must end with newline');
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

  // the current working directory (for relativePath calculation)
  String? cwd;

  /// Get the path relative to current working directory.
  /// Returns null if no path is set, or the absolute path if outside cwd.
  String? get relativePath {
    final abs = absolutePath;
    if (abs == null) return null;
    final workingDir = cwd;
    if (workingDir != null && abs.startsWith(workingDir)) {
      final rel = abs.substring(workingDir.length);
      return rel.startsWith('/') ? rel.substring(1) : rel;
    }
    return abs;
  }

  // list of selections (always at least one; first is "main" selection)
  List<Selection> selections = [Selection.collapsed(0)];

  // the cursor position (byte offset, always at grapheme cluster boundary)
  // This is a convenience getter/setter for the primary cursor.
  int get cursor => selections.first.cursor;
  set cursor(int value) {
    // Only update the first selection's cursor position
    selections[0] = selections.first.isCollapsed
        ? Selection.collapsed(value)
        : selections.first.withCursor(value);
  }

  // whether we have multiple cursors (collapsed selections)
  bool get hasMultipleCursors =>
      selections.length > 1 && selections.every((s) => s.isCollapsed);

  /// Collapse all selections to their cursor positions (multi-cursor mode).
  void collapseSelections() {
    selections = selections.map((s) => s.collapse()).toList();
  }

  /// Collapse to single cursor at first selection's cursor.
  void collapseToPrimaryCursor() {
    selections = [Selection.collapsed(selections.first.cursor)];
  }

  // the main selection (first in list)
  Selection get selection => selections.first;
  set selection(Selection value) => selections[0] = value;

  // whether we have multiple selections active
  bool get hasMultipleSelections => selections.length > 1;

  // whether any selection is non-collapsed (visual selection)
  bool get hasVisualSelection => selections.any((s) => !s.isCollapsed);

  // the viewport position (byte offset of first visible character)
  int viewport = 0;

  // the current mode
  Mode mode = .normal;

  // the current edit builder (accumulates input)
  EditBuilder edit = EditBuilder();

  // input state for command matching
  InputState input = InputState();

  // the previous edit operation (for repeat)
  EditOperation? prevEdit;

  // list of undo operations (each entry is a group of TextOps)
  List<List<TextOp>> undoList = [];

  // list of redo operations (each entry is a group of TextOps)
  List<List<TextOp>> redoList = [];

  // the savepoint for undo operations
  int savepoint = 0;

  // listeners for text changes
  final List<TextChangeListener> _listeners = [];

  void addListener(TextChangeListener listener) => _listeners.add(listener);

  // --- Getters/Setters ---

  String get text => _text;

  set text(String value) {
    assert(value.endsWith(Keys.newline), 'Text must end with newline');
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

  // update text and partially rebuild line index from edit point
  void updateText(int start, int end, String newText) {
    // Find line containing start offset before modifying text
    final startLine = lineNumber(start);

    // Capture old text before modification for LSP sync
    final oldText = _text.substring(start, end);

    _text = _text.replaceRange(start, end, newText);

    // Truncate lines list and rebuild only from edit point
    lines.length = startLine;
    int scanFrom = (startLine > 0) ? lines[startLine - 1].end + 1 : 0;

    int idx = _text.indexOf(Keys.newline, scanFrom);
    while (idx != -1) {
      lines.add(LineInfo(scanFrom, idx));
      scanFrom = idx + 1;
      idx = _text.indexOf(Keys.newline, scanFrom);
    }

    // Notify listeners of text change
    for (final listener in _listeners) {
      listener(this, start, end, newText, oldText);
    }
  }

  // get line number for offset using binary search - O(log n)
  int lineNumber(int offset) {
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
  int lineOffset(int lineNum) {
    if (lineNum < 0) return 0;
    if (lineNum >= lines.length) return _text.length;
    return lines[lineNum].start;
  }

  // set if the file has been modified
  void setSavepoint() => savepoint = undoList.length;

  /// Load a file from disk.
  static ErrorOr<FileBuffer> load(
    String path, {
    bool createIfNotExists = false,
    String? cwd,
  }) {
    return FileBufferIo.load(
      path,
      createIfNotExists: createIfNotExists,
      cwd: cwd,
    );
  }
}
