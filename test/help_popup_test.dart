import 'package:termio/termio.dart';
import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/modes.dart';
import 'package:vid/popup/help_popup.dart';

void main() {
  test('Ctrl+H opens help popup and Esc closes it', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'hello\n';

    e.input(Keys.ctrlH);
    expect(e.popup?.title, 'Keybindings');
    expect(f.mode, Mode.popup);

    e.input(Keys.escape);
    expect(e.popup, isNull);
    expect(f.mode, Mode.normal);
  });

  test(':help opens help popup', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    e.file.text = 'hello\n';

    e.input(':help\n');
    expect(e.popup?.title, 'Keybindings');
  });

  test('filter matches keys and descriptions', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    e.file.text = 'hello\n';

    e.input(':h\n');
    e.input('theme sel');
    final labels = e.popup!.items.map((i) => i.label).toList();
    expect(labels, hasLength(1));
    expect(labels.single, contains('Ctrl+T'));
  });

  test('items merge keys bound to the same action', () {
    final labels = HelpPopup.items().map((i) => i.label);
    expect(
      labels,
      contains(
        allOf(contains('normal'), contains('gr, Ctrl+R'), contains('find ')),
      ),
    );
    expect(
      labels,
      contains(allOf(contains(':help, :h, :keys'), endsWith('help'))),
    );
  });

  test('keyName and humanize', () {
    expect(HelpPopup.keyName(Keys.ctrlT), 'Ctrl+T');
    expect(HelpPopup.keyName(Keys.newline), 'Enter');
    expect(HelpPopup.keyName('gg'), 'gg');
    expect(HelpPopup.humanize('openThemeSelector'), 'open theme selector');
    expect(HelpPopup.humanize('insideWORD'), 'inside WORD');
  });
}
