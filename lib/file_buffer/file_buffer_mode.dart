import '../editor.dart';
import '../esc.dart';
import '../modes.dart';
import 'file_buffer.dart';

extension FileBufferMode on FileBuffer {
  void setMode(Editor e, Mode mode) {
    if (e.file.mode == mode) {
      return;
    }
    switch (mode) {
      case .normal:
        e.terminal.write(Esc.cursorStyleBlock);
      case .insert:
        e.terminal.write(Esc.cursorStyleLine);
      default:
        break;
    }
    this.mode = mode;
  }
}
