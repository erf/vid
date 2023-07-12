import 'package:test/test.dart';
import 'package:vid/actions_motion.dart';
import 'package:vid/file_buffer.dart';
import 'package:vid/position.dart';
import 'package:vid/string_ext.dart';

void main() {
  test('motionCharNext', () {
    final f = FileBuffer();
    f.lines = [
      'abc'.ch,
      'def'.ch,
    ];
    expect(motionCharNext(f, Position(x: 0, y: 0)), Position(x: 1, y: 0));
    expect(motionCharNext(f, Position(x: 2, y: 0)), Position(x: 2, y: 0));
    expect(motionCharNext(f, Position(x: 0, y: 1)), Position(x: 1, y: 1));
    expect(motionCharNext(f, Position(x: 2, y: 1)), Position(x: 2, y: 1));
  });

  test('motionCharPrev', () {
    final f = FileBuffer();
    f.lines = [
      'abc'.ch,
      'def'.ch,
    ];
    expect(motionCharPrev(f, Position(x: 0, y: 0)), Position(x: 0, y: 0));
    expect(motionCharPrev(f, Position(x: 2, y: 0)), Position(x: 1, y: 0));
    expect(motionCharPrev(f, Position(x: 0, y: 1)), Position(x: 0, y: 1));
    expect(motionCharPrev(f, Position(x: 2, y: 1)), Position(x: 1, y: 1));
  });

  test('motionCharUp', () {
    final f = FileBuffer();
    f.lines = [
      'abc'.ch,
      'def'.ch,
    ];
    expect(motionCharUp(f, Position(x: 0, y: 0)), Position(x: 0, y: 0));
    expect(motionCharUp(f, Position(x: 2, y: 0)), Position(x: 2, y: 0));
    expect(motionCharUp(f, Position(x: 0, y: 1)), Position(x: 0, y: 0));
    expect(motionCharUp(f, Position(x: 2, y: 1)), Position(x: 2, y: 0));
  });

  test('motionCharDown', () {
    final f = FileBuffer();
    f.lines = [
      'abc'.ch,
      'def'.ch,
    ];
    expect(motionCharDown(f, Position(x: 0, y: 0)), Position(x: 0, y: 1));
    expect(motionCharDown(f, Position(x: 2, y: 0)), Position(x: 2, y: 1));
    expect(motionCharDown(f, Position(x: 0, y: 1)), Position(x: 0, y: 1));
    expect(motionCharDown(f, Position(x: 2, y: 1)), Position(x: 2, y: 1));
  });

  test('motionFileStart', () {
    final f = FileBuffer();
    f.lines = [
      'abc'.ch,
      'def'.ch,
    ];
    expect(motionFileStart(f, Position(x: 0, y: 0)), Position(x: 0, y: 0));
    expect(motionFileStart(f, Position(x: 2, y: 0)), Position(x: 0, y: 0));
    expect(motionFileStart(f, Position(x: 0, y: 1)), Position(x: 0, y: 0));
    expect(motionFileStart(f, Position(x: 2, y: 1)), Position(x: 0, y: 0));
  });

  test('motionFileEnd', () {
    final f = FileBuffer();
    f.lines = [
      'abc'.ch,
      'def'.ch,
    ];
    expect(motionFileEnd(f, Position(x: 0, y: 0)), Position(x: 3, y: 1));
    expect(motionFileEnd(f, Position(x: 2, y: 0)), Position(x: 3, y: 1));
    expect(motionFileEnd(f, Position(x: 0, y: 1)), Position(x: 3, y: 1));
    expect(motionFileEnd(f, Position(x: 2, y: 1)), Position(x: 3, y: 1));
  });

  test('motionFindNextChar', () {
    final f = FileBuffer();
    f.lines = [
      'abca'.ch,
      'def'.ch,
    ];
    final cursor = Position(x: 0, y: 0);
    expect(motionFindNextChar(f, cursor, 'a'), Position(x: 3, y: 0));
    expect(motionFindNextChar(f, cursor, 'b'), Position(x: 1, y: 0));
    expect(motionFindNextChar(f, cursor, 'c'), Position(x: 2, y: 0));
  });

  test('motionFindPrevChar', () {
    final f = FileBuffer();
    f.lines = [
      'abc'.ch,
      'def'.ch,
    ];
    final cursor = Position(x: 2, y: 0);
    expect(motionFindPrevChar(f, cursor, 'a'), Position(x: 0, y: 0));
    expect(motionFindPrevChar(f, cursor, 'b'), Position(x: 1, y: 0));
    expect(motionFindPrevChar(f, cursor, 'c'), Position(x: 2, y: 0));
  });

  test('motionWordNext', () {
    final f = FileBuffer();
    f.lines = [
      'a🥹c d❤️‍🔥f ghi'.ch,
      'jkl 😺no p🦀r'.ch,
    ];
    expect(motionWordNext(f, Position(x: 0, y: 0)), Position(x: 4, y: 0));
    expect(motionWordNext(f, Position(x: 3, y: 0)), Position(x: 4, y: 0));
    expect(motionWordNext(f, Position(x: 4, y: 0)), Position(x: 8, y: 0));

    expect(motionWordNext(f, Position(x: 8, y: 0)), Position(x: 0, y: 1));
    expect(motionWordNext(f, Position(x: 2, y: 1)), Position(x: 4, y: 1));
    expect(motionWordNext(f, Position(x: 2, y: 1)), Position(x: 4, y: 1));
  });
}
