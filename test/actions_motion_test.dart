import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer_nav.dart';
import 'package:vid/motions/char_next_motion.dart';
import 'package:vid/motions/char_prev_motion.dart';
import 'package:vid/motions/file_end_motion.dart';
import 'package:vid/motions/file_start_motion.dart';
import 'package:vid/motions/find_next_char_motion.dart';
import 'package:vid/motions/find_prev_char_motion.dart';
import 'package:vid/motions/first_non_blank_motion.dart';
import 'package:vid/motions/line_down_motion.dart';
import 'package:vid/motions/line_end_motion.dart';
import 'package:vid/motions/line_up_motion.dart';
import 'package:vid/motions/same_word_next_motion.dart';
import 'package:vid/motions/same_word_prev_motion.dart';
import 'package:vid/motions/word_cap_next_motion.dart';
import 'package:vid/motions/word_cap_prev_motion.dart';
import 'package:vid/motions/word_end_motion.dart';
import 'package:vid/motions/word_end_prev_motion.dart';
import 'package:vid/motions/word_next_motion.dart';
import 'package:vid/motions/word_prev_motion.dart';
import 'package:vid/terminal/test_terminal.dart';

void main() {
  test('motionCharNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    // Test moving from offset 0 (char 'a')
    expect(CharNextMotion().run(e, f, 0), 1); // a -> b
    expect(CharNextMotion().run(e, f, 2), 3); // c -> \n
    expect(CharNextMotion().run(e, f, 3), 4); // \n -> d
    expect(CharNextMotion().run(e, f, 4), 5); // d -> e
    expect(CharNextMotion().run(e, f, 6), 7); // f -> \n
  });

  test('motionCharPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    expect(CharPrevMotion().run(e, f, 0), 0); // at start, stay
    expect(CharPrevMotion().run(e, f, 2), 1); // c -> b
    expect(CharPrevMotion().run(e, f, 4), 3); // d -> \n
    expect(CharPrevMotion().run(e, f, 6), 5); // f -> e
  });

  test('motion.lineUp', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    // From line 0, stay at line 0
    expect(LineUpMotion().run(e, f, 0), 0);
    expect(LineUpMotion().run(e, f, 2), 2);
    // From line 1, go to line 0
    expect(LineUpMotion().run(e, f, 4), 0); // d -> a (same column)
    expect(LineUpMotion().run(e, f, 6), 2); // f -> c (same column)
  });

  test('motion.lineUp with emojis', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcdef\n😎😍👽\nghijkl\n';
    // Line 0: 'abcdef\n' (0-6), Line 1: '😎😍👽\n' (7-13), Line 2: 'ghijkl\n' (14-20)
    // From line 2 col 2 (offset 16 = 'i') -> should go to line 1
    int line2Col2 = 14 + 2; // 16 = 'i' in 'ghijkl'
    int result = LineUpMotion().run(e, f, line2Col2);
    // Should land on line 1 (the emoji line)
    expect(f.lineNumber(result), 1);
  });

  test('motion.lineDown', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    // From line 0, go to line 1
    expect(LineDownMotion().run(e, f, 0), 4); // a -> d
    expect(LineDownMotion().run(e, f, 2), 6); // c -> f
    // From line 1, stay at line 1 (last line)
    expect(LineDownMotion().run(e, f, 4), 4);
    expect(LineDownMotion().run(e, f, 6), 6);
  });

  test('motion.lineDown with emojis', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcdef\n😎😍👽\nghijkl\n';
    // From line 0 col 2 -> line 1 (should land on appropriate grapheme)
    int result = LineDownMotion().run(e, f, 2);
    expect(f.lineNumber(result), 1);
  });

  test('motionFileStart', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    expect(FileStartMotion().run(e, f, 0), 0);
    expect(FileStartMotion().run(e, f, 2), 0);
    expect(FileStartMotion().run(e, f, 4), 0);
    expect(FileStartMotion().run(e, f, 6), 0);
  });

  test('motionFileEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    // Should go to start of last line
    expect(FileEndMotion().run(e, f, 0), 4);
    expect(FileEndMotion().run(e, f, 2), 4);
    expect(FileEndMotion().run(e, f, 4), 4);
    expect(FileEndMotion().run(e, f, 6), 4);
  });

  test('motionWordNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi\njkl mno pqr\n';
    expect(WordNextMotion().run(e, f, 0), 4); // abc -> def
    expect(WordNextMotion().run(e, f, 3), 4); // space -> def
    expect(WordNextMotion().run(e, f, 4), 8); // def -> ghi
    expect(WordNextMotion().run(e, f, 8), 12); // ghi -> jkl (next line)
    expect(WordNextMotion().run(e, f, 14), 16); // jkl -> mno
  });

  test('motionWordCapNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc,def ghi\n';
    // WORD skips punctuation
    expect(WordCapNextMotion().run(e, f, 0), 8); // abc,def -> ghi
  });

  test('motionWordEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi\njkl mno pqr\n';
    expect(WordEndMotion().run(e, f, 0), 2); // abc -> c
    expect(WordEndMotion().run(e, f, 3), 6); // space -> f
    expect(WordEndMotion().run(e, f, 4), 6); // def -> f
    expect(WordEndMotion().run(e, f, 8), 10); // ghi -> i
    expect(WordEndMotion().run(e, f, 10), 14); // i -> l (next line)
  });

  test('motionWordPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    expect(WordPrevMotion().run(e, f, 0), 0); // at start, stay
    // Note: emoji sequence has length 14 bytes
    // 'abc d❤️‍🔥f ghi\n' = 'abc ' (4) + 'd' (1) + emoji (14) + 'f ghi\n' (6)
    int emojiStart = 5;
    expect(WordPrevMotion().run(e, f, 4), 0); // space -> abc
    expect(WordPrevMotion().run(e, f, emojiStart), 4); // d -> space/abc
  });

  test('motionWordCapPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def, ghi\n';
    // WORD skips punctuation when going backwards
    expect(WordCapPrevMotion().run(e, f, 9), 4); // ghi -> def,
  });

  test('motionWordEndPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    // Going backwards to end of previous word
    expect(WordEndPrevMotion().run(e, f, 4), 2); // space -> c
  });

  test('motionFindWordOnCursorNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'det er fint, fint er det saus\n';
    // Find next occurrence of word under cursor
    expect(SameWordNextMotion().run(e, f, 0), 21); // det -> det
    expect(SameWordNextMotion().run(e, f, 7), 13); // fint -> fint
  });

  test('motionFindWordOnCursorPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'det er fint, fint er det saus\n';
    expect(SameWordPrevMotion().run(e, f, 13), 7); // fint -> fint
  });

  test('motionFirstNoneBlank', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = '  abc\n';
    // Should go to first non-blank character
    expect(FirstNonBlankMotion().run(e, f, 0), 2);
    expect(FirstNonBlankMotion().run(e, f, 1), 2);
    expect(FirstNonBlankMotion().run(e, f, 2), 2);
    expect(FirstNonBlankMotion().run(e, f, 3), 2);
    expect(FirstNonBlankMotion().run(e, f, 5), 2);
  });

  test('motionLineEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def\nghi jkl\n';
    // Should go to last character of line (before \n)
    expect(LineEndMotion().run(e, f, 0), 6); // a -> f (offset 6)
    expect(LineEndMotion().run(e, f, 3), 6); // space -> f
    expect(LineEndMotion().run(e, f, 8), 14); // g -> l (offset 14)
    expect(LineEndMotion().run(e, f, 11), 14); // space -> l
  });

  test('FindNextCharMotion with dot', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'test.\n';
    expect(FindNextCharMotion(c: '.').run(e, f, 0), 4);
  });

  test('FindPrevCharMotion with dot', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'hello. test.\n';
    expect(FindPrevCharMotion(c: '.').run(e, f, 10), 5);
  });
}
