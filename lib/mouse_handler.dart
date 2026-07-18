import 'package:termio/termio.dart';

import 'editor.dart';
import 'file_buffer/file_buffer_nav.dart';
import 'modes.dart';
import 'popup/popup_renderer.dart';

/// Routes terminal mouse events (clicks and scroll) to the editor.
///
/// Stateless: all coordination goes through the passed-in [Editor].
/// Redraw is owned by `Editor.input`, so handlers here never call draw.
class MouseHandler {
  /// Handle a mouse event (clicks and scroll).
  void handle(Editor e, MouseEvent mouse) {
    if (mouse.isScroll) {
      _handleScroll(e, mouse);
    } else if (mouse.isPress && mouse.button == MouseButton.left) {
      _handleClick(e, mouse);
    }
    // Ignore other events (release, right-click, etc.)
  }

  /// Handle scroll wheel via mouse event.
  void _handleScroll(Editor e, MouseEvent mouse) {
    // Only handle vertical scroll events
    final dir = mouse.scrollDirection;
    if (dir != ScrollDirection.up && dir != ScrollDirection.down) return;

    final f = e.file;

    // Handle popup scroll if popup is open
    if (e.popup != null && f.mode == Mode.popup) {
      _handlePopupScroll(e, dir!);
      return;
    }

    final visibleLines = e.terminal.height - 1;

    // Don't scroll if all content fits in viewport
    if (f.totalLines <= visibleLines) return;

    final scrollLines = e.config.scrollLines;
    final scrollPadding = e.config.scrollPadding;
    final currentLine = f.lineNumber(f.viewport);
    final delta = dir == ScrollDirection.up ? -scrollLines : scrollLines;
    // Max viewport line: last line at bottom of screen + padding
    final maxViewportLine = f.totalLines - visibleLines + scrollPadding;
    final targetLine = (currentLine + delta).clamp(0, maxViewportLine);
    f.viewport = f.lineOffset(targetLine);
    _clampCursorToViewport(e);
  }

  /// Handle left-click to set cursor position.
  void _handleClick(Editor e, MouseEvent mouse) {
    // mouse.x and mouse.y are 1-based screen coordinates
    final screenRow = mouse.y - 1; // Convert to 0-based
    final screenCol = mouse.x - 1;

    final f = e.file;

    // Check for popup click first
    if (e.popup != null && f.mode == Mode.popup) {
      _handlePopupClick(e, mouse.x, mouse.y);
      return;
    }

    // Don't handle clicks on status line
    if (screenRow >= e.terminal.height - 1) return;

    // Ignore clicks in the gutter area
    if (screenCol < e.renderer.gutterWidth) return;

    // Adjust for gutter width
    final contentCol = screenCol - e.renderer.gutterWidth;

    // Use the screen row map populated by the renderer
    if (screenRow >= e.renderer.screenRowMap.length) return;

    final rowInfo = e.renderer.screenRowMap[screenRow];

    // Ignore clicks on ~ lines (past end of file)
    if (rowInfo.lineNum < 0) return;

    // contentCol + wrapCol gives the position within the full line
    f.cursor = f.screenColToOffset(
      rowInfo.lineNum,
      rowInfo.wrapCol + contentCol,
      e.config.tabWidth,
    );
    f.clampCursor();
  }

  /// Handle click on popup menu.
  void _handlePopupClick(Editor e, int x, int y) {
    final popup = e.popup;
    if (popup == null) return;

    final hit = e.renderer.popupRenderer.hitTest(x, y);
    switch (hit) {
      case PopupHitOutside():
        // Click outside popup - cancel
        popup.onCancel?.call();
      case PopupHitInside():
        // Click inside popup but not on an item (header/filter/empty row)
        break;
      case PopupHitItem(:final itemIndex):
        if (itemIndex < popup.items.length) {
          // Update selection and select the item
          e.popup = popup.copyWith(selectedIndex: itemIndex);
          e.draw();

          // Use invokeSelect for type-safe callback invocation
          e.popup!.invokeSelect();
        }
    }
  }

  /// Handle scroll wheel in popup menu.
  void _handlePopupScroll(Editor e, ScrollDirection dir) {
    final popup = e.popup;
    if (popup == null) return;

    final scrollLines = e.config.scrollLines;
    final delta = dir == ScrollDirection.up ? -scrollLines : scrollLines;

    final oldIndex = popup.selectedIndex;
    e.popup = popup.scrollViewport(delta);

    if (e.popup!.selectedIndex != oldIndex) {
      e.notifyPopupHighlight();
    }
  }

  /// Clamp cursor to top/bottom of viewport if it goes off-screen.
  void _clampCursorToViewport(Editor e) {
    final f = e.file;
    final viewportLine = f.lineNumber(f.viewport);
    final cursorLine = f.lineNumber(f.cursor);
    final visibleLines = e.terminal.height - 1; // Account for status line

    if (cursorLine < viewportLine) {
      // Cursor above viewport - move to first visible line
      f.cursor = f.lineOffset(viewportLine);
      f.clampCursor();
    } else if (cursorLine >= viewportLine + visibleLines) {
      // Cursor below viewport - move to last visible line
      final lastVisibleLine = (viewportLine + visibleLines - 1).clamp(
        0,
        f.totalLines - 1,
      );
      f.cursor = f.lineOffset(lastVisibleLine);
      f.clampCursor();
    }
  }
}
