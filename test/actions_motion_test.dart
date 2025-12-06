import 'package:test/test.dart';
import 'package:vid/actions/motions.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/terminal/test_terminal.dart';

void main() {
  test('motionCharNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    // Test moving from offset 0 (char 'a')
    expect(Motions.charNext(e, f, 0), 1); // a -> b
    expect(Motions.charNext(e, f, 2), 3); // c -> \n
    expect(Motions.charNext(e, f, 3), 4); // \n -> d
    expect(Motions.charNext(e, f, 4), 5); // d -> e
    expect(Motions.charNext(e, f, 6), 7); // f -> \n
  });

  test('motionCharPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    expect(Motions.charPrev(e, f, 0), 0); // at start, stay
    expect(Motions.charPrev(e, f, 2), 1); // c -> b
    expect(Motions.charPrev(e, f, 4), 3); // d -> \n
    expect(Motions.charPrev(e, f, 6), 5); // f -> e
  });

  test('motion.lineUp', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    // From line 0, stay at line 0
    expect(Motions.lineUp(e, f, 0), 0);
    expect(Motions.lineUp(e, f, 2), 2);
    // From line 1, go to line 0
    expect(Motions.lineUp(e, f, 4), 0); // d -> a (same column)
    expect(Motions.lineUp(e, f, 6), 2); // f -> c (same column)
  });

  test('motion.lineUp with emojis', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcdef\n😎😍👽\nghijkl\n';
    // Line 0: 'abcdef\n' (0-6), Line 1: '😎😍👽\n' (7-13), Line 2: 'ghijkl\n' (14-20)
    // From line 2 col 2 (offset 16 = 'i') -> should go to line 1
    int line2Col2 = 14 + 2; // 16 = 'i' in 'ghijkl'
    int result = Motions.lineUp(e, f, line2Col2);
    // Should land on line 1 (the emoji line)
    expect(f.lineNumber(result), 1);
  });

  test('motion.lineDown', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    // From line 0, go to line 1
    expect(Motions.lineDown(e, f, 0), 4); // a -> d
    expect(Motions.lineDown(e, f, 2), 6); // c -> f
    // From line 1, stay at line 1 (last line)
    expect(Motions.lineDown(e, f, 4), 4);
    expect(Motions.lineDown(e, f, 6), 6);
  });

  test('motion.lineDown with emojis', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcdef\n😎😍👽\nghijkl\n';
    // From line 0 col 2 -> line 1 (should land on appropriate grapheme)
    int result = Motions.lineDown(e, f, 2);
    expect(f.lineNumber(result), 1);
  });

  test('motionFileStart', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    expect(Motions.fileStart(e, f, 0), 0);
    expect(Motions.fileStart(e, f, 2), 0);
    expect(Motions.fileStart(e, f, 4), 0);
    expect(Motions.fileStart(e, f, 6), 0);
  });

  test('motionFileEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    // Should go to start of last line
    expect(Motions.fileEnd(e, f, 0), 4);
    expect(Motions.fileEnd(e, f, 2), 4);
    expect(Motions.fileEnd(e, f, 4), 4);
    expect(Motions.fileEnd(e, f, 6), 4);
  });

  test('motionWordNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi\njkl mno pqr\n';
    expect(Motions.wordNext(e, f, 0), 4); // abc -> def
    expect(Motions.wordNext(e, f, 3), 4); // space -> def
    expect(Motions.wordNext(e, f, 4), 8); // def -> ghi
    expect(Motions.wordNext(e, f, 8), 12); // ghi -> jkl (next line)
    expect(Motions.wordNext(e, f, 14), 16); // jkl -> mno
  });

  test('motionWordCapNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc,def ghi\n';
    // WORD skips punctuation
    expect(Motions.wordCapNext(e, f, 0), 8); // abc,def -> ghi
  });

  test('motionWordEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi\njkl mno pqr\n';
    expect(Motions.wordEnd(e, f, 0), 2); // abc -> c
    expect(Motions.wordEnd(e, f, 3), 6); // space -> f
    expect(Motions.wordEnd(e, f, 4), 6); // def -> f
    expect(Motions.wordEnd(e, f, 8), 10); // ghi -> i
    expect(Motions.wordEnd(e, f, 10), 14); // i -> l (next line)
  });

  test('motionWordPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    expect(Motions.wordPrev(e, f, 0), 0); // at start, stay
    // Note: emoji sequence has length 14 bytes
    // 'abc d❤️‍🔥f ghi\n' = 'abc ' (4) + 'd' (1) + emoji (14) + 'f ghi\n' (6)
    int emojiStart = 5;
    expect(Motions.wordPrev(e, f, 4), 0); // space -> abc
    expect(Motions.wordPrev(e, f, emojiStart), 4); // d -> space/abc
  });

  test('motionWordCapPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def, ghi\n';
    // WORD skips punctuation when going backwards
    expect(Motions.wordCapPrev(e, f, 9), 4); // ghi -> def,
  });

  test('motionWordEndPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    // Going backwards to end of previous word
    expect(Motions.wordEndPrev(e, f, 4), 2); // space -> c
  });

  test('motionFindWordOnCursorNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'det er fint, fint er det saus\n';
    // Find next occurrence of word under cursor
    expect(Motions.sameWordNext(e, f, 0), 21); // det -> det
    expect(Motions.sameWordNext(e, f, 7), 13); // fint -> fint
  });

  test('motionFindWordOnCursorPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'det er fint, fint er det saus\n';
    expect(Motions.sameWordPrev(e, f, 13), 7); // fint -> fint
  });

  test('motionFirstNoneBlank', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = '  abc\n';
    // Should go to first non-blank character
    expect(Motions.firstNonBlank(e, f, 0), 2);
    expect(Motions.firstNonBlank(e, f, 1), 2);
    expect(Motions.firstNonBlank(e, f, 2), 2);
    expect(Motions.firstNonBlank(e, f, 3), 2);
    expect(Motions.firstNonBlank(e, f, 5), 2);
  });

  test('motionLineEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def\nghi jkl\n';
    // Should go to last character of line (before \n)
    expect(Motions.lineEnd(e, f, 0), 6); // a -> f (offset 6)
    expect(Motions.lineEnd(e, f, 3), 6); // space -> f
    expect(Motions.lineEnd(e, f, 8), 14); // g -> l (offset 14)
    expect(Motions.lineEnd(e, f, 11), 14); // space -> l
  });

  test('FindNextCharMotion with dot', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'test.\n';
    f.edit.findStr = '.';
    expect(Motions.findNextChar(e, f, 0), 4);
  });

  test('FindPrevCharMotion with dot', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'hello. test.\n';
    f.edit.findStr = '.';
    expect(Motions.findPrevChar(e, f, 10), 5);
  });

  test(
    'motionWordPrev with many lines (tests limited search with fallback)',
    () {
      final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
      final f = e.file;
      // Create text with many lines - word at start, then many empty-ish lines
      final sb = StringBuffer();
      sb.write('firstword\n');
      for (int i = 0; i < 50; i++) {
        sb.write('line $i with words here\n');
      }
      f.text = sb.toString();

      // From end of file, should be able to navigate backwards
      final lastLineStart = f.text.lastIndexOf('\n', f.text.length - 2) + 1;
      final offset = lastLineStart + 5; // somewhere in last line

      // Should find previous word on same line
      final result = Motions.wordPrev(e, f, offset);
      expect(result < offset, true);

      // Should eventually be able to reach the first word
      var pos = f.text.length - 2;
      for (int i = 0; i < 500 && pos > 0; i++) {
        final newPos = Motions.wordPrev(e, f, pos);
        if (newPos == pos) break; // stuck
        pos = newPos;
      }
      expect(pos, 0); // should reach "firstword" at offset 0
    },
  );
}
