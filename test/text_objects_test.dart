import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/editor.dart';

void main() {
  group('Parentheses text objects', () {
    test('di( deletes inside parentheses', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(bar baz)qux\n';
      f.cursor = 5; // on 'a' in 'bar'
      e.input('di(');
      expect(f.text, 'foo()qux\n');
    });

    test('dib deletes inside parentheses (alias)', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(bar baz)qux\n';
      f.cursor = 5;
      e.input('dib');
      expect(f.text, 'foo()qux\n');
    });

    test('da( deletes around parentheses', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(bar baz)qux\n';
      f.cursor = 5;
      e.input('da(');
      expect(f.text, 'fooqux\n');
    });

    test('dab deletes around parentheses (alias)', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(bar baz)qux\n';
      f.cursor = 5;
      e.input('dab');
      expect(f.text, 'fooqux\n');
    });

    test('ci( changes inside parentheses', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(bar baz)qux\n';
      f.cursor = 5;
      e.input('ci(');
      expect(f.text, 'foo()qux\n');
      expect(f.cursor, 4); // Inside the empty parens
    });

    test('nested parentheses - cursor in inner', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo((inner))bar\n';
      f.cursor = 5; // on 'i' in 'inner'
      e.input('di(');
      expect(f.text, 'foo(())bar\n');
    });

    test('nested parentheses - cursor in outer', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(x(inner)y)bar\n';
      f.cursor = 4; // on 'x' before inner parens
      e.input('di(');
      expect(f.text, 'foo()bar\n');
    });

    test('cursor on opening paren', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(bar)baz\n';
      f.cursor = 3; // on '('
      e.input('di(');
      expect(f.text, 'foo()baz\n');
    });

    test('cursor on closing paren', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(bar)baz\n';
      f.cursor = 7; // on ')'
      e.input('di(');
      expect(f.text, 'foo()baz\n');
    });

    test('no matching parens - does nothing', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar baz\n';
      f.cursor = 4;
      e.input('di(');
      expect(f.text, 'foo bar baz\n');
    });
  });

  group('Braces text objects', () {
    test('di{ deletes inside braces', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo{bar baz}qux\n';
      f.cursor = 5;
      e.input('di{');
      expect(f.text, 'foo{}qux\n');
    });

    test('diB deletes inside braces (alias)', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo{bar baz}qux\n';
      f.cursor = 5;
      e.input('diB');
      expect(f.text, 'foo{}qux\n');
    });

    test('da{ deletes around braces', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo{bar baz}qux\n';
      f.cursor = 5;
      e.input('da{');
      expect(f.text, 'fooqux\n');
    });

    test('daB deletes around braces (alias)', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo{bar baz}qux\n';
      f.cursor = 5;
      e.input('daB');
      expect(f.text, 'fooqux\n');
    });
  });

  group('Brackets text objects', () {
    test('di[ deletes inside brackets', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo[bar baz]qux\n';
      f.cursor = 5;
      e.input('di[');
      expect(f.text, 'foo[]qux\n');
    });

    test('da[ deletes around brackets', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo[bar baz]qux\n';
      f.cursor = 5;
      e.input('da[');
      expect(f.text, 'fooqux\n');
    });
  });

  group('Angle brackets text objects', () {
    test('di< deletes inside angle brackets', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo<bar baz>qux\n';
      f.cursor = 5;
      e.input('di<');
      expect(f.text, 'foo<>qux\n');
    });

    test('da< deletes around angle brackets', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo<bar baz>qux\n';
      f.cursor = 5;
      e.input('da<');
      expect(f.text, 'fooqux\n');
    });
  });

  group('Quote text objects', () {
    test('di" deletes inside double quotes', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo"bar baz"qux\n';
      f.cursor = 5;
      e.input('di"');
      expect(f.text, 'foo""qux\n');
    });

    test('da" deletes around double quotes', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo"bar baz"qux\n';
      f.cursor = 5;
      e.input('da"');
      expect(f.text, 'fooqux\n');
    });

    test("di' deletes inside single quotes", () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = "foo'bar baz'qux\n";
      f.cursor = 5;
      e.input("di'");
      expect(f.text, "foo''qux\n");
    });

    test("da' deletes around single quotes", () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = "foo'bar baz'qux\n";
      f.cursor = 5;
      e.input("da'");
      expect(f.text, 'fooqux\n');
    });

    test('di` deletes inside backticks', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo`bar baz`qux\n';
      f.cursor = 5;
      e.input('di`');
      expect(f.text, 'foo``qux\n');
    });

    test('cursor on opening quote', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo"bar"baz\n';
      f.cursor = 3; // on '"'
      e.input('di"');
      expect(f.text, 'foo""baz\n');
    });

    test('cursor on closing quote', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo"bar"baz\n';
      f.cursor = 7; // on closing '"'
      e.input('di"');
      expect(f.text, 'foo""baz\n');
    });

    test('multiple quote pairs on line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = '"first" "second"\n';
      f.cursor = 10; // in 'second'
      e.input('di"');
      expect(f.text, '"first" ""\n');
    });
  });

  group('Word text objects', () {
    test('diw deletes inside word', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar baz\n';
      f.cursor = 4; // on 'b' in 'bar'
      e.input('diw');
      expect(f.text, 'foo  baz\n');
    });

    test('daw deletes around word (with trailing space)', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar baz\n';
      f.cursor = 4; // on 'b' in 'bar'
      e.input('daw');
      expect(f.text, 'foo baz\n');
    });

    test('daw deletes around word (with leading space when at end)', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar\n';
      f.cursor = 4; // on 'b' in 'bar'
      e.input('daw');
      expect(f.text, 'foo\n');
    });

    test('ciw changes word', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar baz\n';
      f.cursor = 4;
      e.input('ciw');
      expect(f.text, 'foo  baz\n');
      expect(f.cursor, 4);
    });

    test('diw on underscore word', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo_bar_baz qux\n';
      f.cursor = 4; // on 'b' in 'bar'
      e.input('diw');
      expect(f.text, ' qux\n');
    });

    test('yiw yanks word', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar baz\n';
      f.cursor = 4;
      e.input('yiw');
      expect(f.text, 'foo bar baz\n');
      expect(e.yankBuffer?.text, 'bar');
    });
  });

  group('WORD text objects', () {
    test('diW deletes inside WORD', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar-baz qux\n';
      f.cursor = 5; // on 'a' in 'bar-baz'
      e.input('diW');
      expect(f.text, 'foo  qux\n');
    });

    test('daW deletes around WORD', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo bar-baz qux\n';
      f.cursor = 5;
      e.input('daW');
      expect(f.text, 'foo qux\n');
    });
  });

  group('Sentence text objects', () {
    test('dis deletes inside sentence', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'First sentence. Second sentence. Third.\n';
      f.cursor = 20; // in 'Second'
      e.input('dis');
      expect(f.text, 'First sentence.  Third.\n');
    });

    test('das deletes around sentence', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'First sentence. Second sentence. Third.\n';
      f.cursor = 20; // in 'Second'
      e.input('das');
      expect(f.text, 'First sentence. Third.\n');
    });
  });

  group('Paragraph text objects', () {
    test('dip deletes inside paragraph', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'First para.\n\nSecond para.\n\nThird para.\n';
      f.cursor = 14; // in 'Second'
      e.input('dip');
      expect(f.text, 'First para.\n\n\nThird para.\n');
    });

    test('dap deletes around paragraph', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'First para.\n\nSecond para.\n\nThird para.\n';
      f.cursor = 14;
      e.input('dap');
      expect(f.text, 'First para.\n\nThird para.\n');
    });
  });

  group('Edge cases', () {
    test('empty brackets', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo()bar\n';
      f.cursor = 4; // between ( and )
      e.input('di(');
      // Already empty, should do nothing
      expect(f.text, 'foo()bar\n');
    });

    test('multiline brackets', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(\n  bar\n  baz\n)qux\n';
      f.cursor = 7; // on 'bar'
      e.input('di(');
      expect(f.text, 'foo()qux\n');
    });

    test('deeply nested brackets', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'a(b(c(d)e)f)g\n';
      f.cursor = 6; // on 'd'
      e.input('di(');
      expect(f.text, 'a(b(c()e)f)g\n');
    });
  });
}
