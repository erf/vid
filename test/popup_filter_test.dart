import 'package:test/test.dart';
import 'package:vid/popup/popup.dart';

PopupState<String> popupWithItems([List<String>? labels]) {
  final items = (labels ?? ['apple', 'banana', 'cherry'])
      .map((l) => PopupItem(label: l, value: l))
      .toList();
  return PopupState<String>.create(title: 'test', items: items);
}

void main() {
  group('filter editing with ASCII', () {
    test('addFilterChar appends at cursor', () {
      var p = popupWithItems();
      p = p.addFilterChar('a');
      p = p.addFilterChar('b');
      expect(p.filterText, 'ab');
      expect(p.filterCursor, 2);
    });

    test('addFilterChar inserts at cursor position', () {
      var p = popupWithItems();
      p = p.addFilterChar('a');
      p = p.addFilterChar('c');
      p = p.moveFilterCursorLeft();
      p = p.addFilterChar('b');
      expect(p.filterText, 'abc');
      expect(p.filterCursor, 2);
    });

    test('removeFilterChar deletes char before cursor', () {
      var p = popupWithItems();
      p = p.addFilterChar('a');
      p = p.addFilterChar('b');
      p = p.removeFilterChar();
      expect(p.filterText, 'a');
      expect(p.filterCursor, 1);
    });

    test('removeFilterChar at start is a no-op', () {
      var p = popupWithItems();
      p = p.addFilterChar('a');
      p = p.moveFilterCursorToStart();
      p = p.removeFilterChar();
      expect(p.filterText, 'a');
      expect(p.filterCursor, 0);
    });

    test('cursor movement clamps at boundaries', () {
      var p = popupWithItems();
      p = p.addFilterChar('a');
      p = p.moveFilterCursorLeft();
      p = p.moveFilterCursorLeft(); // already at 0
      expect(p.filterCursor, 0);
      p = p.moveFilterCursorRight();
      p = p.moveFilterCursorRight(); // already at end
      expect(p.filterCursor, 1);
    });
  });

  group('filter editing with multi-byte graphemes', () {
    // 'é' as single code point (U+00E9, 2 UTF-16 units? no — 1 unit, 2 UTF-8 bytes)
    // Emoji '😀' is 2 UTF-16 code units. Combining sequences span multiple units.

    test('removeFilterChar removes whole emoji, not half a surrogate pair', () {
      var p = popupWithItems();
      p = p.addFilterChar('😀');
      expect(p.filterText, '😀');
      expect(p.filterCursor, '😀'.length);

      p = p.removeFilterChar();
      expect(p.filterText, '');
      expect(p.filterCursor, 0);
    });

    test('cursor movement treats emoji as one unit', () {
      var p = popupWithItems();
      p = p.addFilterChar('a');
      p = p.addFilterChar('😀');
      p = p.addFilterChar('b');

      // cursor at end; move left over 'b', then over whole emoji
      p = p.moveFilterCursorLeft();
      expect(p.filterCursor, 'a😀'.length);
      p = p.moveFilterCursorLeft();
      expect(p.filterCursor, 'a'.length);
      p = p.moveFilterCursorRight();
      expect(p.filterCursor, 'a😀'.length);
    });

    test('insert at cursor keeps emoji intact', () {
      var p = popupWithItems();
      p = p.addFilterChar('😀');
      p = p.moveFilterCursorLeft(); // cursor before emoji
      expect(p.filterCursor, 0);
      p = p.addFilterChar('x');
      expect(p.filterText, 'x😀');
      expect(p.filterCursor, 1);
    });

    test('removeFilterChar removes whole combining sequence', () {
      // 'e' + combining acute accent (U+0301) = single grapheme 'é'
      const accented = 'é'; // e + ́
      var p = popupWithItems();
      p = p.addFilterChar(accented);
      expect(p.filterText, accented);

      p = p.removeFilterChar();
      expect(p.filterText, '');
      expect(p.filterCursor, 0);
    });

    test('removeFilterChar in middle leaves surrounding text intact', () {
      var p = popupWithItems();
      p = p.addFilterChar('a');
      p = p.addFilterChar('😀');
      p = p.addFilterChar('b');
      p = p.moveFilterCursorLeft(); // before 'b', after emoji
      p = p.removeFilterChar(); // removes emoji
      expect(p.filterText, 'ab');
      expect(p.filterCursor, 1);
    });
  });
}
