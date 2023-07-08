import 'package:test/test.dart';
import 'package:vid/utils.dart';

void main() {
  // write a test for the 'clamp' function
  test('clamp low', () {
    final result = clamp(0, 5, 10);
    expect(result, 5);
  });

  test('clamp high', () {
    final result = clamp(15, 5, 10);
    expect(result, 10);
  });
}
