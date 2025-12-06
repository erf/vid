import 'dart:io';

import '../editor.dart';
import '../error_or.dart';
import 'file_buffer.dart';
import 'file_buffer_text.dart';

extension FileBufferUtils on FileBuffer {
  ErrorOr<bool> insertFile(Editor e, String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return ErrorOr.error('File not found: \'$path\'');
    }
    insertChunk(e, file.readAsStringSync());
    return ErrorOr.value(true);
  }

  // Insert a chunk of text at cursor position.
  // Batches the entire insert as a single undo operation.
  void insertChunk(Editor e, String str) {
    final int startOffset = cursor;
    // Insert entire string at once
    insertAt(cursor, str, undo: false, config: e.config);
    cursor += str.length;
    // Add single undo entry for the whole chunk
    addUndo(
      start: startOffset,
      end: startOffset,
      newText: str,
      cursorOffset: startOffset,
      config: e.config,
    );
  }
}
