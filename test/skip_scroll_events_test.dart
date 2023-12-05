import 'package:test/test.dart';
import 'package:vid/editor.dart';

void main() {
  test('skip scroll events x1b[[A-B]', () {
    var e = Editor();
    expect(e.hasScrollEvents('\x1b[A'), true);
    expect(e.hasScrollEvents('\x1b[B'), true);
    expect(e.hasScrollEvents('\x1b[C'), true);
    expect(e.hasScrollEvents('\x1b[D'), true);
  });

  test('skip scroll events x1bO[A-B]', () {
    var e = Editor();
    expect(e.hasScrollEvents('\x1bOA'), true);
    expect(e.hasScrollEvents('\x1bOB'), true);
    expect(e.hasScrollEvents('\x1bOC'), true);
    expect(e.hasScrollEvents('\x1bOD'), true);
  });

  test('skip scroll events x1bO[A-B]', () {
    var e = Editor();
    expect(e.hasScrollEvents('test'), false);
    expect(e.hasScrollEvents('\x1b[X'), false);
    expect(e.hasScrollEvents('[C'), false);
    expect(e.hasScrollEvents('OD'), false);
  });
}
