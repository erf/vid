import 'package:characters/characters.dart';
import 'package:vid/characters_ext.dart';

import 'file_buffer.dart';
import 'modes.dart';

typedef ReplaceAction = void Function(FileBuffer, Characters);

void defaultReplace(FileBuffer f, String s) {
  final p = f.cursor;
  f.mode = Mode.normal;
  final line = f.lines[p.y];
  if (line.isEmpty) return;
  f.lines[p.y] = line.replaceCharAt(p.x, s.characters);
  f.isModified = true;
}
