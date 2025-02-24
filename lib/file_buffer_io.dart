import 'dart:convert';
import 'dart:io';

import 'editor.dart';
import 'error_or.dart';
import 'esc.dart';
import 'file_buffer.dart';

extension FileBufferIo on FileBuffer {
  // load file from disk or create new file, return file name
  static ErrorOr<FileBuffer> load(
    Editor editor, {
    required String path,
    required bool createNewFileIfNotExists,
  }) {
    //  if no path is given, return an empty file buffer
    if (path.isEmpty) {
      return ErrorOr.value(FileBuffer());
    }

    // check if path is a directory
    if (Directory(path).existsSync()) {
      return ErrorOr.error('Cannot open directory: \'$path\'');
    }

    // load file if it exists
    final file = File(path);
    final abs = file.absolute.path;
    if (file.existsSync()) {
      try {
        String text = file.readAsStringSync();
        // add newline at end of file if missing
        if (!text.endsWith('\n')) {
          text += '\n';
        }
        return ErrorOr.value(FileBuffer(path: path, abs: abs, text: text));
      } catch (error) {
        return ErrorOr.error('Error reading file: \'$error\'');
      }
    }

    // create new file if allowed
    if (createNewFileIfNotExists) {
      return ErrorOr.value(FileBuffer(path: path, abs: abs));
    }

    // file not found
    return ErrorOr.error('File not found: \'$path\'');
  }

  // parse line number argument if it exists
  void parseCliArgs(List<String> args) {
    if (args.length > 1 && args.last.startsWith('+')) {
      final lineNo = args.last.substring(1);
      if (lineNo.isNotEmpty) {
        cursor.l = (int.tryParse(lineNo) ?? 1) - 1;
      } else {
        cursor.l = 0;
      }
    }
  }

  // save file to disk or create new file
  // we pass a path so we can try to save to a new file name before setting the path
  ErrorOr<bool> save(Editor e, String? path) {
    if (path == null || path.isEmpty) {
      return ErrorOr.error('Path is empty');
    }
    try {
      File(path).writeAsStringSync(text);
    } catch (error) {
      return ErrorOr.error('Error saving file: \'$path\'');
    }
    setSavepoint();
    e.terminal.write(Esc.setWindowTitle(path));
    return ErrorOr.value(true);
  }

  // read a single character from stdin (used by find motions)
  String readNextChar() {
    return utf8.decode([stdin.readByteSync()]);
  }

  static String get cacheDir {
    return Platform.environment['XDG_CACHE_HOME'] ??
        '${Platform.environment['HOME']}/.cache';
  }

  static String get cursorPositionsPath {
    return '$cacheDir/vid_cursor_positions.csv';
  }

  // load cursors positions from XDG_CACHE_HOME
  static Map<String, int> loadCursorPositions() {
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

  static void saveCursorPositions(Map<String, int> cursorPositionsPerFile) {
    final file = File(cursorPositionsPath);
    final lines = cursorPositionsPerFile.entries
        .map((entry) => '${entry.key},${entry.value}')
        .join('\n');
    file.writeAsStringSync(lines);
  }
}
