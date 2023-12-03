import 'package:test/test.dart';
import 'package:vid/actions_motion.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_lines.dart';
import 'package:vid/caret.dart';

void main() {
  test('motionCharNext', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(Motions.charNext(f, Position(c: 0, l: 0)), Position(c: 1, l: 0));
    expect(Motions.charNext(f, Position(c: 2, l: 0)), Position(c: 3, l: 0));
    expect(Motions.charNext(f, Position(c: 3, l: 0)), Position(c: 0, l: 1));
    expect(Motions.charNext(f, Position(c: 0, l: 1)), Position(c: 1, l: 1));
    expect(Motions.charNext(f, Position(c: 2, l: 1)), Position(c: 3, l: 1));
  });

  test('motionCharPrev', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(Motions.charPrev(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(Motions.charPrev(f, Position(c: 2, l: 0)), Position(c: 1, l: 0));
    expect(Motions.charPrev(f, Position(c: 0, l: 1)), Position(c: 3, l: 0));
    expect(Motions.charPrev(f, Position(c: 2, l: 1)), Position(c: 1, l: 1));
  });

  test('motionCharUp', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(Motions.lineUp(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(Motions.lineUp(f, Position(c: 2, l: 0)), Position(c: 2, l: 0));
    expect(Motions.lineUp(f, Position(c: 0, l: 1)), Position(c: 0, l: 0));
    expect(Motions.lineUp(f, Position(c: 2, l: 1)), Position(c: 2, l: 0));
  });

  test('motionCharDown', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(Motions.lineDown(f, Position(c: 0, l: 0)), Position(c: 0, l: 1));
    expect(Motions.lineDown(f, Position(c: 2, l: 0)), Position(c: 2, l: 1));
    expect(Motions.lineDown(f, Position(c: 0, l: 1)), Position(c: 0, l: 1));
    expect(Motions.lineDown(f, Position(c: 2, l: 1)), Position(c: 2, l: 1));
  });

  test('motionFileStart', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(Motions.fileStart(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(Motions.fileStart(f, Position(c: 2, l: 0)), Position(c: 0, l: 0));
    expect(Motions.fileStart(f, Position(c: 0, l: 1)), Position(c: 0, l: 0));
    expect(Motions.fileStart(f, Position(c: 2, l: 1)), Position(c: 0, l: 0));
  });

  test('motionFileEnd', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(Motions.fileEnd(f, Position(c: 0, l: 0)), Position(c: 0, l: 1));
    expect(Motions.fileEnd(f, Position(c: 2, l: 0)), Position(c: 0, l: 1));
    expect(Motions.fileEnd(f, Position(c: 0, l: 1)), Position(c: 0, l: 1));
    expect(Motions.fileEnd(f, Position(c: 2, l: 1)), Position(c: 0, l: 1));
  });

  test('motionWordNext', () {
    final f = FileBuffer();
    f.text = 'abc def ghi\njkl mno pqr\n';
    f.createLines();
    expect(Motions.wordNext(f, Position(c: 0, l: 0)), Position(c: 4, l: 0));
    expect(Motions.wordNext(f, Position(c: 3, l: 0)), Position(c: 4, l: 0));
    expect(Motions.wordNext(f, Position(c: 4, l: 0)), Position(c: 8, l: 0));
    expect(Motions.wordNext(f, Position(c: 8, l: 0)), Position(c: 0, l: 1));
    expect(Motions.wordNext(f, Position(c: 2, l: 1)), Position(c: 4, l: 1));
    expect(Motions.wordNext(f, Position(c: 2, l: 1)), Position(c: 4, l: 1));
  });

  test('motionWordEnd', () {
    final f = FileBuffer();
    f.text = 'abc def ghi\njkl mno pqr\n';
    f.createLines();
    expect(Motions.wordEnd(f, Position(c: 0, l: 0)), Position(c: 2, l: 0));
    expect(Motions.wordEnd(f, Position(c: 3, l: 0)), Position(c: 6, l: 0));
    expect(Motions.wordEnd(f, Position(c: 4, l: 0)), Position(c: 6, l: 0));
    expect(Motions.wordEnd(f, Position(c: 8, l: 0)), Position(c: 10, l: 0));
    expect(Motions.wordEnd(f, Position(c: 10, l: 0)), Position(c: 2, l: 1));
    expect(Motions.wordEnd(f, Position(c: 2, l: 1)), Position(c: 6, l: 1));
  });

  test('motionWordPrev', () {
    final f = FileBuffer();
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    f.createLines();
    expect(Motions.wordPrev(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(Motions.wordPrev(f, Position(c: 3, l: 0)), Position(c: 0, l: 0));
    expect(Motions.wordPrev(f, Position(c: 4, l: 0)), Position(c: 0, l: 0));
    expect(Motions.wordPrev(f, Position(c: 5, l: 0)), Position(c: 4, l: 0));
    expect(Motions.wordPrev(f, Position(c: 4, l: 1)), Position(c: 0, l: 1));
    expect(Motions.wordPrev(f, Position(c: 0, l: 1)), Position(c: 8, l: 0));
  });

  test('motionWordEndPrev', () {
    final f = FileBuffer();
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    f.createLines();
    expect(Motions.wordEndPrev(f, Position(c: 4, l: 0)), Position(c: 2, l: 0));
    expect(Motions.wordEndPrev(f, Position(c: 8, l: 0)), Position(c: 6, l: 0));
    expect(Motions.wordEndPrev(f, Position(c: 10, l: 0)), Position(c: 6, l: 0));
    expect(Motions.wordEndPrev(f, Position(c: 1, l: 1)), Position(c: 10, l: 0));
  });

  test('motionFindWordOnCursorNext', () {
    final f = FileBuffer();
    f.text = 'det er fint, fint er det saus\n';
    f.createLines();
    expect(
        Motions.sameWordNext(f, Position(l: 0, c: 0)), Position(l: 0, c: 21));
    expect(
        Motions.sameWordNext(f, Position(l: 0, c: 10)), Position(l: 0, c: 13));
    expect(
        Motions.sameWordNext(f, Position(l: 0, c: 27)), Position(l: 0, c: 25));
  });

  test('motionFindWordOnCursorPrev', () {
    final f = FileBuffer();
    f.text = 'det er fint, fint er det saus\n';
    f.createLines();
    expect(
        Motions.sameWordPrev(f, Position(l: 0, c: 15)), Position(l: 0, c: 7));
    expect(
        Motions.sameWordPrev(f, Position(l: 0, c: 27)), Position(l: 0, c: 25));
  });

  test('motionFirstNoneBlank', () {
    final f = FileBuffer();
    f.text = '  abc\n';
    f.createLines();
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
    final f = FileBuffer();
    f.text = 'abc def\nghi jkl\n';
    f.createLines();
    expect(Motions.lineEndExcl(f, Position(l: 0, c: 0)), Position(l: 0, c: 7));
    expect(Motions.lineEndExcl(f, Position(l: 0, c: 3)), Position(l: 0, c: 7));
    expect(Motions.lineEndExcl(f, Position(l: 1, c: 0)), Position(l: 1, c: 7));
    expect(Motions.lineEndExcl(f, Position(l: 1, c: 3)), Position(l: 1, c: 7));
  });
}
