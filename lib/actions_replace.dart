import 'package:characters/characters.dart';

import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'string_ext.dart';

typedef ReplaceAction = void Function(FileBuffer, Characters);

void defaultReplace(FileBuffer f, String s) {
  f.mode = Mode.normal;
  if (f.empty) return;
  f.replaceAt(f.cursor, s);
}
