import 'dart:io';

import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';

void main() {
  benchmarkCreateLines();
}

void benchmarkCreateLines() {
  final fb = FileBuffer();
  fb.text = File('sample-data/eval.c').readAsStringSync();
  final stopWatch = Stopwatch()..start();
  fb.createLines();
  stopWatch.stop();
  print('create lines: ${stopWatch.elapsedMilliseconds} ms');
}
