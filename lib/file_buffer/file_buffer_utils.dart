import 'dart:io';

import '../actions/insert_actions.dart';
import '../editor.dart';
import '../error_or.dart';
import 'file_buffer.dart';
import 'file_buffer_text.dart';
import '../keys.dart';
import '../position.dart';

extension FileBufferUtils on FileBuffer {
  ErrorOr<bool> insertFile(Editor e, String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return ErrorOr.error('File not found: \'$path\'');
    }
    insertChunk(e, file.readAsStringSync());
    return ErrorOr.value(true);
  }

  // Insert a chunk of non-special chars - line by line in order to correctly
  // update cursor position. Add the whole string to the undo list at the end.
  void insertChunk(Editor e, String str) {
    final String buffer = str;
    final Position cursor = Position.from(this.cursor);
    final int start = indexFromPosition(cursor);
    while (str.isNotEmpty) {
      int nlPos = str.indexOf(Keys.newline);
      if (nlPos == -1) {
        InsertActions.defaultInsert(e, this, str, undo: false);
        break;
      }
      String line = str.substring(0, nlPos);
      InsertActions.defaultInsert(e, this, line, undo: false);
      InsertActions.enter(e, this, undo: false);
      str = str.substring(nlPos + 1);
    }
    addUndo(start: start, end: start, newText: buffer, cursor: cursor);
  }
}
