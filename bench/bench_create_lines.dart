import 'dart:io';

import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/terminal.dart';
import 'package:vid/terminal_dummy.dart';

void main() {
  String text = File('sample-data/Sema.zig').readAsStringSync();
  final editor = Editor(terminal: TerminalDummy(80, 24), redraw: false);
  benchmarkCreateLinesWrapModeNone(editor, text);
  benchmarkCreateLinesWrapModeChar(editor, text);
  benchmarkCreateLinesWrapModeWord(editor, text);
}

void benchmarkCreateLinesWrapModeNone(Editor editor, String text) {
  final stopWatch = Stopwatch()..start();
  final f = FileBuffer(text: text);
  f.createLines(editor, WrapMode.none);
  print('create lines (wrap none): ${stopWatch.elapsedMilliseconds} ms');
  stopWatch.stop();
}

void benchmarkCreateLinesWrapModeChar(Editor editor, String text) {
  final stopWatch = Stopwatch()..start();
  final f = FileBuffer(text: text);
  f.createLines(editor, WrapMode.char);
  print('create lines (wrap char): ${stopWatch.elapsedMilliseconds} ms');
  stopWatch.stop();
}

void benchmarkCreateLinesWrapModeWord(Editor editor, String text) {
  final stopWatch = Stopwatch()..start();
  final f = FileBuffer(text: text);
  f.createLines(editor, WrapMode.word);
  print('create lines (wrap word): ${stopWatch.elapsedMilliseconds} ms');
  stopWatch.stop();
}
