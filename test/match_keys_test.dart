import 'package:test/test.dart';
import 'package:vid/map_match.dart';

void main() {
  test('MatchKeys none, partial, and match for key bindings', () {
    final map = <String, bool>{'a': true, 'bc': true, 'abc': true};
    expect(matchKeys(map, 'c'), (KeyMatch.none, null));
    expect(matchKeys(map, 'b'), (KeyMatch.partial, null));
    expect(matchKeys(map, 'ab'), (KeyMatch.partial, null));
    expect(matchKeys(map, 'a'), (KeyMatch.match, true));
  });
}
