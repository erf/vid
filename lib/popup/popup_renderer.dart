import 'package:termio/termio.dart';

import '../config.dart';
import '../highlighting/highlighter.dart';
import 'popup.dart';

/// Result of a popup hit-test.
sealed class PopupHit {}

/// Click landed outside the popup bounds.
class PopupHitOutside extends PopupHit {}

/// Click landed inside the popup but not on any item (header/filter/empty).
class PopupHitInside extends PopupHit {}

/// Click landed on an item row.
class PopupHitItem extends PopupHit {
  final int itemIndex;
  PopupHitItem(this.itemIndex);
}

/// Renders the popup overlay and answers mouse hit-tests against it.
///
/// Owns its own geometry and row→item map state; updated on each [draw].
class PopupRenderer {
  final TerminalBase terminal;
  final Highlighter highlighter;

  /// Maps popup content row (0-based, relative to first item row) to item
  /// index, or -1 for empty rows. Populated during [draw].
  final List<int> popupRowMap = [];

  /// Popup bounds for mouse click detection.
  int popupLeft = 0;
  int popupTop = 0;
  int popupRight = 0;
  int popupBottom = 0;

  PopupRenderer({required this.terminal, required this.highlighter});

  /// Draw popup menu overlay into [buffer].
  void draw(StringBuffer buffer, PopupState popup, Config config) {
    popupRowMap.clear();

    // Use percentage-based margins for better scaling
    // ~12% margin on each side, so popup takes ~76% of terminal
    final horizontalMargin = (terminal.width * 0.12).round().clamp(6, 24);
    final verticalMargin = (terminal.height * 0.12).round().clamp(3, 12);

    // Calculate popup size with margins
    var popupWidth = terminal.width - (horizontalMargin * 2);
    // Config takes precedence, then popup's own maxWidth
    final maxWidth = config.popupMaxWidth ?? popup.maxWidth;
    if (maxWidth != null && popupWidth > maxWidth) {
      popupWidth = maxWidth;
    }
    final popupHeight = terminal.height - (verticalMargin * 2);
    const innerPadding = 1; // Space inside popup on left and right
    final contentWidth = popupWidth - (innerPadding * 2);
    final maxVisible =
        popupHeight - (popup.showFilter ? 3 : 2); // Account for header + footer
    final items = popup.items;

    // Center the popup
    final left = (terminal.width - popupWidth) ~/ 2;
    final top = verticalMargin;

    // Store bounds for mouse detection
    popupLeft = left;
    popupTop = top;
    popupRight = left + popupWidth;
    popupBottom = top + popupHeight;

    // Draw header with title and count (contrasting background)
    buffer.write(Ansi.cursor(x: left + 1, y: top + 1));
    buffer.write(Ansi.inverse(true));
    buffer.write(' ' * innerPadding);
    final totalItems = popup.allItems.length;
    final countStr = totalItems != items.length
        ? '${items.length}/$totalItems'
        : '${items.length}';
    var header = '${popup.title} ($countStr)';
    if (header.length > contentWidth) {
      header = '${header.substring(0, contentWidth - 1)}…';
    }
    buffer.write(header.padRight(contentWidth));
    buffer.write(' ' * innerPadding);
    buffer.write(Ansi.inverse(false));

    // Draw items (fixed height, fill empty rows)
    final scrollOffset = popup.scrollOffset;
    final selectionBg =
        highlighter.theme.selectionBackground ?? Ansi.bg(Color.brightBlack);
    for (int i = 0; i < maxVisible; i++) {
      final itemIndex = scrollOffset + i;
      final row = top + 2 + i; // +2 for header row

      buffer.write(Ansi.cursor(x: left + 1, y: row));
      buffer.write(' ' * innerPadding); // Left padding

      if (itemIndex < items.length) {
        final item = items[itemIndex];
        final isSelected = itemIndex == popup.selectedIndex;

        // Highlight selected item with theme selection background
        if (isSelected) {
          buffer.write(selectionBg);
        }

        // Build item content
        final iconStr = item.icon != null ? '${item.icon} ' : '';
        final labelStr = item.label;
        final detailStr = item.detail != null ? ' ${item.detail}' : '';
        var content = '$iconStr$labelStr$detailStr';

        // Truncate if needed and pad to width
        if (content.length > contentWidth) {
          content = '${content.substring(0, contentWidth - 1)}…';
        }
        content = content.padRight(contentWidth);

        buffer.write(content);

        if (isSelected) {
          highlighter.theme.resetCode(buffer);
        }

        // Map row to item index for mouse clicks
        popupRowMap.add(itemIndex);
      } else {
        // Empty row
        buffer.write(' ' * contentWidth);
        popupRowMap.add(-1);
      }

      buffer.write(' ' * innerPadding); // Right padding
    }

    // Draw filter input line if shown
    if (popup.showFilter) {
      final filterRow = top + 2 + maxVisible;
      buffer.write(Ansi.cursor(x: left + 1, y: filterRow));
      buffer.write(' ' * innerPadding);
      final filterContent = '> ${popup.filterText}';
      final padded = filterContent.padRight(contentWidth);
      buffer.write(padded.substring(0, contentWidth));
      buffer.write(' ' * innerPadding);
    }

    // Position cursor in filter input if shown
    if (popup.showFilter) {
      final cursorX =
          left +
          1 +
          innerPadding +
          2 +
          popup.filterCursor; // after padding + "> "
      final cursorY = top + 2 + maxVisible;
      buffer.write(Ansi.cursorStyle(CursorStyle.steadyBar));
      buffer.write(Ansi.cursor(x: cursorX, y: cursorY));
    } else {
      // Hide cursor
      buffer.write(Ansi.cursor(x: 1, y: terminal.height));
    }
  }

  /// Hit-test a mouse click at 1-based terminal coordinates [x], [y].
  ///
  /// Must be called after [draw] so popup bounds reflect the latest layout.
  PopupHit hitTest(int x, int y) {
    // Check if click is within popup bounds (1-based coordinates)
    if (x < popupLeft + 1 ||
        x > popupRight ||
        y < popupTop + 1 ||
        y > popupBottom) {
      return PopupHitOutside();
    }

    // Calculate which row was clicked (0-based, relative to popup content)
    final contentRowStart = popupTop + 2; // After title bar
    final clickedRow = y - contentRowStart;

    if (clickedRow >= 0 && clickedRow < popupRowMap.length) {
      final itemIndex = popupRowMap[clickedRow];
      if (itemIndex >= 0) {
        return PopupHitItem(itemIndex);
      }
    }
    return PopupHitInside();
  }
}
