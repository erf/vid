import 'package:test/test.dart';
import 'package:vid/regex.dart';

void main() {
  test('skip scroll events x1b[[A-B]', () {
    expect(Regex.scrollEvents.hasMatch('\x1b[A'), true);
    expect(Regex.scrollEvents.hasMatch('\x1b[B'), true);
    expect(Regex.scrollEvents.hasMatch('\x1b[C'), true);
    expect(Regex.scrollEvents.hasMatch('\x1b[D'), true);
  });

  test('skip scroll events x1bO[A-B]', () {
    expect(Regex.scrollEvents.hasMatch('\x1bOA'), true);
    expect(Regex.scrollEvents.hasMatch('\x1bOB'), true);
    expect(Regex.scrollEvents.hasMatch('\x1bOC'), true);
    expect(Regex.scrollEvents.hasMatch('\x1bOD'), true);
  });

  test('skip scroll events x1bO[A-B]', () {
    expect(Regex.scrollEvents.hasMatch('test'), false);
    expect(Regex.scrollEvents.hasMatch('\x1b[X'), false);
    expect(Regex.scrollEvents.hasMatch('[C'), false);
    expect(Regex.scrollEvents.hasMatch('OD'), false);
  });
}
