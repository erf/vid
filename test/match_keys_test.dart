import 'package:test/test.dart';

import 'package:vid/match_keys.dart';

void main() {
  test('MatchKeys none, partial, and match for key bindings', () {
    var map = {
      'a': true,
      'bc': true,
    };
    expect(matchKeys(map, 'c'), InputMatch.none);
    expect(matchKeys(map, 'b'), InputMatch.partial);
    expect(matchKeys(map, 'a'), InputMatch.match);
  });
}
