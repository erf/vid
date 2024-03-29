import 'package:characters/characters.dart';

import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_text.dart';
import 'modes.dart';

typedef ReplaceAction = void Function(FileBuffer, Characters);

void defaultReplace(FileBuffer f, String s) {
  f.setMode(Mode.normal);
  if (f.empty) return;
  f.replaceAt(f.cursor, s);
}
