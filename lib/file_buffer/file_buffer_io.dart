import 'dart:convert';
import 'dart:io';

import 'package:termio/termio.dart';

import '../editor.dart';
import '../error_or.dart';
import 'file_buffer.dart';

extension FileBufferIo on FileBuffer {
  // load file from disk or create new file, return file name
  static ErrorOr<FileBuffer> load(
    String path, {
    required bool createIfNotExists,
    String? cwd,
  }) {
    //  if no path is given, return an empty file buffer
    if (path.isEmpty) {
      return ErrorOr.value(FileBuffer(cwd: cwd));
    }

    // check if path is a directory
    if (Directory(path).existsSync()) {
      return ErrorOr.error('Cannot open directory: \'$path\'');
    }

    // load file if it exists
    final file = File(path);
    final String absolutePath = file.absolute.path;
    if (file.existsSync()) {
      try {
        String text = file.readAsStringSync();
        // add newline at end of file if missing
        if (!text.endsWith(Keys.newline)) {
          text += Keys.newline;
        }
        return ErrorOr.value(
          FileBuffer(
            path: path,
            absolutePath: absolutePath,
            text: text,
            cwd: cwd,
          ),
        );
      } catch (error) {
        return ErrorOr.error('Error reading file: \'$error\'');
      }
    }

    // create new file if allowed
    if (createIfNotExists) {
      return ErrorOr.value(
        FileBuffer(path: path, absolutePath: absolutePath, cwd: cwd),
      );
    }

    // file not found
    return ErrorOr.error('File not found: \'$path\'');
  }

  // parse line number argument if it exists, set cursor to start of that line
  void parseCliArgs(List<String> args) {
    if (args.length > 1 && args.last.startsWith('+')) {
      final lineNo = args.last.substring(1);
      if (lineNo.isNotEmpty) {
        int targetLine = (int.tryParse(lineNo) ?? 1) - 1;
        cursor = lineOffset(targetLine);
      } else {
        cursor = 0;
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
    e.terminal.write(Ansi.setTitle('vid $path'));
    return ErrorOr.value(true);
  }

  // read a single character from stdin (used by find motions)
  String readNextChar() {
    return utf8.decode([stdin.readByteSync()]);
  }

  /// Convert a path to absolute path
  static String toAbsolutePath(String path) {
    return File(path).absolute.path;
  }

  static String get cacheDir {
    return Platform.environment['XDG_CACHE_HOME'] ??
        '${Platform.environment['HOME']}/.cache';
  }
}
