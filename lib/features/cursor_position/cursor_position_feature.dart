import 'dart:io';

import 'package:termio/termio.dart';

import '../../file_buffer/file_buffer.dart';
import '../feature.dart';

/// Feature that remembers cursor positions for files
class CursorPositionFeature extends Feature {
  Map<String, int> cursorPerFile = {};

  CursorPositionFeature(super.editor);

  @override
  void onInit() {
    cursorPerFile = loadCursorPositions();
  }

  @override
  void onFileOpen(FileBuffer file) {
    int? cursorPosition = cursorPerFile[file.absolutePath];
    if (cursorPosition != null) {
      file.cursor = cursorPosition;
      file.clampCursor();
      file.centerViewport(editor.terminal);
    }
  }

  @override
  void onBufferSwitch(FileBuffer previous, FileBuffer next) {
    // Save cursor position when switching away from a buffer
    _saveCursorForBuffer(previous);
  }

  @override
  void onBufferClose(FileBuffer file) {
    // Save cursor position when closing a buffer
    _saveCursorForBuffer(file);
  }

  @override
  void onQuit() {
    // Save cursor position for current buffer and persist to disk
    _saveCursorForBuffer(editor.file);
    saveCursorPositions(cursorPerFile);
  }

  void _saveCursorForBuffer(FileBuffer buffer) {
    if (buffer.absolutePath != null) {
      if (buffer.cursor == 0) {
        cursorPerFile.remove(buffer.absolutePath!);
      } else {
        cursorPerFile[buffer.absolutePath!] = buffer.cursor;
      }
    }
  }

  String get cursorPositionsPath {
    return '${editor.cacheDir}/vid_cursor_positions.csv';
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
