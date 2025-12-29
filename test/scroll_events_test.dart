import 'package:test/test.dart';
import 'package:vid/regex.dart';

void main() {
  test('matches arrow key sequences x1b[[A-D]', () {
    expect(Regex.scrollEvents.hasMatch('\x1b[A'), true); // up
    expect(Regex.scrollEvents.hasMatch('\x1b[B'), true); // down
    expect(Regex.scrollEvents.hasMatch('\x1b[C'), true); // right
    expect(Regex.scrollEvents.hasMatch('\x1b[D'), true); // left
  });

  test('matches arrow key sequences x1bO[A-D]', () {
    expect(Regex.scrollEvents.hasMatch('\x1bOA'), true); // up
    expect(Regex.scrollEvents.hasMatch('\x1bOB'), true); // down
    expect(Regex.scrollEvents.hasMatch('\x1bOC'), true); // right
    expect(Regex.scrollEvents.hasMatch('\x1bOD'), true); // left
  });

  test('does not match invalid sequences', () {
    expect(Regex.scrollEvents.hasMatch('test'), false);
    expect(Regex.scrollEvents.hasMatch('\x1b[X'), false);
    expect(Regex.scrollEvents.hasMatch('[C'), false);
    expect(Regex.scrollEvents.hasMatch('OD'), false);
  });
}
