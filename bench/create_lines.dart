import 'dart:io';

import 'package:vid/config.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';

void main() {
  String text = File('sample-data/eval.c').readAsStringSync();
  benchmarkCreateLinesWrapModeNone(text);
  benchmarkCreateLinesWrapModeWord(text);
}

void benchmarkCreateLinesWrapModeNone(String text) {
  final stopWatch = Stopwatch()..start();
  final f = FileBuffer();
  f.text = text;
  f.createLines(WrapMode.none, 80, 24);
  print('create lines (wrap none): ${stopWatch.elapsedMilliseconds} ms');
  stopWatch.stop();
}

void benchmarkCreateLinesWrapModeWord(String text) {
  final stopWatch = Stopwatch()..start();
  final f = FileBuffer();
  f.text = text;
  f.createLines(WrapMode.word, 80, 24);
  print('create lines (wrap word): ${stopWatch.elapsedMilliseconds} ms');
  stopWatch.stop();
}
