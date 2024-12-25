import 'package:characters/characters.dart';

import 'editor.dart';
import 'file_buffer.dart';
import 'file_buffer_lines.dart';
import 'file_buffer_mode.dart';
import 'file_buffer_text.dart';
import 'modes.dart';

typedef ReplaceAction = void Function(Editor, FileBuffer, Characters);

void defaultReplace(Editor e, FileBuffer f, String s) {
  f.setMode(e, Mode.normal);
  if (f.empty) return;
  f.replaceAt(e, f.cursor, s);
}
