import 'dart:math';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import 'action_base.dart';

enum HalfPageDir {
  down(1),
  up(-1);

  const HalfPageDir(this.value);
  final int value;
}

/// Scroll viewport by half page (Ctrl-D/Ctrl-U).
/// Both viewport and cursor move by the same number of lines.
class MoveHalfPage extends Action {
  final HalfPageDir direction;
  const MoveHalfPage(this.direction);

  @override
  void call(Editor e, FileBuffer f) {
    final halfPage = e.terminal.height ~/ 2;
    final cursorLine = f.lineNumber(f.cursor);

    // Do nothing if cursor is already at boundary
    if (direction == .down && cursorLine >= f.totalLines - 1) return;
    if (direction == .up && cursorLine <= 0) return;

    // Calculate current cursor column for preservation
    final cursorCol = f.cursor - f.lines[cursorLine].start;

    // Calculate new cursor line (clamped to valid range)
    final newCursorLine = (cursorLine + direction.value * halfPage).clamp(
      0,
      f.totalLines - 1,
    );

    // Move cursor, preserving column
    final lineInfo = f.lines[newCursorLine];
    f.cursor = min(lineInfo.start + cursorCol, lineInfo.end);
    f.clampCursor();

    // Scroll viewport by same amount (clamped to valid range)
    final viewportLine = f.lineNumber(f.viewport);
    final visibleLines = e.terminal.height - 1;
    final maxViewportLine = max(0, f.totalLines - visibleLines);
    final newViewportLine = (viewportLine + direction.value * halfPage).clamp(
      0,
      maxViewportLine,
    );
    f.viewport = f.lineOffset(newViewportLine);
  }
}

/// Scroll view position.
enum ViewPosition { center, top, bottom }

/// Scroll view to position cursor at center/top/bottom.
class ScrollView extends Action {
  final ViewPosition position;
  const ScrollView(this.position);

  @override
  void call(Editor e, FileBuffer f) {
    switch (position) {
      case .center:
        f.centerViewport(e.terminal);
      case .top:
        f.topViewport();
      case .bottom:
        f.bottomViewport(e.terminal);
    }
  }
}
