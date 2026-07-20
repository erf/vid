import 'dart:convert';

import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/popup/popup.dart';

void main() {
  test('emoji into popup filter via full input path', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    e.file.text = 'hello\n';

    e.showPopup(
      PopupState<String>.create(
        title: 'test',
        items: [PopupItem(label: 'a', value: 'a')],
      ),
    );

    // Full path: raw UTF-8 bytes -> onInput -> parser -> fallback
    e.onInput(utf8.encode('😀'));

    expect(e.file.text, 'hello\n');
    expect(e.popup?.filterText, '😀');
    expect(e.popup?.filterCursor, '😀'.length);

    // Backspace removes the whole emoji
    e.input('\x7f');
    expect(e.popup?.filterText, '');
  });

  test('bracketed-pasted emoji routes to popup filter, not file', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    e.file.text = 'hello\n';

    e.showPopup(
      PopupState<String>.create(
        title: 'test',
        items: [PopupItem(label: 'a', value: 'a')],
      ),
    );

    // Some terminals wrap emoji-picker input in bracketed paste markers
    e.onInput(utf8.encode('\x1b[200~😚\x1b[201~'));

    expect(e.file.text, 'hello\n', reason: 'paste must not touch the file');
    expect(e.popup?.filterText, '😚');
  });

  test('bracketed paste still inserts into file when no popup is open', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    e.file.text = 'hello\n';
    e.file.cursor = 0;

    e.onInput(utf8.encode('\x1b[200~😚\x1b[201~'));

    expect(e.file.text, '😚hello\n');
  });
}
