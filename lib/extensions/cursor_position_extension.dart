import 'package:vid/file_buffer/file_buffer_io.dart';
import 'package:vid/file_buffer/file_buffer_text.dart';
import 'package:vid/file_buffer/file_buffer_view.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import 'extension.dart';

/// Extension that remembers cursor positions for files
class CursorPositionExtension implements Extension {
  Map<String, int> cursorPerFile = {};

  @override
  void onInit(Editor editor) {
    cursorPerFile = FileBufferIo.loadCursorPositions();
  }

  @override
  void onFileOpen(Editor editor, FileBuffer file) {
    int? cursorPosition = cursorPerFile[file.absolutePath];
    if (cursorPosition != null) {
      file.cursor = file.positionFromIndex(cursorPosition);
      file.centerView(editor.terminal);
    }
  }

  @override
  void onQuit(Editor editor) {
    FileBuffer file = editor.file;
    if (file.path != null) {
      if (file.cursor.l == 0 && file.cursor.c == 0) {
        cursorPerFile.remove(file.absolutePath!);
      } else {
        cursorPerFile[file.absolutePath!] = file.indexFromPosition(file.cursor);
      }
      FileBufferIo.saveCursorPositions(cursorPerFile);
    }
  }
}
