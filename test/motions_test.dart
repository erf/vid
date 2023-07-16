import 'package:test/test.dart';
import 'package:vid/actions_motion.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/file_buffer_ext.dart';
import 'package:vid/position.dart';

void main() {
  test('motionCharNext', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();

    expect(motionCharNext(f, Position(x: 0, y: 0)), Position(x: 1, y: 0));
    expect(motionCharNext(f, Position(x: 2, y: 0)), Position(x: 2, y: 0));
    expect(motionCharNext(f, Position(x: 0, y: 1)), Position(x: 1, y: 1));
    expect(motionCharNext(f, Position(x: 2, y: 1)), Position(x: 2, y: 1));
  });

  test('motionCharPrev', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();

    expect(motionCharPrev(f, Position(x: 0, y: 0)), Position(x: 0, y: 0));
    expect(motionCharPrev(f, Position(x: 2, y: 0)), Position(x: 1, y: 0));
    expect(motionCharPrev(f, Position(x: 0, y: 1)), Position(x: 0, y: 1));
    expect(motionCharPrev(f, Position(x: 2, y: 1)), Position(x: 1, y: 1));
  });

  test('motionCharUp', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();

    expect(motionCharUp(f, Position(x: 0, y: 0)), Position(x: 0, y: 0));
    expect(motionCharUp(f, Position(x: 2, y: 0)), Position(x: 2, y: 0));
    expect(motionCharUp(f, Position(x: 0, y: 1)), Position(x: 0, y: 0));
    expect(motionCharUp(f, Position(x: 2, y: 1)), Position(x: 2, y: 0));
  });

  test('motionCharDown', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();

    expect(motionCharDown(f, Position(x: 0, y: 0)), Position(x: 0, y: 1));
    expect(motionCharDown(f, Position(x: 2, y: 0)), Position(x: 2, y: 1));
    expect(motionCharDown(f, Position(x: 0, y: 1)), Position(x: 0, y: 1));
    expect(motionCharDown(f, Position(x: 2, y: 1)), Position(x: 2, y: 1));
  });

  test('motionFileStart', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();

    expect(motionFileStart(f, Position(x: 0, y: 0)), Position(x: 0, y: 0));
    expect(motionFileStart(f, Position(x: 2, y: 0)), Position(x: 0, y: 0));
    expect(motionFileStart(f, Position(x: 0, y: 1)), Position(x: 0, y: 0));
    expect(motionFileStart(f, Position(x: 2, y: 1)), Position(x: 0, y: 0));
  });

  test('motionFileEnd', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();

    expect(motionFileEnd(f, Position(x: 0, y: 0)), Position(x: 3, y: 1));
    expect(motionFileEnd(f, Position(x: 2, y: 0)), Position(x: 3, y: 1));
    expect(motionFileEnd(f, Position(x: 0, y: 1)), Position(x: 3, y: 1));
    expect(motionFileEnd(f, Position(x: 2, y: 1)), Position(x: 3, y: 1));
  });

  test('motionFindNextChar', () {
    final f = FileBuffer();
    f.text = 'abca\ndef';
    f.createLines();
    final cursor = Position(x: 0, y: 0);

    expect(motionFindNextChar(f, cursor, 'a'), Position(x: 3, y: 0));
    expect(motionFindNextChar(f, cursor, 'b'), Position(x: 1, y: 0));
    expect(motionFindNextChar(f, cursor, 'c'), Position(x: 2, y: 0));
  });

  test('motionFindPrevChar', () {
    final f = FileBuffer();
    f.text = 'abc\ndef';
    f.createLines();
    final cursor = Position(x: 2, y: 0);
    expect(motionFindPrevChar(f, cursor, 'a'), Position(x: 0, y: 0));
    expect(motionFindPrevChar(f, cursor, 'b'), Position(x: 1, y: 0));
    expect(motionFindPrevChar(f, cursor, 'c'), Position(x: 2, y: 0));
  });

  test('motionWordNext', () {
    final f = FileBuffer();
    f.text = 'a🥹c d❤️‍🔥f ghi\njkl 😺no p🦀r';
    f.createLines();
    expect(motionWordNext(f, Position(x: 0, y: 0)), Position(x: 4, y: 0));
    expect(motionWordNext(f, Position(x: 3, y: 0)), Position(x: 4, y: 0));
    expect(motionWordNext(f, Position(x: 4, y: 0)), Position(x: 8, y: 0));

    expect(motionWordNext(f, Position(x: 8, y: 0)), Position(x: 0, y: 1));
    expect(motionWordNext(f, Position(x: 2, y: 1)), Position(x: 4, y: 1));
    expect(motionWordNext(f, Position(x: 2, y: 1)), Position(x: 4, y: 1));
  });

  test('motionWordEnd', () {
    final f = FileBuffer();
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr';
    f.createLines();
    expect(motionWordEnd(f, Position(x: 0, y: 0)), Position(x: 2, y: 0));
    expect(motionWordEnd(f, Position(x: 3, y: 0)), Position(x: 6, y: 0));
    expect(motionWordEnd(f, Position(x: 4, y: 0)), Position(x: 6, y: 0));

    expect(motionWordEnd(f, Position(x: 8, y: 0)), Position(x: 10, y: 0));
    expect(motionWordEnd(f, Position(x: 10, y: 0)), Position(x: 2, y: 1));
    expect(motionWordEnd(f, Position(x: 2, y: 1)), Position(x: 6, y: 1));
  });

  test('motionWordPrev', () {
    final f = FileBuffer();
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr';
    f.createLines();
    expect(motionWordPrev(f, Position(x: 0, y: 0)), Position(x: 0, y: 0));
    expect(motionWordPrev(f, Position(x: 3, y: 0)), Position(x: 0, y: 0));
    expect(motionWordPrev(f, Position(x: 4, y: 0)), Position(x: 0, y: 0));

    expect(motionWordPrev(f, Position(x: 5, y: 0)), Position(x: 4, y: 0));
    expect(motionWordPrev(f, Position(x: 4, y: 1)), Position(x: 0, y: 1));
    expect(motionWordPrev(f, Position(x: 0, y: 1)), Position(x: 8, y: 0));
  });
}
