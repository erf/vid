import 'dart:io';

import 'package:vid/config.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';

void main() {
  String text = File('sample-data/Sema.zig').readAsStringSync();
  benchmarkCreateLinesWrapModeNone(text, 80, 24);
  benchmarkCreateLinesWrapModeChar(text, 80, 24);
  benchmarkCreateLinesWrapModeWord(text, 80, 24);
}

void benchmarkCreateLinesWrapModeNone(String text, int width, int height) {
  final stopWatch = Stopwatch()..start();
  final f = FileBuffer(text: text);
  f.createLines(WrapMode.none, width, height);
  print('create lines (wrap none): ${stopWatch.elapsedMilliseconds} ms');
  stopWatch.stop();
}

void benchmarkCreateLinesWrapModeChar(String text, int width, int height) {
  final stopWatch = Stopwatch()..start();
  final f = FileBuffer(text: text);
  f.createLines(WrapMode.char, width, height);
  print('create lines (wrap char): ${stopWatch.elapsedMilliseconds} ms');
  stopWatch.stop();
}

void benchmarkCreateLinesWrapModeWord(String text, int width, int height) {
  final stopWatch = Stopwatch()..start();
  final f = FileBuffer(text: text);
  f.createLines(WrapMode.word, width, height);
  print('create lines (wrap word): ${stopWatch.elapsedMilliseconds} ms');
  stopWatch.stop();
}
