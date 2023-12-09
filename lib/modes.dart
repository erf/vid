import 'editor.dart';
import 'esc.dart';
import 'file_buffer.dart';

enum Mode {
  normal,
  operator,
  insert,
  replace,
}

void setMode(Editor editor, FileBuffer file, Mode mode) {
  switch (mode) {
    case Mode.normal:
      editor.term.write(Esc.cursorStyleBlock);
      break;
    case Mode.operator:
      break;
    case Mode.insert:
      editor.term.write(Esc.cursorStyleLine);
      break;
    case Mode.replace:
      break;
  }
  file.mode = mode;
}
