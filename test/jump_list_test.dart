import 'package:test/test.dart';
import 'package:vid/jump_list.dart';

void main() {
  test('push ignores null path', () {
    final j = JumpList();
    j.push(null, 0);
    expect(j.back('/a', 0), isNull);
  });

  test('push ignores duplicate of last location', () {
    final j = JumpList();
    j.push('/a', 10);
    j.push('/a', 10);
    // Only one entry: back from a different position saves current and
    // returns the single pushed location.
    expect(j.back('/b', 20), JumpLocation('/a', 10));
    expect(j.back('/a', 10), isNull);
  });

  test('back returns null with empty list', () {
    final j = JumpList();
    expect(j.back('/a', 0), isNull);
  });

  test('back saves current position when at end', () {
    final j = JumpList();
    j.push('/a', 10);
    // Currently at /b: back should land on /a and remember /b for forward.
    expect(j.back('/b', 20), JumpLocation('/a', 10));
    expect(j.forward(), JumpLocation('/b', 20));
  });

  test('back walks history in reverse order', () {
    final j = JumpList();
    j.push('/a', 1);
    j.push('/b', 2);
    j.push('/c', 3);
    expect(j.back('/d', 4), JumpLocation('/c', 3));
    expect(j.back('/d', 4), JumpLocation('/b', 2));
    expect(j.back('/d', 4), JumpLocation('/a', 1));
    expect(j.back('/d', 4), isNull); // bottom of history
  });

  test('forward returns null at end of list', () {
    final j = JumpList();
    j.push('/a', 1);
    expect(j.forward(), isNull);
  });

  test('push clears forward history', () {
    final j = JumpList();
    j.push('/a', 1);
    j.push('/b', 2);
    expect(j.back('/c', 3), JumpLocation('/b', 2));
    // New push from mid-history drops everything after it.
    j.push('/d', 4);
    expect(j.forward(), isNull);
    expect(j.back('/e', 5), JumpLocation('/d', 4));
    expect(j.back('/e', 5), JumpLocation('/b', 2));
  });

  test('respects maxSize by dropping oldest entries', () {
    final j = JumpList(maxSize: 2);
    j.push('/a', 1);
    j.push('/b', 2);
    j.push('/c', 3);
    expect(j.back('/d', 4), JumpLocation('/c', 3));
    expect(j.back('/d', 4), JumpLocation('/b', 2));
    expect(j.back('/d', 4), isNull); // /a was evicted
  });
}
