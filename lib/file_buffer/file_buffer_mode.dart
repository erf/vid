import '../editor.dart';
import '../esc.dart';
import 'file_buffer.dart';
import '../modes.dart';

extension FileBufferMode on FileBuffer {
  void setMode(Editor e, Mode mode) {
    if (e.file.mode == mode) {
      return;
    }
    switch (mode) {
      case Mode.normal:
        e.terminal.write(Esc.cursorStyleBlock);
      case Mode.insert:
        e.terminal.write(Esc.cursorStyleLine);
      default:
        break;
    }
    this.mode = mode;
  }
}
