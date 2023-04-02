import 'package:characters/characters.dart';
import 'package:vid/characters_ext.dart';

import 'file_buffer.dart';
import 'modes.dart';

typedef ReplaceAction = void Function(FileBuffer, Characters);

void defaultReplace(FileBuffer f, Characters s) {
  final p = f.cursor;
  f.mode = Mode.normal;
  final line = f.lines[p.line];
  if (line.isEmpty) return;
  f.lines[p.line] = line.replaceCharAt(p.char, s);
}
