import 'package:test/test.dart';
import 'package:vid/actions_motion.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/position.dart';
import 'package:vid/terminal.dart';

void main() {
  test('motionCharNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.charNext(f, Position(c: 0, l: 0)), Position(c: 1, l: 0));
    expect(Motions.charNext(f, Position(c: 2, l: 0)), Position(c: 3, l: 0));
    expect(Motions.charNext(f, Position(c: 3, l: 0)), Position(c: 0, l: 1));
    expect(Motions.charNext(f, Position(c: 0, l: 1)), Position(c: 1, l: 1));
    expect(Motions.charNext(f, Position(c: 2, l: 1)), Position(c: 3, l: 1));
  });

  test('motionCharPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.charPrev(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(Motions.charPrev(f, Position(c: 2, l: 0)), Position(c: 1, l: 0));
    expect(Motions.charPrev(f, Position(c: 0, l: 1)), Position(c: 3, l: 0));
    expect(Motions.charPrev(f, Position(c: 2, l: 1)), Position(c: 1, l: 1));
  });

  test('motion.lineUp', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.lineUp(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(Motions.lineUp(f, Position(c: 2, l: 0)), Position(c: 2, l: 0));
    expect(Motions.lineUp(f, Position(c: 0, l: 1)), Position(c: 0, l: 0));
    expect(Motions.lineUp(f, Position(c: 2, l: 1)), Position(c: 2, l: 0));
  });

  test('motion.lineUp with emojis', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcdef\n😎😍👽\nghijkl\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.lineUp(f, Position(c: 2, l: 2)), Position(c: 1, l: 1));
    expect(Motions.lineUp(f, Position(c: 1, l: 1)), Position(c: 2, l: 0));
  });

  test('motion.lineDown', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.lineDown(f, Position(c: 0, l: 0)), Position(c: 0, l: 1));
    expect(Motions.lineDown(f, Position(c: 2, l: 0)), Position(c: 2, l: 1));
    expect(Motions.lineDown(f, Position(c: 0, l: 1)), Position(c: 0, l: 1));
    expect(Motions.lineDown(f, Position(c: 2, l: 1)), Position(c: 2, l: 1));
  });

  test('motion.lineDown with emojis', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abcdef\n😎😍👽\nghijkl\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.lineDown(f, Position(c: 2, l: 0)), Position(c: 1, l: 1));
    expect(Motions.lineDown(f, Position(c: 1, l: 1)), Position(c: 2, l: 2));
  });

  test('motionFileStart', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.fileStart(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(Motions.fileStart(f, Position(c: 2, l: 0)), Position(c: 0, l: 0));
    expect(Motions.fileStart(f, Position(c: 0, l: 1)), Position(c: 0, l: 0));
    expect(Motions.fileStart(f, Position(c: 2, l: 1)), Position(c: 0, l: 0));
  });

  test('motionFileEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc\ndef\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.fileEnd(f, Position(c: 0, l: 0)), Position(c: 0, l: 1));
    expect(Motions.fileEnd(f, Position(c: 2, l: 0)), Position(c: 0, l: 1));
    expect(Motions.fileEnd(f, Position(c: 0, l: 1)), Position(c: 0, l: 1));
    expect(Motions.fileEnd(f, Position(c: 2, l: 1)), Position(c: 0, l: 1));
  });

  test('motionWordNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi\njkl mno pqr\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.wordNext(f, Position(c: 0, l: 0)), Position(c: 4, l: 0));
    expect(Motions.wordNext(f, Position(c: 3, l: 0)), Position(c: 4, l: 0));
    expect(Motions.wordNext(f, Position(c: 4, l: 0)), Position(c: 8, l: 0));
    expect(Motions.wordNext(f, Position(c: 8, l: 0)), Position(c: 0, l: 1));
    expect(Motions.wordNext(f, Position(c: 2, l: 1)), Position(c: 4, l: 1));
    expect(Motions.wordNext(f, Position(c: 2, l: 1)), Position(c: 4, l: 1));
  });

  test('motionWordCapNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc,def ghi\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.wordCapNext(f, Position(c: 0, l: 0)), Position(c: 8, l: 0));
  });

  test('motionWordEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def ghi\njkl mno pqr\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.wordEnd(f, Position(c: 0, l: 0)), Position(c: 2, l: 0));
    expect(Motions.wordEnd(f, Position(c: 3, l: 0)), Position(c: 6, l: 0));
    expect(Motions.wordEnd(f, Position(c: 4, l: 0)), Position(c: 6, l: 0));
    expect(Motions.wordEnd(f, Position(c: 8, l: 0)), Position(c: 10, l: 0));
    expect(Motions.wordEnd(f, Position(c: 10, l: 0)), Position(c: 2, l: 1));
    expect(Motions.wordEnd(f, Position(c: 2, l: 1)), Position(c: 6, l: 1));
  });

  test('motionWordPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.wordPrev(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(Motions.wordPrev(f, Position(c: 3, l: 0)), Position(c: 0, l: 0));
    expect(Motions.wordPrev(f, Position(c: 4, l: 0)), Position(c: 0, l: 0));
    expect(Motions.wordPrev(f, Position(c: 5, l: 0)), Position(c: 4, l: 0));
    expect(Motions.wordPrev(f, Position(c: 4, l: 1)), Position(c: 0, l: 1));
    expect(Motions.wordPrev(f, Position(c: 0, l: 1)), Position(c: 8, l: 0));
  });

  test('motionWordCapPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def, ghi\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.wordCapPrev(f, Position(c: 9, l: 0)), Position(c: 4, l: 0));
  });

  test('motionWordEndPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    f.createLines(e, WrapMode.none);
    expect(Motions.wordEndPrev(f, Position(c: 4, l: 0)), Position(c: 2, l: 0));
    expect(Motions.wordEndPrev(f, Position(c: 8, l: 0)), Position(c: 6, l: 0));
    expect(Motions.wordEndPrev(f, Position(c: 10, l: 0)), Position(c: 6, l: 0));
    expect(Motions.wordEndPrev(f, Position(c: 1, l: 1)), Position(c: 10, l: 0));
  });

  test('motionFindWordOnCursorNext', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'det er fint, fint er det saus\n';
    f.createLines(e, WrapMode.none);
    expect(
        Motions.sameWordNext(f, Position(l: 0, c: 0)), Position(l: 0, c: 21));
    expect(
        Motions.sameWordNext(f, Position(l: 0, c: 10)), Position(l: 0, c: 13));
    expect(
        Motions.sameWordNext(f, Position(l: 0, c: 27)), Position(l: 0, c: 25));
  });

  test('motionFindWordOnCursorPrev', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'det er fint, fint er det saus\n';
    f.createLines(e, WrapMode.none);
    expect(
        Motions.sameWordPrev(f, Position(l: 0, c: 15)), Position(l: 0, c: 7));
    expect(
        Motions.sameWordPrev(f, Position(l: 0, c: 27)), Position(l: 0, c: 25));
  });

  test('motionFirstNoneBlank', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = '  abc\n';
    f.createLines(e, WrapMode.none);
    expect(
        Motions.firstNonBlank(f, Position(l: 0, c: 0)), Position(l: 0, c: 2));
    expect(
        Motions.firstNonBlank(f, Position(l: 0, c: 1)), Position(l: 0, c: 2));
    expect(
        Motions.firstNonBlank(f, Position(l: 0, c: 2)), Position(l: 0, c: 2));
    expect(
        Motions.firstNonBlank(f, Position(l: 0, c: 3)), Position(l: 0, c: 2));
    expect(
        Motions.firstNonBlank(f, Position(l: 0, c: 5)), Position(l: 0, c: 2));
  });

  test('motionLineEnd', () {
    final e = Editor(terminal: TestTerminal(80, 24), redraw: false);
    final f = e.file;
    f.text = 'abc def\nghi jkl\n';
    f.createLines(e, WrapMode.none);
    expect(
        Motions.lineEnd(f, Position(l: 0, c: 0), false), Position(l: 0, c: 7));
    expect(
        Motions.lineEnd(f, Position(l: 0, c: 3), false), Position(l: 0, c: 7));
    expect(
        Motions.lineEnd(f, Position(l: 1, c: 0), false), Position(l: 1, c: 7));
    expect(
        Motions.lineEnd(f, Position(l: 1, c: 3), false), Position(l: 1, c: 7));
  });
}
