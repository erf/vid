import 'dart:math' as math;

import 'file_buffer.dart';
import 'terminal.dart';
import 'utils.dart';

extension FileBufferView on FileBuffer {
  // clamp cursor position to valid range
  void clampCursor() {
    cursor.l = clamp(cursor.l, 0, lines.length - 1);
    cursor.c = clamp(cursor.c, 0, lines[cursor.l].charLen - 1);
  }

  // clamp view on cursor position
  void clampView(Terminal term, int cursorpos) {
    view.l = clamp(view.l, cursor.l, cursor.l - term.height + 2);
    view.c = clamp(view.c, cursorpos, cursorpos - term.width + 1);
  }

  void centerView(Terminal term) {
    view.l = cursor.l - (term.height - 2) ~/ 2;
    view.l = math.max(view.l, 0);
  }
}
