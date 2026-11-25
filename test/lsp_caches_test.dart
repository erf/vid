import 'package:test/test.dart';
import 'package:vid/features/lsp/lsp_caches.dart';
import 'package:vid/features/lsp/lsp_protocol.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/highlighting/token.dart';

SemanticToken _tok(int line, int character, int length) => SemanticToken(
  line: line,
  character: character,
  length: length,
  type: TokenType.keyword,
  modifiers: 0,
);

void main() {
  group('LspSemanticTokensCache.invalidateForEdit', () {
    const uri = 'file:///a.dart';

    /// Apply an edit to [before] and invalidate tokens accordingly.
    List<SemanticToken> edit(
      String before,
      int start,
      String oldText,
      String newText,
      List<SemanticToken> tokens,
    ) {
      final c = LspSemanticTokensCache();
      c.setBoth(uri, tokens);
      final f = FileBuffer();
      f.text = before.replaceRange(start, start + oldText.length, newText);
      c.invalidateForEdit(uri, f, start, oldText, newText);
      return c.getCurrent(uri);
    }

    String spans(List<SemanticToken> t) =>
        t.map((t) => '${t.line}:${t.character}+${t.length}').join(' ');

    test('insert between tokens keeps and shifts them', () {
      // 'foo bar\n' tokens foo(0,3) bar(4,3); insert 'xx' at col 3
      final t = edit('foo bar\n', 3, '', 'xx', [_tok(0, 0, 3), _tok(0, 4, 3)]);
      expect(spans(t), '0:0+3 0:6+3');
    });

    test('insert inside token grows it', () {
      final t = edit('foo bar\n', 1, '', 'x', [_tok(0, 0, 3), _tok(0, 4, 3)]);
      expect(spans(t), '0:0+4 0:5+3');
    });

    test('delete overlapping token drops only that token', () {
      // delete 'o' at col 1 of foo
      final t = edit('foo bar\n', 1, 'o', '', [_tok(0, 0, 3), _tok(0, 4, 3)]);
      expect(spans(t), '0:3+3');
    });

    test('newline insert keeps prefix tokens and shifts later lines', () {
      final t = edit('foo bar\nbaz\n', 3, '', '\n', [
        _tok(0, 0, 3),
        _tok(0, 4, 3),
        _tok(1, 0, 3),
      ]);
      expect(spans(t), '0:0+3 2:0+3');
    });
  });
}
