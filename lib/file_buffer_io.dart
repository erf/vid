import 'dart:io';

import 'editor.dart';
import 'error_or.dart';
import 'esc.dart';
import 'file_buffer.dart';
import 'terminal.dart';

extension FileBufferIo on FileBuffer {
  // load file from disk or create new file, return file name
  static ErrorOr<FileBuffer> load(Editor editor, String path,
      {required bool allowNew}) {
    //  if no path is given, return an empty file buffer
    if (path.isEmpty) {
      return ErrorOr.value(FileBuffer(path: '', text: ''));
    }

    // check if path is a directory
    if (Directory(path).existsSync()) {
      return ErrorOr.error('Cannot open directory \'$path\'');
    }

    // load file if it exists
    final file = File(path);
    if (file.existsSync()) {
      String text;
      try {
        text = file.readAsStringSync();
      } catch (error) {
        return ErrorOr.error('Error reading file: $error');
      }
      return ErrorOr.value(FileBuffer(path: path, text: text));
    }

    // create new file if allowed
    if (allowNew) {
      return ErrorOr.value(FileBuffer(path: path, text: ''));
    }

    return ErrorOr.error('File not found \'$path\'');
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
  ErrorOr<bool> save(String? path) {
    if (path == null || path.isEmpty) {
      return ErrorOr.error('path is empty');
    }
    try {
      File(path).writeAsStringSync(text);
    } catch (error) {
      return ErrorOr.error('Error saving file: $path');
    }
    setSavepoint();
    Terminal.instance.write(Esc.setWindowTitle(path));
    return ErrorOr.value(true);
  }
}
