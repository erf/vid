import 'package:test/test.dart';
import 'package:vid/input/input.dart';

void main() {
  group('InputParser', () {
    late InputParser parser;

    setUp(() {
      parser = InputParser();
    });

    test('parses regular characters', () {
      final events = parser.parse('abc');
      expect(events.length, 3);
      expect(events[0], isA<KeyEvent>());
      expect((events[0] as KeyEvent).key, 'a');
      expect((events[1] as KeyEvent).key, 'b');
      expect((events[2] as KeyEvent).key, 'c');
    });

    test('parses escape key alone', () {
      final events = parser.parse('\x1b');
      expect(events.length, 1);
      expect((events[0] as KeyEvent).key, 'escape');
    });

    test('parses arrow keys (CSI)', () {
      final events = parser.parse('\x1b[A\x1b[B\x1b[C\x1b[D');
      expect(events.length, 4);
      expect((events[0] as KeyEvent).key, 'up');
      expect((events[1] as KeyEvent).key, 'down');
      expect((events[2] as KeyEvent).key, 'right');
      expect((events[3] as KeyEvent).key, 'left');
    });

    test('parses arrow keys (SS3)', () {
      final events = parser.parse('\x1bOA\x1bOB');
      expect(events.length, 2);
      expect((events[0] as KeyEvent).key, 'up');
      expect((events[1] as KeyEvent).key, 'down');
    });

    test('buffers incomplete CSI sequence', () {
      // Send incomplete sequence
      var events = parser.parse('\x1b[');
      expect(events.isEmpty, true);
      expect(parser.hasBufferedInput, true);

      // Complete it
      events = parser.parse('A');
      expect(events.length, 1);
      expect((events[0] as KeyEvent).key, 'up');
    });

    test('buffers incomplete SS3 sequence', () {
      var events = parser.parse('\x1bO');
      expect(events.isEmpty, true);
      expect(parser.hasBufferedInput, true);

      events = parser.parse('A');
      expect(events.length, 1);
      expect((events[0] as KeyEvent).key, 'up');
    });

    test('parses navigation keys', () {
      final events = parser.parse('\x1b[5~\x1b[6~'); // PageUp, PageDown
      expect(events.length, 2);
      expect((events[0] as KeyEvent).key, 'pageup');
      expect((events[1] as KeyEvent).key, 'pagedown');
    });

    test('parses function keys', () {
      final events = parser.parse('\x1bOP\x1b[15~'); // F1, F5
      expect(events.length, 2);
      expect((events[0] as KeyEvent).key, 'f1');
      expect((events[1] as KeyEvent).key, 'f5');
    });

    test('parses Ctrl+arrow with modifiers', () {
      final events = parser.parse('\x1b[1;5A'); // Ctrl+Up
      expect(events.length, 1);
      final key = events[0] as KeyEvent;
      expect(key.key, 'up');
      expect(key.ctrl, true);
      expect(key.alt, false);
      expect(key.shift, false);
    });

    test('parses mixed input', () {
      final events = parser.parse('a\x1b[Ab');
      expect(events.length, 3);
      expect((events[0] as KeyEvent).key, 'a');
      expect((events[1] as KeyEvent).key, 'up');
      expect((events[2] as KeyEvent).key, 'b');
    });

    test('parses control characters', () {
      final events = parser.parse('\x01\x03'); // Ctrl+A, Ctrl+C
      expect(events.length, 2);
      expect((events[0] as KeyEvent).key, 'a');
      expect((events[0] as KeyEvent).ctrl, true);
      expect((events[1] as KeyEvent).key, 'c');
      expect((events[1] as KeyEvent).ctrl, true);
    });

    test('parses backspace', () {
      final events = parser.parse('\x7f');
      expect(events.length, 1);
      expect((events[0] as KeyEvent).key, 'backspace');
    });

    test('parses enter', () {
      final events = parser.parse('\n');
      expect(events.length, 1);
      expect((events[0] as KeyEvent).key, 'enter');
    });

    test('parses tab', () {
      final events = parser.parse('\t');
      expect(events.length, 1);
      expect((events[0] as KeyEvent).key, 'tab');
    });

    test('parses mouse events', () {
      final events = parser.parse('\x1b[<0;10;5M'); // Mouse click
      expect(events.length, 1);
      expect(events[0], isA<MouseInputEvent>());
    });

    test('flush returns buffered as escape', () {
      parser.parse('\x1b['); // Incomplete
      final events = parser.flush();
      expect(events.length, 2); // ESC and [
      expect(parser.hasBufferedInput, false);
    });

    test('raw sequence preserved for binding matching', () {
      final events = parser.parse('\x1b[A');
      expect(events.length, 1);
      expect((events[0] as KeyEvent).raw, '\x1b[A');
    });
  });
}
