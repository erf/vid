import 'package:test/test.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer_lines.dart';
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
import 'package:vid/position.dart';
import 'package:vid/terminal/test_terminal.dart';

void main() {
  test('motionCharNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    expect(CharNextMotion().run(e, f, Position(c: 0, l: 0)), Position(c: 1, l: 0));
    expect(CharNextMotion().run(e, f, Position(c: 2, l: 0)), Position(c: 3, l: 0));
    expect(CharNextMotion().run(e, f, Position(c: 3, l: 0)), Position(c: 0, l: 1));
    expect(CharNextMotion().run(e, f, Position(c: 0, l: 1)), Position(c: 1, l: 1));
    expect(CharNextMotion().run(e, f, Position(c: 2, l: 1)), Position(c: 3, l: 1));
  });

  test('motionCharPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    expect(CharPrevMotion().run(e, f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(CharPrevMotion().run(e, f, Position(c: 2, l: 0)), Position(c: 1, l: 0));
    expect(CharPrevMotion().run(e, f, Position(c: 0, l: 1)), Position(c: 3, l: 0));
    expect(CharPrevMotion().run(e, f, Position(c: 2, l: 1)), Position(c: 1, l: 1));
  });

  test('motion.lineUp', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    expect(LineUpMotion().run(e, f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(LineUpMotion().run(e, f, Position(c: 2, l: 0)), Position(c: 2, l: 0));
    expect(LineUpMotion().run(e, f, Position(c: 0, l: 1)), Position(c: 0, l: 0));
    expect(LineUpMotion().run(e, f, Position(c: 2, l: 1)), Position(c: 2, l: 0));
  });

  test('motion.lineUp with emojis', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcdef\n😎😍👽\nghijkl\n';
    f.createLines(e);
    expect(LineUpMotion().run(e, f, Position(c: 2, l: 2)), Position(c: 1, l: 1));
    expect(LineUpMotion().run(e, f, Position(c: 1, l: 1)), Position(c: 2, l: 0));
  });

  test('motion.lineDown', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    expect(LineDownMotion().run(e, f, Position(c: 0, l: 0)), Position(c: 0, l: 1));
    expect(LineDownMotion().run(e, f, Position(c: 2, l: 0)), Position(c: 2, l: 1));
    expect(LineDownMotion().run(e, f, Position(c: 0, l: 1)), Position(c: 0, l: 1));
    expect(LineDownMotion().run(e, f, Position(c: 2, l: 1)), Position(c: 2, l: 1));
  });

  test('motion.lineDown with emojis', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcdef\n😎😍👽\nghijkl\n';
    f.createLines(e);
    expect(LineDownMotion().run(e, f, Position(c: 2, l: 0)), Position(c: 1, l: 1));
    expect(LineDownMotion().run(e, f, Position(c: 1, l: 1)), Position(c: 2, l: 2));
  });

  test('motionFileStart', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    expect(
      FileStartMotion().run(e, f, Position(c: 0, l: 0)),
      Position(c: 0, l: 0),
    );
    expect(
      FileStartMotion().run(e, f, Position(c: 2, l: 0)),
      Position(c: 0, l: 0),
    );
    expect(
      FileStartMotion().run(e, f, Position(c: 0, l: 1)),
      Position(c: 0, l: 0),
    );
    expect(
      FileStartMotion().run(e, f, Position(c: 2, l: 1)),
      Position(c: 0, l: 0),
    );
  });

  test('motionFileEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e);
    expect(FileEndMotion().run(e, f, Position(c: 0, l: 0)), Position(c: 0, l: 1));
    expect(FileEndMotion().run(e, f, Position(c: 2, l: 0)), Position(c: 0, l: 1));
    expect(FileEndMotion().run(e, f, Position(c: 0, l: 1)), Position(c: 0, l: 1));
    expect(FileEndMotion().run(e, f, Position(c: 2, l: 1)), Position(c: 0, l: 1));
  });

  test('motionWordNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi\njkl mno pqr\n';
    f.createLines(e);
    expect(WordNextMotion().run(e, f, Position(c: 0, l: 0)), Position(c: 4, l: 0));
    expect(WordNextMotion().run(e, f, Position(c: 3, l: 0)), Position(c: 4, l: 0));
    expect(WordNextMotion().run(e, f, Position(c: 4, l: 0)), Position(c: 8, l: 0));
    expect(WordNextMotion().run(e, f, Position(c: 8, l: 0)), Position(c: 0, l: 1));
    expect(WordNextMotion().run(e, f, Position(c: 2, l: 1)), Position(c: 4, l: 1));
    expect(WordNextMotion().run(e, f, Position(c: 2, l: 1)), Position(c: 4, l: 1));
  });

  test('motionWordCapNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc,def ghi\n';
    f.createLines(e);
    expect(
      WordCapNextMotion().run(e, f, Position(c: 0, l: 0)),
      Position(c: 8, l: 0),
    );
  });

  test('motionWordEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi\njkl mno pqr\n';
    f.createLines(e);
    expect(WordEndMotion().run(e, f, Position(c: 0, l: 0)), Position(c: 2, l: 0));
    expect(WordEndMotion().run(e, f, Position(c: 3, l: 0)), Position(c: 6, l: 0));
    expect(WordEndMotion().run(e, f, Position(c: 4, l: 0)), Position(c: 6, l: 0));
    expect(WordEndMotion().run(e, f, Position(c: 8, l: 0)), Position(c: 10, l: 0));
    expect(WordEndMotion().run(e, f, Position(c: 10, l: 0)), Position(c: 2, l: 1));
    expect(WordEndMotion().run(e, f, Position(c: 2, l: 1)), Position(c: 6, l: 1));
  });

  test('motionWordPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    f.createLines(e);
    expect(WordPrevMotion().run(e, f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(WordPrevMotion().run(e, f, Position(c: 3, l: 0)), Position(c: 0, l: 0));
    expect(WordPrevMotion().run(e, f, Position(c: 4, l: 0)), Position(c: 0, l: 0));
    expect(WordPrevMotion().run(e, f, Position(c: 5, l: 0)), Position(c: 4, l: 0));
    expect(WordPrevMotion().run(e, f, Position(c: 4, l: 1)), Position(c: 0, l: 1));
    expect(WordPrevMotion().run(e, f, Position(c: 0, l: 1)), Position(c: 8, l: 0));
  });

  test('motionWordCapPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def, ghi\n';
    f.createLines(e);
    expect(
      WordCapPrevMotion().run(e, f, Position(c: 9, l: 0)),
      Position(c: 4, l: 0),
    );
  });

  test('motionWordEndPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    f.createLines(e);
    expect(
      WordEndPrevMotion().run(e, f, Position(c: 4, l: 0)),
      Position(c: 2, l: 0),
    );
    expect(
      WordEndPrevMotion().run(e, f, Position(c: 8, l: 0)),
      Position(c: 6, l: 0),
    );
    expect(
      WordEndPrevMotion().run(e, f, Position(c: 10, l: 0)),
      Position(c: 6, l: 0),
    );
    expect(
      WordEndPrevMotion().run(e, f, Position(c: 1, l: 1)),
      Position(c: 10, l: 0),
    );
  });

  test('motionFindWordOnCursorNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'det er fint, fint er det saus\n';
    f.createLines(e);
    expect(
      SameWordNextMotion().run(e, f, Position(l: 0, c: 0)),
      Position(l: 0, c: 21),
    );
    expect(
      SameWordNextMotion().run(e, f, Position(l: 0, c: 10)),
      Position(l: 0, c: 13),
    );
    expect(
      SameWordNextMotion().run(e, f, Position(l: 0, c: 27)),
      Position(l: 0, c: 25),
    );
  });

  test('motionFindWordOnCursorPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'det er fint, fint er det saus\n';
    f.createLines(e);
    expect(
      SameWordPrevMotion().run(e, f, Position(l: 0, c: 15)),
      Position(l: 0, c: 7),
    );
    expect(
      SameWordPrevMotion().run(e, f, Position(l: 0, c: 27)),
      Position(l: 0, c: 25),
    );
  });

  test('motionFirstNoneBlank', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = '  abc\n';
    f.createLines(e);
    expect(
      FirstNonBlankMotion().run(e, f, Position(l: 0, c: 0)),
      Position(l: 0, c: 2),
    );
    expect(
      FirstNonBlankMotion().run(e, f, Position(l: 0, c: 1)),
      Position(l: 0, c: 2),
    );
    expect(
      FirstNonBlankMotion().run(e, f, Position(l: 0, c: 2)),
      Position(l: 0, c: 2),
    );
    expect(
      FirstNonBlankMotion().run(e, f, Position(l: 0, c: 3)),
      Position(l: 0, c: 2),
    );
    expect(
      FirstNonBlankMotion().run(e, f, Position(l: 0, c: 5)),
      Position(l: 0, c: 2),
    );
  });

  test('motionLineEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def\nghi jkl\n';
    f.createLines(e);
    expect(LineEndMotion().run(e, f, Position(l: 0, c: 0)), Position(l: 0, c: 7));
    expect(LineEndMotion().run(e, f, Position(l: 0, c: 3)), Position(l: 0, c: 7));
    expect(LineEndMotion().run(e, f, Position(l: 1, c: 0)), Position(l: 1, c: 7));
    expect(LineEndMotion().run(e, f, Position(l: 1, c: 3)), Position(l: 1, c: 7));
  });

  test('FindNextCharMotion with dot', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'test.\n';
    f.createLines(e);
    expect(
      FindNextCharMotion(c: '.').run(e, f, Position(l: 0, c: 0)),
      Position(l: 0, c: 4),
    );
  });

  test('FindPrevCharMotion with dot', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'hello. test.\n';
    f.createLines(e);
    expect(
      FindPrevCharMotion(c: '.').run(e, f, Position(l: 0, c: 10)),
      Position(l: 0, c: 5),
    );
  });
}
