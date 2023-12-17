import 'dart:io';

import 'package:args/args.dart';

import 'editor.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_view.dart';

extension FileBufferLines on FileBuffer {
  // load file from disk or create new file, return file name
  String load(Editor editor, List<String> args) {
    // check if file name is specified
    if (args.isEmpty) {
      createLines();
      return '';
    }

    // parse command line arguments
    final parser = ArgParser();
    parser.addOption('log', abbr: 'l', help: 'Log file');

    // parse file name
    path = args.first;

    // parse log file
    ArgResults argRes = parser.parse(args);
    if (argRes.wasParsed('log')) {
      editor.logPath = argRes['log'];
    }

    // parse line number
    if (args.last.startsWith('+')) {
      final lineNo = args.last.substring(1);
      if (lineNo.isEmpty) {
        print('No line number specified');
        exit(1);
      }
      cursor.l = int.parse(lineNo) - 1;
    }

    // check if path is a directory
    if (Directory(path!).existsSync()) {
      print('Cannot open directory \'$path\'');
      exit(1);
    }

    // load file if it exists
    final file = File(path!);
    if (file.existsSync()) {
      text = file.readAsStringSync();
    }

    // split text into lines
    createLines();

    return path!;
  }

  // save file to disk
  bool save() {
    try {
      File(path!).writeAsStringSync(text);
      setSavepoint();
      return true;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}
