import 'package:test/test.dart';
import 'package:vid/bindings.dart';

void main() {
  test('MatchKeys none, partial, and match for key bindings', () {
    final bindings = ModeBindings({'a': true, 'bc': true, 'abc': true});
    expect(bindings.match('c'), (KeyMatch.none, null));
    expect(bindings.match('b'), (KeyMatch.partial, null));
    expect(bindings.match('ab'), (KeyMatch.partial, null));
    expect(bindings.match('a'), (KeyMatch.match, true));
  });

  test('MatchKeys fallback for unmatched keys', () {
    final bindings = ModeBindings({'a': 'matched'}, fallback: 'fallback');
    expect(bindings.match('a'), (KeyMatch.match, 'matched'));
    expect(bindings.match('x'), (KeyMatch.match, 'fallback'));
  });

  test('MatchKeys no fallback returns none', () {
    final bindings = ModeBindings<String>({'a': 'matched'});
    expect(bindings.match('a'), (KeyMatch.match, 'matched'));
    expect(bindings.match('x'), (KeyMatch.none, null));
  });
}
