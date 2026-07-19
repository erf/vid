import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/string_ext.dart';

/// Config with no gutter, so contentWidth == terminal width.
const _charConfig = Config(
  wrapMode: WrapMode.char,
  syntaxHighlighting: false,
  showLineNumbers: false,
  showDiagnosticSigns: false,
);
const _wordConfig = Config(
  wrapMode: WrapMode.word,
  syntaxHighlighting: false,
  showLineNumbers: false,
  showDiagnosticSigns: false,
);

final _ansi = RegExp(r'\x1b\[[0-9;]*[A-Za-z]');

String _strip(String s) => s.replaceAll(_ansi, '');

void main() {
  Editor editorWith(Config config, String text, {int width = 10}) {
    final e = Editor(
      terminal: TestTerminal(width: width, height: 10),
      redraw: false,
      config: config,
    );
    e.file.text = text;
    return e;
  }

  /// Draw and return content screen rows with ANSI escapes stripped.
  List<String> drawRows(Editor e) {
    e.draw();
    final out = (e.terminal as TestTerminal).takeOutput();
    return out.split('\x1b[2J').last.split('\n').map(_strip).toList();
  }

  group('char wrap', () {
    test('CJK chunks stay within content width and reassemble the line', () {
      const line = '你好世界你'; // 5 wide chars = 10 cols
      final e = editorWith(_charConfig, '$line\n', width: 5);
      final rows = drawRows(e);

      expect(rows[0], '你好'); // 4 cols
      expect(rows[1], '世界'); // 4 cols
      expect(rows[2], startsWith('你')); // 2 cols + newline symbol
      for (final row in rows.take(2)) {
        expect(row.renderLength(), lessThanOrEqualTo(5));
      }
    });

    test('emoji chunks never split a cluster or exceed width', () {
      const line = '😀😀😀'; // 3 emoji = 6 cols
      final e = editorWith(_charConfig, '$line\n', width: 5);
      final rows = drawRows(e);

      expect(rows[0], '😀😀'); // 4 cols; third would straddle, deferred
      expect(rows[1], startsWith('😀'));
      expect(rows[0].renderLength(), lessThanOrEqualTo(5));
    });

    test('layout wrap positions use render columns', () {
      const line = '你好世界你'; // 10 cols, wraps into 3 rows at width 5
      final e = editorWith(_charConfig, '$line\n', width: 5);
      e.file.cursor = 8; // last 你 (UTF-16: 2 units per char)
      drawRows(e);
      final rowMap = e.renderer.screenRowMap;

      // wrapCol is a render-column offset, not a UTF-16 index.
      expect(rowMap[0].wrapCol, 0);
      expect(rowMap[1].wrapCol, 4);
      expect(rowMap[2].wrapCol, 8);
    });

    test('ASCII wrap is unchanged', () {
      const line = 'abcdefghij'; // 10 cols
      final e = editorWith(_charConfig, '$line\n', width: 4);
      final rows = drawRows(e);

      expect(rows[0], 'abcd');
      expect(rows[1], 'efgh');
      expect(rows[2], startsWith('ij'));
    });
  });

  group('word wrap', () {
    test('breaks at spaces with wide chars, within width', () {
      const line = '你好 世界 你好'; // 4-col words separated by spaces
      final e = editorWith(_wordConfig, '$line\n', width: 7);
      final rows = drawRows(e);

      expect(rows[0], '你好 '); // breaks after space (5 cols)
      expect(rows[1], '世界 ');
      expect(rows[2], startsWith('你好'));
      expect('${rows[0]}${rows[1]}你好', line);
      for (final row in rows.take(3)) {
        expect(row.renderLength(), lessThanOrEqualTo(7));
      }
    });

    test('word wrap never splits a grapheme cluster', () {
      const line = 'ab 😀😀 cd';
      final e = editorWith(_wordConfig, '$line\n', width: 6);
      final rows = drawRows(e);

      // Row 1: 'ab 😀' fills 5 cols; the space (col 2) is not in the latter
      // half, so no break. Row 2: '😀 cd ' breaks after the space at col 8.
      // Both emoji stay intact; clusters are never split.
      expect(rows[0], 'ab 😀');
      expect(rows[1], '😀 cd ');
      expect(rows[0] + rows[1].trimRight(), line);
      for (final row in rows.take(2)) {
        expect(row.renderLength(), lessThanOrEqualTo(6));
      }
    });
  });
}
