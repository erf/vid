import 'package:test/test.dart';

void main() {
  test('isEmojiRegex', () {
    expect(isEmojiRegex.hasMatch('😀'), true);
    expect(isEmojiRegex.hasMatch('a'), false);
    expect(isEmojiRegex.hasMatch('Æ'), false);
    expect(isEmojiRegex.hasMatch('👨‍👨‍👧‍👧'), true);
  });
}

final isEmojiRegex =
    RegExp(r'[\p{Extended_Pictographic}\p{Emoji_Presentation}]', unicode: true);
