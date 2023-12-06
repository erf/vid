import 'package:characters/characters.dart';

import 'editor.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_text.dart';
import 'modes.dart';

typedef ReplaceAction = void Function(FileBuffer, Characters);

void defaultReplace(Editor e, FileBuffer f, String s) {
  setMode(e, f, Mode.normal);
  if (f.empty) return;
  f.replaceAt(f.cursor, s);
}
