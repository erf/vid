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
}
