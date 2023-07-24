import 'package:test/test.dart';
import 'package:vid/actions_motion.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';

void main() {
  test('motionCharNext', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(motionCharNext(f, Position(c: 0, l: 0)), Position(c: 1, l: 0));
    expect(motionCharNext(f, Position(c: 2, l: 0)), Position(c: 3, l: 0));
    expect(motionCharNext(f, Position(c: 0, l: 1)), Position(c: 1, l: 1));
    expect(motionCharNext(f, Position(c: 2, l: 1)), Position(c: 3, l: 1));
  });

  test('motionCharPrev', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(motionCharPrev(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(motionCharPrev(f, Position(c: 2, l: 0)), Position(c: 1, l: 0));
    expect(motionCharPrev(f, Position(c: 0, l: 1)), Position(c: 0, l: 1));
    expect(motionCharPrev(f, Position(c: 2, l: 1)), Position(c: 1, l: 1));
  });

  test('motionCharUp', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(motionCharUp(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(motionCharUp(f, Position(c: 2, l: 0)), Position(c: 2, l: 0));
    expect(motionCharUp(f, Position(c: 0, l: 1)), Position(c: 0, l: 0));
    expect(motionCharUp(f, Position(c: 2, l: 1)), Position(c: 2, l: 0));
  });

  test('motionCharDown', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(motionCharDown(f, Position(c: 0, l: 0)), Position(c: 0, l: 1));
    expect(motionCharDown(f, Position(c: 2, l: 0)), Position(c: 2, l: 1));
    expect(motionCharDown(f, Position(c: 0, l: 1)), Position(c: 0, l: 1));
    expect(motionCharDown(f, Position(c: 2, l: 1)), Position(c: 2, l: 1));
  });

  test('motionFileStart', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(motionFileStart(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(motionFileStart(f, Position(c: 2, l: 0)), Position(c: 0, l: 0));
    expect(motionFileStart(f, Position(c: 0, l: 1)), Position(c: 0, l: 0));
    expect(motionFileStart(f, Position(c: 2, l: 1)), Position(c: 0, l: 0));
  });

  test('motionFileEnd', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    expect(motionFileEnd(f, Position(c: 0, l: 0)), Position(c: 4, l: 1));
    expect(motionFileEnd(f, Position(c: 2, l: 0)), Position(c: 4, l: 1));
    expect(motionFileEnd(f, Position(c: 0, l: 1)), Position(c: 4, l: 1));
    expect(motionFileEnd(f, Position(c: 2, l: 1)), Position(c: 4, l: 1));
  });

  test('motionFindNextChar', () {
    final f = FileBuffer();
    f.text = 'abca\ndef\n';
    f.createLines();
    final cursor = Position(c: 0, l: 0);
    expect(motionFindNextChar(f, cursor, 'a'), Position(c: 3, l: 0));
    expect(motionFindNextChar(f, cursor, 'b'), Position(c: 1, l: 0));
    expect(motionFindNextChar(f, cursor, 'c'), Position(c: 2, l: 0));
  });

  test('motionFindPrevChar', () {
    final f = FileBuffer();
    f.text = 'abc\ndef\n';
    f.createLines();
    final cursor = Position(c: 2, l: 0);
    expect(motionFindPrevChar(f, cursor, 'a'), Position(c: 0, l: 0));
    expect(motionFindPrevChar(f, cursor, 'b'), Position(c: 1, l: 0));
    expect(motionFindPrevChar(f, cursor, 'c'), Position(c: 2, l: 0));
  });

  test('motionWordNext', () {
    final f = FileBuffer();
    f.text = 'abc def ghi\njkl mno pqr\n';
    f.createLines();
    expect(motionWordNext(f, Position(c: 0, l: 0)), Position(c: 4, l: 0));
    expect(motionWordNext(f, Position(c: 3, l: 0)), Position(c: 4, l: 0));
    expect(motionWordNext(f, Position(c: 4, l: 0)), Position(c: 8, l: 0));
    expect(motionWordNext(f, Position(c: 8, l: 0)), Position(c: 0, l: 1));
    expect(motionWordNext(f, Position(c: 2, l: 1)), Position(c: 4, l: 1));
    expect(motionWordNext(f, Position(c: 2, l: 1)), Position(c: 4, l: 1));
  });

  test('motionWordEnd', () {
    final f = FileBuffer();
    f.text = 'abc def ghi\njkl mno pqr\n';
    f.createLines();
    expect(motionWordEnd(f, Position(c: 0, l: 0)), Position(c: 3, l: 0));
    expect(motionWordEnd(f, Position(c: 3, l: 0)), Position(c: 7, l: 0));
    expect(motionWordEnd(f, Position(c: 4, l: 0)), Position(c: 7, l: 0));
    expect(motionWordEnd(f, Position(c: 8, l: 0)), Position(c: 11, l: 0));
    expect(motionWordEnd(f, Position(c: 10, l: 0)), Position(c: 3, l: 1));
    expect(motionWordEnd(f, Position(c: 2, l: 1)), Position(c: 7, l: 1));
  });

  test('motionWordPrev', () {
    final f = FileBuffer();
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    f.createLines();
    expect(motionWordPrev(f, Position(c: 0, l: 0)), Position(c: 0, l: 0));
    expect(motionWordPrev(f, Position(c: 3, l: 0)), Position(c: 0, l: 0));
    expect(motionWordPrev(f, Position(c: 4, l: 0)), Position(c: 0, l: 0));
    expect(motionWordPrev(f, Position(c: 5, l: 0)), Position(c: 4, l: 0));
    expect(motionWordPrev(f, Position(c: 4, l: 1)), Position(c: 0, l: 1));
    expect(motionWordPrev(f, Position(c: 0, l: 1)), Position(c: 8, l: 0));
  });

  test('motionWordEndPrev', () {
    final f = FileBuffer();
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    f.createLines();
    expect(motionWordEndPrev(f, Position(c: 4, l: 0)), Position(c: 2, l: 0));
    expect(motionWordEndPrev(f, Position(c: 8, l: 0)), Position(c: 6, l: 0));
    expect(motionWordEndPrev(f, Position(c: 10, l: 0)), Position(c: 6, l: 0));
    expect(motionWordEndPrev(f, Position(c: 1, l: 1)), Position(c: 10, l: 0));
  });

  test('motionFindWordOnCursorNext', () {
    final f = FileBuffer();
    f.text = 'det er fint, fint er det saus\n';
    f.createLines();
    expect(motionSameWordNext(f, Position(l: 0, c: 0)), Position(l: 0, c: 21));
    expect(motionSameWordNext(f, Position(l: 0, c: 10)), Position(l: 0, c: 13));
    expect(motionSameWordNext(f, Position(l: 0, c: 27)), Position(l: 0, c: 25));
  });

  test('motionFindWordOnCursorPrev', () {
    final f = FileBuffer();
    f.text = 'det er fint, fint er det saus\n';
    f.createLines();
    expect(motionSameWordPrev(f, Position(l: 0, c: 15)), Position(l: 0, c: 7));
    expect(motionSameWordPrev(f, Position(l: 0, c: 27)), Position(l: 0, c: 25));
  });

  test('motionFirstNoneBlank', () {
    final f = FileBuffer();
    f.text = '  abc\n';
    f.createLines();
    expect(motionFirstNonBlank(f, Position(l: 0, c: 0)), Position(l: 0, c: 2));
    expect(motionFirstNonBlank(f, Position(l: 0, c: 1)), Position(l: 0, c: 2));
    expect(motionFirstNonBlank(f, Position(l: 0, c: 2)), Position(l: 0, c: 2));
    expect(motionFirstNonBlank(f, Position(l: 0, c: 3)), Position(l: 0, c: 2));
    expect(motionFirstNonBlank(f, Position(l: 0, c: 5)), Position(l: 0, c: 2));
  });

  test('motionLineEnd', () {
    final f = FileBuffer();
    f.text = 'abc def\nghi jkl\n';
    f.createLines();
    expect(motionLineEnd(f, Position(l: 0, c: 0)), Position(l: 0, c: 7));
    expect(motionLineEnd(f, Position(l: 0, c: 3)), Position(l: 0, c: 7));
    expect(motionLineEnd(f, Position(l: 1, c: 0)), Position(l: 1, c: 7));
    expect(motionLineEnd(f, Position(l: 1, c: 3)), Position(l: 1, c: 7));
  });
}
