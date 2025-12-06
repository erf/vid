import 'package:test/test.dart';
import 'package:vid/map_match.dart';

void main() {
  test('MatchKeys none, partial, and match for key bindings', () {
    final bindings = ModeBindings({'a': true, 'bc': true, 'abc': true});
    expect(matchKeys(bindings, 'c'), (KeyMatch.none, null));
    expect(matchKeys(bindings, 'b'), (KeyMatch.partial, null));
    expect(matchKeys(bindings, 'ab'), (KeyMatch.partial, null));
    expect(matchKeys(bindings, 'a'), (KeyMatch.match, true));
  });

  test('MatchKeys fallback for unmatched keys', () {
    final bindings = ModeBindings({'a': 'matched'}, fallback: 'fallback');
    expect(matchKeys(bindings, 'a'), (KeyMatch.match, 'matched'));
    expect(matchKeys(bindings, 'x'), (KeyMatch.match, 'fallback'));
  });

  test('MatchKeys no fallback returns none', () {
    final bindings = ModeBindings<String>({'a': 'matched'});
    expect(matchKeys(bindings, 'a'), (KeyMatch.match, 'matched'));
    expect(matchKeys(bindings, 'x'), (KeyMatch.none, null));
  });
}
