import 'dart:io';

import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/string_ext.dart';

void main() {
  // benchmark create lines
  final fileBuffer = FileBuffer();
  fileBuffer.text = File('sample-data/eval.c').readAsStringSync().ch;
  final stopWatch = Stopwatch()..start();
  fileBuffer.createLines();
  stopWatch.stop();
  print('create lines: ${stopWatch.elapsedMilliseconds} ms');
}
