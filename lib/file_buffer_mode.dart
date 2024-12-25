import 'editor.dart';
import 'esc.dart';
import 'file_buffer.dart';
import 'modes.dart';

extension FileBufferMode on FileBuffer {
  void setMode(Editor e, Mode mode) {
    switch (mode) {
      case Mode.normal:
        if (this.mode == Mode.insert ||
            this.mode == Mode.command ||
            this.mode == Mode.search) {
          e.terminal.write(Esc.cursorStyleBlock);
        }
        break;
      case Mode.operator:
        break;
      case Mode.insert:
        if (this.mode != Mode.insert) {
          e.terminal.write(Esc.cursorStyleLine);
        }
        break;
      case Mode.replace:
        break;
      case Mode.command:
        break;
      case Mode.search:
        break;
    }
    this.mode = mode;
  }
}
