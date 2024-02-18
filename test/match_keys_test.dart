import 'package:test/test.dart';

import 'package:vid/match_keys.dart';

void main() {
  test('MatchKeys none, partial, and match for key bindings', () {
    Map map = {
      'a': true,
      'bc': true,
      'abc': true,
    };
    expect(map.partialMatch('c'), KeyMatch.none);
    expect(map.partialMatch('b'), KeyMatch.partial);
    expect(map.partialMatch('ab'), KeyMatch.partial);
    expect(map.partialMatch('a'), KeyMatch.match);
  });
}
