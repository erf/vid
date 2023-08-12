import 'dart:io';

import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';

void main() {
  benchmarkCreateLines();
}

void benchmarkCreateLines() {
  final stopWatch = Stopwatch()..start();
  final fb = FileBuffer();
  fb.text = File('sample-data/eval.c').readAsStringSync();
  print('load file: ${stopWatch.elapsedMilliseconds} ms');
  fb.createLines();
  print('create lines: ${stopWatch.elapsedMilliseconds} ms');
  stopWatch.stop();
}
