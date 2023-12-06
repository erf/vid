import 'file_buffer.dart';

enum Mode {
  normal,
  operator,
  insert,
  replace,
}

void setMode(FileBuffer file, Mode mode) {
  switch (mode) {
    case Mode.normal:
      //file.action = Action();
      break;
    case Mode.operator:
      //file.prevAction = file.action;
      //file.action = Action();
      break;
    case Mode.insert:
      break;
    case Mode.replace:
      break;
  }
  file.mode = mode;
}
