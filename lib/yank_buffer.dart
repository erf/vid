/// Yank buffer with linewise information and multi-cursor support.
///
/// When yanking with multiple cursors, each selection is stored separately
/// in [pieces]. When pasting:
/// - With same number of cursors: each cursor gets its corresponding piece
/// - With fewer cursors: each cursor gets its corresponding piece (first N)
/// - With single cursor: gets all pieces joined
class YankBuffer {
  /// Individual pieces from each cursor/selection.
  final List<String> pieces;

  /// Whether this was a linewise yank (yy, dd, etc.)
  final bool linewise;

  /// All pieces joined together (for clipboard and single-cursor paste).
  String get text => pieces.join();

  /// Number of pieces in the buffer.
  int get length => pieces.length;

  const YankBuffer(this.pieces, {this.linewise = false});

  /// Create a single-piece yank buffer (backwards compatible).
  YankBuffer.single(String text, {this.linewise = false}) : pieces = [text];

  /// Get the text for a specific cursor index.
  /// Each cursor gets its corresponding piece by index.
  /// If index is out of range, returns all text joined.
  String textForCursor(int index, int totalCursors) {
    if (index < pieces.length) {
      return pieces[index];
    }
    // More cursors than pieces: extras get full text
    return text;
  }
}
