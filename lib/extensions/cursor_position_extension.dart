import 'dart:io';

import 'package:vid/keys.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_io.dart';
import '../file_buffer/file_buffer_nav.dart';
import 'extension.dart';

/// Extension that remembers cursor positions for files
class CursorPositionExtension implements Extension {
  Map<String, int> cursorPerFile = {};

  CursorPositionExtension();

  @override
  void onInit(Editor editor) {
    cursorPerFile = loadCursorPositions();
  }

  @override
  void onFileOpen(Editor editor, FileBuffer file) {
    int? cursorPosition = cursorPerFile[file.absolutePath];
    if (cursorPosition != null) {
      file.cursor = cursorPosition;
      file.clampCursor();
      file.centerViewport(editor.terminal);
    }
  }

  @override
  void onQuit(Editor editor) {
    FileBuffer file = editor.file;
    if (file.absolutePath != null) {
      if (file.cursor == 0) {
        cursorPerFile.remove(file.absolutePath!);
      } else {
        cursorPerFile[file.absolutePath!] = file.cursor;
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
          final [path, pos] = line.split(',');
          return MapEntry(path, int.tryParse(pos) ?? 0);
        }),
      );
    } catch (error) {
      return {};
    }
  }

  void saveCursorPositions(Map<String, int> cursorPositionsPerFile) {
    final file = File(cursorPositionsPath);
    final lines = cursorPositionsPerFile.entries
        .map((entry) => '${entry.key},${entry.value}')
        .join(Keys.newline);
    file.writeAsStringSync(lines);
  }
}
