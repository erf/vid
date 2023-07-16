import 'package:characters/characters.dart';

import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'undo.dart';

typedef ReplaceAction = void Function(FileBuffer, Characters);

void defaultReplace(FileBuffer f, String s) {
  final p = f.cursor;
  f.mode = Mode.normal;
  if (f.empty) return;
  f.replaceChar(s, p, UndoOpType.replace);
}
