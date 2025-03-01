import 'package:test/test.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
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
import 'package:vid/terminal_dummy.dart';

void main() {
  test('motionCharNext', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(CharNextMotion().run(f, Position(c: 0, l: 0)), Position(c: 1, l: 0));
    expect(CharNextMotion().run(f, Position(c: 2, l: 0)), Position(c: 3, l: 0));
    expect(CharNextMotion().run(f, Position(c: 3, l: 0)), Position(c: 0, l: 1));
    expect(CharNextMotion().run(f, Position(c: 0, l: 1)), Position(c: 1, l: 1));
    expect(CharNextMotion().run(f, Position(c: 2, l: 1)), Position(c: 3, l: 1));
  });

  test('motionCharPrev', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(CharPrevMotion().run(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(CharPrevMotion().run(f, Position(c: 2, l: 0)), Position(c: 1, l: 0));
    expect(CharPrevMotion().run(f, Position(c: 0, l: 1)), Position(c: 3, l: 0));
    expect(CharPrevMotion().run(f, Position(c: 2, l: 1)), Position(c: 1, l: 1));
  });

  test('motion.lineUp', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(LineUpMotion().run(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(LineUpMotion().run(f, Position(c: 2, l: 0)), Position(c: 2, l: 0));
    expect(LineUpMotion().run(f, Position(c: 0, l: 1)), Position(c: 0, l: 0));
    expect(LineUpMotion().run(f, Position(c: 2, l: 1)), Position(c: 2, l: 0));
  });

  test('motion.lineUp with emojis', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcdef\n😎😍👽\nghijkl\n';
    f.createLines(e, WrapMode.none);
    expect(LineUpMotion().run(f, Position(c: 2, l: 2)), Position(c: 1, l: 1));
    expect(LineUpMotion().run(f, Position(c: 1, l: 1)), Position(c: 2, l: 0));
  });

  test('motion.lineDown', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(LineDownMotion().run(f, Position(c: 0, l: 0)), Position(c: 0, l: 1));
    expect(LineDownMotion().run(f, Position(c: 2, l: 0)), Position(c: 2, l: 1));
    expect(LineDownMotion().run(f, Position(c: 0, l: 1)), Position(c: 0, l: 1));
    expect(LineDownMotion().run(f, Position(c: 2, l: 1)), Position(c: 2, l: 1));
  });

  test('motion.lineDown with emojis', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcdef\n😎😍👽\nghijkl\n';
    f.createLines(e, WrapMode.none);
    expect(LineDownMotion().run(f, Position(c: 2, l: 0)), Position(c: 1, l: 1));
    expect(LineDownMotion().run(f, Position(c: 1, l: 1)), Position(c: 2, l: 2));
  });

  test('motionFileStart', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(
      FileStartMotion().run(f, Position(c: 0, l: 0)),
      Position(c: 0, l: 0),
    );
    expect(
      FileStartMotion().run(f, Position(c: 2, l: 0)),
      Position(c: 0, l: 0),
    );
    expect(
      FileStartMotion().run(f, Position(c: 0, l: 1)),
      Position(c: 0, l: 0),
    );
    expect(
      FileStartMotion().run(f, Position(c: 2, l: 1)),
      Position(c: 0, l: 0),
    );
  });

  test('motionFileEnd', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(FileEndMotion().run(f, Position(c: 0, l: 0)), Position(c: 0, l: 1));
    expect(FileEndMotion().run(f, Position(c: 2, l: 0)), Position(c: 0, l: 1));
    expect(FileEndMotion().run(f, Position(c: 0, l: 1)), Position(c: 0, l: 1));
    expect(FileEndMotion().run(f, Position(c: 2, l: 1)), Position(c: 0, l: 1));
  });

  test('motionWordNext', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi\njkl mno pqr\n';
    f.createLines(e, WrapMode.none);
    expect(WordNextMotion().run(f, Position(c: 0, l: 0)), Position(c: 4, l: 0));
    expect(WordNextMotion().run(f, Position(c: 3, l: 0)), Position(c: 4, l: 0));
    expect(WordNextMotion().run(f, Position(c: 4, l: 0)), Position(c: 8, l: 0));
    expect(WordNextMotion().run(f, Position(c: 8, l: 0)), Position(c: 0, l: 1));
    expect(WordNextMotion().run(f, Position(c: 2, l: 1)), Position(c: 4, l: 1));
    expect(WordNextMotion().run(f, Position(c: 2, l: 1)), Position(c: 4, l: 1));
  });

  test('motionWordCapNext', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc,def ghi\n';
    f.createLines(e, WrapMode.none);
    expect(
      WordCapNextMotion().run(f, Position(c: 0, l: 0)),
      Position(c: 8, l: 0),
    );
  });

  test('motionWordEnd', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi\njkl mno pqr\n';
    f.createLines(e, WrapMode.none);
    expect(WordEndMotion().run(f, Position(c: 0, l: 0)), Position(c: 2, l: 0));
    expect(WordEndMotion().run(f, Position(c: 3, l: 0)), Position(c: 6, l: 0));
    expect(WordEndMotion().run(f, Position(c: 4, l: 0)), Position(c: 6, l: 0));
    expect(WordEndMotion().run(f, Position(c: 8, l: 0)), Position(c: 10, l: 0));
    expect(WordEndMotion().run(f, Position(c: 10, l: 0)), Position(c: 2, l: 1));
    expect(WordEndMotion().run(f, Position(c: 2, l: 1)), Position(c: 6, l: 1));
  });

  test('motionWordPrev', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    f.createLines(e, WrapMode.none);
    expect(WordPrevMotion().run(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(WordPrevMotion().run(f, Position(c: 3, l: 0)), Position(c: 0, l: 0));
    expect(WordPrevMotion().run(f, Position(c: 4, l: 0)), Position(c: 0, l: 0));
    expect(WordPrevMotion().run(f, Position(c: 5, l: 0)), Position(c: 4, l: 0));
    expect(WordPrevMotion().run(f, Position(c: 4, l: 1)), Position(c: 0, l: 1));
    expect(WordPrevMotion().run(f, Position(c: 0, l: 1)), Position(c: 8, l: 0));
  });

  test('motionWordCapPrev', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def, ghi\n';
    f.createLines(e, WrapMode.none);
    expect(
      WordCapPrevMotion().run(f, Position(c: 9, l: 0)),
      Position(c: 4, l: 0),
    );
  });

  test('motionWordEndPrev', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    f.createLines(e, WrapMode.none);
    expect(
      WordEndPrevMotion().run(f, Position(c: 4, l: 0)),
      Position(c: 2, l: 0),
    );
    expect(
      WordEndPrevMotion().run(f, Position(c: 8, l: 0)),
      Position(c: 6, l: 0),
    );
    expect(
      WordEndPrevMotion().run(f, Position(c: 10, l: 0)),
      Position(c: 6, l: 0),
    );
    expect(
      WordEndPrevMotion().run(f, Position(c: 1, l: 1)),
      Position(c: 10, l: 0),
    );
  });

  test('motionFindWordOnCursorNext', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'det er fint, fint er det saus\n';
    f.createLines(e, WrapMode.none);
    expect(
      SameWordNextMotion().run(f, Position(l: 0, c: 0)),
      Position(l: 0, c: 21),
    );
    expect(
      SameWordNextMotion().run(f, Position(l: 0, c: 10)),
      Position(l: 0, c: 13),
    );
    expect(
      SameWordNextMotion().run(f, Position(l: 0, c: 27)),
      Position(l: 0, c: 25),
    );
  });

  test('motionFindWordOnCursorPrev', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'det er fint, fint er det saus\n';
    f.createLines(e, WrapMode.none);
    expect(
      SameWordPrevMotion().run(f, Position(l: 0, c: 15)),
      Position(l: 0, c: 7),
    );
    expect(
      SameWordPrevMotion().run(f, Position(l: 0, c: 27)),
      Position(l: 0, c: 25),
    );
  });

  test('motionFirstNoneBlank', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = '  abc\n';
    f.createLines(e, WrapMode.none);
    expect(
      FirstNonBlankMotion().run(f, Position(l: 0, c: 0)),
      Position(l: 0, c: 2),
    );
    expect(
      FirstNonBlankMotion().run(f, Position(l: 0, c: 1)),
      Position(l: 0, c: 2),
    );
    expect(
      FirstNonBlankMotion().run(f, Position(l: 0, c: 2)),
      Position(l: 0, c: 2),
    );
    expect(
      FirstNonBlankMotion().run(f, Position(l: 0, c: 3)),
      Position(l: 0, c: 2),
    );
    expect(
      FirstNonBlankMotion().run(f, Position(l: 0, c: 5)),
      Position(l: 0, c: 2),
    );
  });

  test('motionLineEnd', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def\nghi jkl\n';
    f.createLines(e, WrapMode.none);
    expect(LineEndMotion().run(f, Position(l: 0, c: 0)), Position(l: 0, c: 7));
    expect(LineEndMotion().run(f, Position(l: 0, c: 3)), Position(l: 0, c: 7));
    expect(LineEndMotion().run(f, Position(l: 1, c: 0)), Position(l: 1, c: 7));
    expect(LineEndMotion().run(f, Position(l: 1, c: 3)), Position(l: 1, c: 7));
  });

  test('FindNextCharMotion with dot', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'test.\n';
    f.createLines(e, WrapMode.none);
    expect(
      FindNextCharMotion(c: '.').run(f, Position(l: 0, c: 0)),
      Position(l: 0, c: 4),
    );
  });

  test('FindPrevCharMotion with dot', () {
    final e = Editor(terminal: TerminalDummy(80, 24), redraw: false);
    final f = e.file;
    f.text = 'hello. test.\n';
    f.createLines(e, WrapMode.none);
    expect(
      FindPrevCharMotion(c: '.').run(f, Position(l: 0, c: 10)),
      Position(l: 0, c: 5),
    );
  });
}
