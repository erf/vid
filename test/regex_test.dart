import 'package:test/test.dart';

import 'package:vid/regex.dart';

void main() {
  group('Regex', () {
    test('isEmoji', () {
      expect(Regex.emoji.hasMatch('😀'), true);
      expect(Regex.emoji.hasMatch('a'), false);
      expect(Regex.emoji.hasMatch('Æ'), false);
      expect(Regex.emoji.hasMatch('👨‍👨‍👧‍👧'), true);
    });
  });
}
