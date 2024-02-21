import 'package:test/test.dart';
import 'package:vid/actions_motion.dart';
import 'package:vid/config.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/position.dart';

void main() {
  test('motionCharNext', () {
    final f = FileBuffer(text: 'abc\ndef\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.charNext(f, Position(c: 0, l: 0)), Position(c: 1, l: 0));
    expect(Motions.charNext(f, Position(c: 2, l: 0)), Position(c: 3, l: 0));
    expect(Motions.charNext(f, Position(c: 3, l: 0)), Position(c: 0, l: 1));
    expect(Motions.charNext(f, Position(c: 0, l: 1)), Position(c: 1, l: 1));
    expect(Motions.charNext(f, Position(c: 2, l: 1)), Position(c: 3, l: 1));
  });

  test('motionCharPrev', () {
    final f = FileBuffer(text: 'abc\ndef\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.charPrev(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(Motions.charPrev(f, Position(c: 2, l: 0)), Position(c: 1, l: 0));
    expect(Motions.charPrev(f, Position(c: 0, l: 1)), Position(c: 3, l: 0));
    expect(Motions.charPrev(f, Position(c: 2, l: 1)), Position(c: 1, l: 1));
  });

  test('motion.lineUp', () {
    final f = FileBuffer(text: 'abc\ndef\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.lineUp(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(Motions.lineUp(f, Position(c: 2, l: 0)), Position(c: 2, l: 0));
    expect(Motions.lineUp(f, Position(c: 0, l: 1)), Position(c: 0, l: 0));
    expect(Motions.lineUp(f, Position(c: 2, l: 1)), Position(c: 2, l: 0));
  });

  test('motion.lineUp with emojis', () {
    final f = FileBuffer(text: 'abcdef\n😎😍👽\nghijkl\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.lineUp(f, Position(c: 2, l: 2)), Position(c: 1, l: 1));
    expect(Motions.lineUp(f, Position(c: 1, l: 1)), Position(c: 2, l: 0));
  });

  test('motion.lineDown', () {
    final f = FileBuffer(text: 'abc\ndef\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.lineDown(f, Position(c: 0, l: 0)), Position(c: 0, l: 1));
    expect(Motions.lineDown(f, Position(c: 2, l: 0)), Position(c: 2, l: 1));
    expect(Motions.lineDown(f, Position(c: 0, l: 1)), Position(c: 0, l: 1));
    expect(Motions.lineDown(f, Position(c: 2, l: 1)), Position(c: 2, l: 1));
  });

  test('motion.lineDown with emojis', () {
    final f = FileBuffer(text: 'abcdef\n😎😍👽\nghijkl\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.lineDown(f, Position(c: 2, l: 0)), Position(c: 1, l: 1));
    expect(Motions.lineDown(f, Position(c: 1, l: 1)), Position(c: 2, l: 2));
  });

  test('motionFileStart', () {
    final f = FileBuffer(text: 'abc\ndef\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.fileStart(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(Motions.fileStart(f, Position(c: 2, l: 0)), Position(c: 0, l: 0));
    expect(Motions.fileStart(f, Position(c: 0, l: 1)), Position(c: 0, l: 0));
    expect(Motions.fileStart(f, Position(c: 2, l: 1)), Position(c: 0, l: 0));
  });

  test('motionFileEnd', () {
    final f = FileBuffer(text: 'abc\ndef\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.fileEnd(f, Position(c: 0, l: 0)), Position(c: 0, l: 1));
    expect(Motions.fileEnd(f, Position(c: 2, l: 0)), Position(c: 0, l: 1));
    expect(Motions.fileEnd(f, Position(c: 0, l: 1)), Position(c: 0, l: 1));
    expect(Motions.fileEnd(f, Position(c: 2, l: 1)), Position(c: 0, l: 1));
  });

  test('motionWordNext', () {
    final f = FileBuffer(text: 'abc def ghi\njkl mno pqr\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.wordNext(f, Position(c: 0, l: 0)), Position(c: 4, l: 0));
    expect(Motions.wordNext(f, Position(c: 3, l: 0)), Position(c: 4, l: 0));
    expect(Motions.wordNext(f, Position(c: 4, l: 0)), Position(c: 8, l: 0));
    expect(Motions.wordNext(f, Position(c: 8, l: 0)), Position(c: 0, l: 1));
    expect(Motions.wordNext(f, Position(c: 2, l: 1)), Position(c: 4, l: 1));
    expect(Motions.wordNext(f, Position(c: 2, l: 1)), Position(c: 4, l: 1));
  });

  test('motionWordCapNext', () {
    final f = FileBuffer(text: 'abc,def ghi\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.wordCapNext(f, Position(c: 0, l: 0)), Position(c: 8, l: 0));
  });

  test('motionWordEnd', () {
    final f = FileBuffer(text: 'abc def ghi\njkl mno pqr\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.wordEnd(f, Position(c: 0, l: 0)), Position(c: 2, l: 0));
    expect(Motions.wordEnd(f, Position(c: 3, l: 0)), Position(c: 6, l: 0));
    expect(Motions.wordEnd(f, Position(c: 4, l: 0)), Position(c: 6, l: 0));
    expect(Motions.wordEnd(f, Position(c: 8, l: 0)), Position(c: 10, l: 0));
    expect(Motions.wordEnd(f, Position(c: 10, l: 0)), Position(c: 2, l: 1));
    expect(Motions.wordEnd(f, Position(c: 2, l: 1)), Position(c: 6, l: 1));
  });

  test('motionWordPrev', () {
    final f = FileBuffer(text: 'abc d❤️‍🔥f ghi\njkl mno pqr\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.wordPrev(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(Motions.wordPrev(f, Position(c: 3, l: 0)), Position(c: 0, l: 0));
    expect(Motions.wordPrev(f, Position(c: 4, l: 0)), Position(c: 0, l: 0));
    expect(Motions.wordPrev(f, Position(c: 5, l: 0)), Position(c: 4, l: 0));
    expect(Motions.wordPrev(f, Position(c: 4, l: 1)), Position(c: 0, l: 1));
    expect(Motions.wordPrev(f, Position(c: 0, l: 1)), Position(c: 8, l: 0));
  });

  test('motionWordCapPrev', () {
    final f = FileBuffer(text: 'abc def, ghi\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.wordCapPrev(f, Position(c: 9, l: 0)), Position(c: 4, l: 0));
  });

  test('motionWordEndPrev', () {
    final f = FileBuffer(text: 'abc d❤️‍🔥f ghi\njkl mno pqr\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(Motions.wordEndPrev(f, Position(c: 4, l: 0)), Position(c: 2, l: 0));
    expect(Motions.wordEndPrev(f, Position(c: 8, l: 0)), Position(c: 6, l: 0));
    expect(Motions.wordEndPrev(f, Position(c: 10, l: 0)), Position(c: 6, l: 0));
    expect(Motions.wordEndPrev(f, Position(c: 1, l: 1)), Position(c: 10, l: 0));
  });

  test('motionFindWordOnCursorNext', () {
    final f = FileBuffer(text: 'det er fint, fint er det saus\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(
        Motions.sameWordNext(f, Position(l: 0, c: 0)), Position(l: 0, c: 21));
    expect(
        Motions.sameWordNext(f, Position(l: 0, c: 10)), Position(l: 0, c: 13));
    expect(
        Motions.sameWordNext(f, Position(l: 0, c: 27)), Position(l: 0, c: 25));
  });

  test('motionFindWordOnCursorPrev', () {
    final f = FileBuffer(text: 'det er fint, fint er det saus\n');
    f.createLines(WrapMode.none, 80, 24);
    expect(
        Motions.sameWordPrev(f, Position(l: 0, c: 15)), Position(l: 0, c: 7));
    expect(
        Motions.sameWordPrev(f, Position(l: 0, c: 27)), Position(l: 0, c: 25));
  });

  test('motionFirstNoneBlank', () {
    final f = FileBuffer(text: '  abc\n');
    f.createLines(WrapMode.none, 80, 24);
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
    final f = FileBuffer(text: 'abc def\nghi jkl\n');
    f.createLines(WrapMode.none, 80, 24);
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
