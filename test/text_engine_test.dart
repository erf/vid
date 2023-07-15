import 'package:test/test.dart';
import 'package:vid/text_engine.dart';

void main() {
  test('TextEngine.insert', () {
    expect(TextEngine().insert('abc', 0, 'd'), 'dabc');
    expect(TextEngine().insert('abc', 1, 'd'), 'adbc');
    expect(TextEngine().insert('abc', 3, 'd'), 'abcd');
    expect(TextEngine().insert('abc', 0, 'YO'), 'YOabc');
  });

  test('TextEngine.replace', () {
    expect(TextEngine().replace('abc', 0, 1, 'd'), 'dbc');
    expect(TextEngine().replace('abc', 1, 2, 'd'), 'adc');
    expect(TextEngine().replace('abc', 3, 3, 'd'), 'abcd');
  });

  test('TextEngine.replace', () {
    expect(TextEngine().replaceChar('abc', 0, 'd'), 'dbc');
    expect(TextEngine().replaceChar('abc', 1, 'd'), 'adc');
    expect(TextEngine().replaceChar('abc', 2, 'd'), 'abd');
  });

  test('TextEngine.delete', () {
    expect(TextEngine().delete('abc', 0, 1), 'bc');
    expect(TextEngine().delete('abc', 1, 2), 'ac');
    expect(TextEngine().delete('abc', 2, 3), 'ab');
  });
}
