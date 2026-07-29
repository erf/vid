import 'package:test/test.dart';
import 'package:vid/regex_ext.dart';

void main() {
  group('nextMatch', () {
    final word = RegExp(r'\w+');

    test('returns start of next match after offset', () {
      expect(word.nextMatch('abc def', 1), 4);
    });

    test('match at offset with no later match returns its end', () {
      // Only one match: firstWhere falls back to matches.first, whose
      // start == offset, so its end is returned (moves off the match).
      expect(word.nextMatch('abc', 0), 3);
    });

    test('match containing offset is not seen', () {
      expect(word.nextMatch('abc def', 2), 4);
    });

    test('returns offset unchanged when no match found', () {
      expect(word.nextMatch('   ', 0), 0);
      expect(word.nextMatch('abc', 3), 3);
    });

    test('skip starts scanning at offset + skip', () {
      // Scan starts at index 1, so the first match is 'bc' at 1.
      expect(word.nextMatch('abc def', 0, skip: 1), 1);
    });
  });

  group('prevMatch', () {
    final word = RegExp(r'\w+');

    test('returns start of previous match', () {
      expect(word.prevMatch('abc def', 6), 4);
    });

    test('match at offset boundary returns enclosing match start', () {
      // offset 3 is the space after 'abc'; enclosing match is 'abc'
      expect(word.prevMatch('abc def', 3), 0);
    });

    test('offset inside match returns that match start', () {
      expect(word.prevMatch('abc def', 5), 4);
    });

    test('returns offset unchanged when no match found', () {
      expect(word.prevMatch('   ', 2), 2);
      expect(word.prevMatch('abc', 0), 0);
    });

    test('expands chunks to find distant match', () {
      final text = 'word${' ' * 2000}';
      expect(word.prevMatch(text, text.length), 0);
    });
  });
}
