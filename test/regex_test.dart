import 'package:test/test.dart';

import 'package:vid/regex.dart';

void main() {
  group('Regex', () {
    test('isEmoji', () {
      expect(Regex.isEmoji.hasMatch('😀'), true);
      expect(Regex.isEmoji.hasMatch('a'), false);
      expect(Regex.isEmoji.hasMatch('Æ'), false);
      expect(Regex.isEmoji.hasMatch('👨‍👨‍👧‍👧'), true);
    });
  });
}
