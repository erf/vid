import 'esc.dart';
import 'file_buffer.dart';
import 'modes.dart';
import 'terminal.dart';

extension FileBufferMode on FileBuffer {
  void setMode(Mode mode) {
    switch (mode) {
      case Mode.normal:
        if (this.mode == Mode.insert ||
            this.mode == Mode.command ||
            this.mode == Mode.search) {
          Terminal.instance.write(Esc.cursorStyleBlock);
        }
        break;
      case Mode.operator:
        break;
      case Mode.insert:
        if (this.mode != Mode.insert) {
          Terminal.instance.write(Esc.cursorStyleLine);
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
