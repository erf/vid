import 'package:test/test.dart';
import 'package:vid/string_ext.dart';

// also see test/string_ext_test.dart
void main() {
  test('isEmoji test', () {
    expect('a'.isEmoji, false);
    expect('▫︎'.isEmoji, false);
    expect('❤️'.isEmoji, true);
    expect('❤️‍🔥'.isEmoji, true);
    expect('👩‍👩‍👦‍👦'.isEmoji, true);
  });
}
