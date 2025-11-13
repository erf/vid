import 'dart:math' as math;

import '../terminal/terminal_base.dart';
import '../utils.dart';
import 'file_buffer.dart';

extension FileBufferView on FileBuffer {
  // clamp cursor position to valid range
  void clampCursor() {
    cursor.l = clamp(cursor.l, 0, lines.length - 1);
    cursor.c = clamp(cursor.c, 0, lines[cursor.l].charLen - 1);
  }

  // clamp view on cursor position
  void clampView(TerminalBase term, int cursorpos) {
    view.l = clamp(view.l, cursor.l, cursor.l - term.height + 2);
    view.c = clamp(view.c, cursorpos, cursorpos - term.width + 1);
  }

  void centerView(TerminalBase term) {
    view.l = cursor.l - (term.height - 2) ~/ 2;
    view.l = math.max(view.l, 0);
  }
}
