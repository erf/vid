import '../../file_buffer/file_buffer.dart';

/// Convert an LSP position (line, character) to a text offset in [file].
///
/// LSP `character` is a UTF-16 code unit offset within the line, and Dart
/// String offsets are also UTF-16 code units — so the character can be used
/// directly as an offset into the line text (no conversion needed).
/// Out-of-range values return -1.
int lspPositionToOffset(FileBuffer file, int line, int char) {
  if (line < 0 || line >= file.lines.length || char < 0) {
    return -1;
  }
  final lineStart = file.lineOffset(line);
  final lineLength = file.lines[line].length;
  return lineStart + char.clamp(0, lineLength);
}
