import 'esc.dart';
import 'file_buffer.dart';
import 'terminal.dart';

enum Mode {
  normal,
  operator,
  insert,
  replace,
  command,
}

void setMode(FileBuffer file, Mode mode) {
  switch (mode) {
    case Mode.normal:
      Terminal.instance.write(Esc.cursorStyleBlock);
      break;
    case Mode.operator:
      break;
    case Mode.insert:
      Terminal.instance.write(Esc.cursorStyleLine);
      break;
    case Mode.replace:
      break;
    case Mode.command:
      break;
  }
  file.mode = mode;
}
