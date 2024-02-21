import 'dart:io';

import 'vid_exception.dart';

import 'editor.dart';
import 'esc.dart';
import 'file_buffer.dart';
import 'terminal.dart';

extension FileBufferIo on FileBuffer {
  // load file from disk or create new file, return file name
  static FileBuffer load(Editor editor, String path, {required bool allowNew}) {
    //  if no path is given, return an empty file buffer
    if (path.isEmpty) {
      return FileBuffer(path: '', text: '');
    }

    // check if path is a directory
    if (Directory(path).existsSync()) {
      throw VidException('Cannot open directory \'$path\'');
    }

    // load file if it exists
    final file = File(path);
    if (file.existsSync()) {
      String text;
      try {
        text = file.readAsStringSync();
      } catch (error) {
        throw VidException('Error reading file: $error');
      }
      return FileBuffer(path: path, text: text);
    }

    // create new file if allowed
    if (allowNew) {
      return FileBuffer(path: path, text: '');
    }

    throw VidException('File not found: $path');
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
  void save(String? path) {
    if (path == null || path.isEmpty) {
      throw VidException('\'path\' is empty');
    }
    File(path).writeAsStringSync(text);
    setSavepoint();
    Terminal.instance.write(Esc.setWindowTitle(path));
  }
}
