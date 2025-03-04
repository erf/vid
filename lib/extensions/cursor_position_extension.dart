import 'dart:io';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_index.dart';
import '../file_buffer/file_buffer_io.dart';
import '../file_buffer/file_buffer_view.dart';
import 'extension.dart';

/// Extension that remembers cursor positions for files
class CursorPositionExtension implements Extension {
  Map<String, int> cursorPerFile = {};

  @override
  void onInit(Editor editor) {
    cursorPerFile = loadCursorPositions();
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
    if (file.absolutePath != null) {
      if (file.cursor.l == 0 && file.cursor.c == 0) {
        cursorPerFile.remove(file.absolutePath!);
      } else {
        cursorPerFile[file.absolutePath!] = file.indexFromPosition(file.cursor);
      }
      saveCursorPositions(cursorPerFile);
    }
  }

  String get cursorPositionsPath {
    return '${FileBufferIo.cacheDir}/vid_cursor_positions.csv';
  }

  // load cursors positions from XDG_CACHE_HOME
  Map<String, int> loadCursorPositions() {
    final file = File(cursorPositionsPath);
    if (!file.existsSync()) {
      return {};
    }
    try {
      final List<String> lines = file.readAsLinesSync();
      return Map.fromEntries(
        lines.map((line) {
          final List<String> parts = line.split(',');
          return MapEntry(parts[0], int.tryParse(parts[1]) ?? 0);
        }),
      );
    } catch (error) {
      return {};
    }
  }

  void saveCursorPositions(Map<String, int> cursorPositionsPerFile) {
    final file = File(cursorPositionsPath);
    final String lines = cursorPositionsPerFile.entries
        .map((entry) => '${entry.key},${entry.value}')
        .join('\n');
    file.writeAsStringSync(lines);
  }
}
