/// Lightweight line metadata for fast line-based operations
class LineInfo {
  int start; // byte offset of line start
  int end; // byte offset of \n (or text.length for last line)

  LineInfo(this.start, this.end);

  /// Length of line in bytes (excluding \n)
  int get length => end - start;
}
