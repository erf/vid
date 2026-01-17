import 'package:termio/testing.dart';
import 'package:test/test.dart';
import 'package:vid/actions/motion_actions.dart';
import 'package:vid/config.dart';
import 'package:vid/editor.dart';

void main() {
  test('motionCharNext', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    // Test moving from offset 0 (char 'a')
    expect(MotionActions.charNext(e, f, 0), 1); // a -> b
    expect(MotionActions.charNext(e, f, 2), 3); // c -> \n
    expect(MotionActions.charNext(e, f, 3), 4); // \n -> d
    expect(MotionActions.charNext(e, f, 4), 5); // d -> e
    expect(MotionActions.charNext(e, f, 6), 7); // f -> \n
  });

  test('motionCharPrev', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    expect(MotionActions.charPrev(e, f, 0), 0); // at start, stay
    expect(MotionActions.charPrev(e, f, 2), 1); // c -> b
    expect(MotionActions.charPrev(e, f, 4), 3); // d -> \n
    expect(MotionActions.charPrev(e, f, 6), 5); // f -> e
  });

  test('motion.lineUp', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    // From line 0, stay at line 0
    expect(MotionActions.lineUp(e, f, 0), 0);
    f.desiredColumn = null; // Reset between independent tests
    expect(MotionActions.lineUp(e, f, 2), 2);
    f.desiredColumn = null;
    // From line 1, go to line 0
    expect(MotionActions.lineUp(e, f, 4), 0); // d -> a (same column)
    f.desiredColumn = null;
    expect(MotionActions.lineUp(e, f, 6), 2); // f -> c (same column)
  });

  test('motion.lineUp with emojis', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abcdef\n😎😍👽\nghijkl\n';
    // Line 0: 'abcdef\n' (0-6), Line 1: '😎😍👽\n' (7-13), Line 2: 'ghijkl\n' (14-20)
    // From line 2 col 2 (offset 16 = 'i') -> should go to line 1
    int line2Col2 = 14 + 2; // 16 = 'i' in 'ghijkl'
    int result = MotionActions.lineUp(e, f, line2Col2);
    // Should land on line 1 (the emoji line)
    expect(f.lineNumber(result), 1);
  });

  test('motion.lineDown', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    // From line 0, go to line 1
    expect(MotionActions.lineDown(e, f, 0), 4); // a -> d
    f.desiredColumn = null; // Reset between independent tests
    expect(MotionActions.lineDown(e, f, 2), 6); // c -> f
    f.desiredColumn = null;
    // From line 1, stay at line 1 (last line)
    expect(MotionActions.lineDown(e, f, 4), 4);
    f.desiredColumn = null;
    expect(MotionActions.lineDown(e, f, 6), 6);
  });

  test('motion.lineDown with emojis', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abcdef\n😎😍👽\nghijkl\n';
    // From line 0 col 2 -> line 1 (should land on appropriate grapheme)
    int result = MotionActions.lineDown(e, f, 2);
    expect(f.lineNumber(result), 1);
  });

  test('sticky column preserves column through short lines', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    // Line 0: 'abcdefgh' (8 chars), Line 1: 'xy' (2 chars), Line 2: '12345678' (8 chars)
    f.text = 'abcdefgh\nxy\n12345678\n';

    // Start at column 6 ('g' at offset 6)
    f.cursor = 6;
    f.desiredColumn = null;

    // Move down - should go to end of short line (offset 9, 'x' at col 0 or 'y' at col 1)
    // but remember column 6
    int pos1 = MotionActions.lineDown(e, f, 6);
    expect(f.lineNumber(pos1), 1);
    expect(f.desiredColumn, 6); // Column 6 is remembered

    // Move down again - should restore to column 6 on line 2 (offset 12 + 6 = 18)
    int pos2 = MotionActions.lineDown(e, f, pos1);
    expect(f.lineNumber(pos2), 2);
    expect(pos2, 12 + 6); // '7' at offset 18
  });

  test('sticky column with line end motion', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndefgh\nij\n';

    // Use $ to go to end of line 0 ('c' at offset 2)
    f.cursor = 0;
    int endPos = MotionActions.lineEnd(e, f, 0);
    expect(endPos, 2); // 'c'
    expect(
      f.desiredColumn,
      MotionActions.endOfLineColumn,
    ); // End-of-line sentinel

    // Move down - should go to end of line 1 ('h' at offset 8)
    int pos1 = MotionActions.lineDown(e, f, endPos);
    expect(pos1, 8); // 'h' (last char before newline on line 1)

    // Move down again - should go to end of line 2 ('j' at offset 11)
    int pos2 = MotionActions.lineDown(e, f, pos1);
    expect(pos2, 11); // 'j' (last char before newline on line 2)
  });

  test('sticky column disabled via config', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
      config: const Config(preserveColumnOnVerticalMove: false),
    );
    final f = e.file;
    f.text = 'abcdefgh\nxy\n12345678\n';

    // Start at column 6
    f.cursor = 6;
    f.desiredColumn = null;

    // Move down - should go to end of short line
    int pos1 = MotionActions.lineDown(e, f, 6);
    expect(f.lineNumber(pos1), 1);
    expect(f.desiredColumn, isNull); // Not set when disabled

    // Move down again - should use current column (1), not remembered column
    int pos2 = MotionActions.lineDown(e, f, pos1);
    expect(f.lineNumber(pos2), 2);
    // pos1 is at 'y' (col 1), so next line should be at col 1 ('2' at offset 13)
    expect(pos2, 12 + 1); // '2' at offset 13
  });

  test('motionFileStart', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    expect(MotionActions.fileStart(e, f, 0), 0);
    expect(MotionActions.fileStart(e, f, 2), 0);
    expect(MotionActions.fileStart(e, f, 4), 0);
    expect(MotionActions.fileStart(e, f, 6), 0);
  });

  test('motionFileEnd', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc\ndef\n';
    // Should go to start of last line
    expect(MotionActions.fileEnd(e, f, 0), 4);
    expect(MotionActions.fileEnd(e, f, 2), 4);
    expect(MotionActions.fileEnd(e, f, 4), 4);
    expect(MotionActions.fileEnd(e, f, 6), 4);
  });

  test('motionWordNext', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc def ghi\njkl mno pqr\n';
    expect(MotionActions.wordNext(e, f, 0), 4); // abc -> def
    expect(MotionActions.wordNext(e, f, 3), 4); // space -> def
    expect(MotionActions.wordNext(e, f, 4), 8); // def -> ghi
    expect(MotionActions.wordNext(e, f, 8), 12); // ghi -> jkl (next line)
    expect(MotionActions.wordNext(e, f, 14), 16); // jkl -> mno
  });

  test('motionWordCapNext', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc,def ghi\n';
    // WORD skips punctuation
    expect(MotionActions.wordCapNext(e, f, 0), 8); // abc,def -> ghi
  });

  test('motionWordEnd', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc def ghi\njkl mno pqr\n';
    expect(MotionActions.wordEnd(e, f, 0), 2); // abc -> c
    expect(MotionActions.wordEnd(e, f, 3), 6); // space -> f
    expect(MotionActions.wordEnd(e, f, 4), 6); // def -> f
    expect(MotionActions.wordEnd(e, f, 8), 10); // ghi -> i
    expect(MotionActions.wordEnd(e, f, 10), 14); // i -> l (next line)
  });

  test('motionWordPrev', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    expect(MotionActions.wordPrev(e, f, 0), 0); // at start, stay
    // Note: emoji sequence has length 14 bytes
    // 'abc d❤️‍🔥f ghi\n' = 'abc ' (4) + 'd' (1) + emoji (14) + 'f ghi\n' (6)
    int emojiStart = 5;
    expect(MotionActions.wordPrev(e, f, 4), 0); // space -> abc
    expect(MotionActions.wordPrev(e, f, emojiStart), 4); // d -> space/abc
  });

  test('motionWordCapPrev', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc def, ghi\n';
    // WORD skips punctuation when going backwards
    expect(MotionActions.wordCapPrev(e, f, 9), 4); // ghi -> def,
  });

  test('motionWordNext with Unicode', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    // Test various Unicode scripts: Latin Extended, Cyrillic, CJK
    // Dart strings use UTF-16 code units
    f.text = 'café мир 你好\n';
    // café (4) + space (1) = 5 -> мир starts at 5
    expect(MotionActions.wordNext(e, f, 0), 5);
    // мир (3) + space (1) = 4 -> 你好 starts at 9
    expect(MotionActions.wordNext(e, f, 5), 9);
  });

  test('motionWordPrev with Unicode', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'café мир 你好\n';
    // 你好 (at 9) -> мир (at 5)
    expect(MotionActions.wordPrev(e, f, 9), 5);
    // мир (at 5) -> café (at 0)
    expect(MotionActions.wordPrev(e, f, 5), 0);
  });

  test('motionWordEnd with Unicode', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'café мир\n';
    // café: 4 chars, end at index 3
    expect(MotionActions.wordEnd(e, f, 0), 3);
    // мир: starts at 5, 3 chars, end at index 7
    expect(MotionActions.wordEnd(e, f, 5), 7);
  });

  test('motionWord treats emoji as separate word', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    // Emoji should be treated as punctuation (separate word unit)
    // 🎉 is 2 UTF-16 code units (surrogate pair)
    f.text = 'hello🎉world\n';
    // hello (5) -> 🎉 at 5
    expect(MotionActions.wordNext(e, f, 0), 5);
    // 🎉 (2 code units) -> world at 7
    expect(MotionActions.wordNext(e, f, 5), 7);
  });

  test('motionWordEndPrev', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc d❤️‍🔥f ghi\njkl mno pqr\n';
    // Going backwards to end of previous word
    expect(MotionActions.wordEndPrev(e, f, 4), 2); // space -> c
  });

  test('motionFindWordOnCursorNext', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'det er fint, fint er det saus\n';
    // Find next occurrence of word under cursor
    expect(MotionActions.sameWordNext(e, f, 0), 21); // det -> det
    expect(MotionActions.sameWordNext(e, f, 7), 13); // fint -> fint
  });

  test('motionFindWordOnCursorPrev', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'det er fint, fint er det saus\n';
    expect(MotionActions.sameWordPrev(e, f, 13), 7); // fint -> fint
  });

  test('motionFirstNoneBlank', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = '  abc\n';
    // Should go to first non-blank character
    expect(MotionActions.firstNonBlank(e, f, 0), 2);
    expect(MotionActions.firstNonBlank(e, f, 1), 2);
    expect(MotionActions.firstNonBlank(e, f, 2), 2);
    expect(MotionActions.firstNonBlank(e, f, 3), 2);
    expect(MotionActions.firstNonBlank(e, f, 5), 2);
  });

  test('motionLineEnd', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'abc def\nghi jkl\n';
    // Should go to last character of line (before \n)
    expect(MotionActions.lineEnd(e, f, 0), 6); // a -> f (offset 6)
    expect(MotionActions.lineEnd(e, f, 3), 6); // space -> f
    expect(MotionActions.lineEnd(e, f, 8), 14); // g -> l (offset 14)
    expect(MotionActions.lineEnd(e, f, 11), 14); // space -> l
  });

  test('FindNextCharMotion with dot', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'test.\n';
    f.edit.findStr = '.';
    expect(MotionActions.findNextChar(e, f, 0), 4);
  });

  test('FindPrevCharMotion with dot', () {
    final e = Editor(
      terminal: TestTerminal(width: 80, height: 24),
      redraw: false,
    );
    final f = e.file;
    f.text = 'hello. test.\n';
    f.edit.findStr = '.';
    expect(MotionActions.findPrevChar(e, f, 10), 5);
  });

  test(
    'motionWordPrev with many lines (tests limited search with fallback)',
    () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      // Create text with many lines - word at start, then many empty-ish lines
      final sb = StringBuffer();
      sb.write('firstword\n');
      for (int i = 0; i < 50; i++) {
        sb.write('line $i with words here\n');
      }
      f.text = sb.toString();

      // From end of file, should be able to navigate backwards
      final lastLineStart = f.text.lastIndexOf('\n', f.text.length - 2) + 1;
      final offset = lastLineStart + 5; // somewhere in last line

      // Should find previous word on same line
      final result = MotionActions.wordPrev(e, f, offset);
      expect(result < offset, true);

      // Should eventually be able to reach the first word
      var pos = f.text.length - 2;
      for (int i = 0; i < 500 && pos > 0; i++) {
        final newPos = MotionActions.wordPrev(e, f, pos);
        if (newPos == pos) break; // stuck
        pos = newPos;
      }
      expect(pos, 0); // should reach "firstword" at offset 0
    },
  );

  group('paragraph motions', () {
    test('paragraphNext moves to next empty line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\ndef\n\nghi\n';
      // Text structure: 'abc\ndef\n\nghi\n'
      // Offsets:         0123 4567 8 9...
      // Empty line is at offset 8

      // From start of file, should move to empty line
      expect(MotionActions.paragraphNext(e, f, 0), 8);
      // From middle of first paragraph
      expect(MotionActions.paragraphNext(e, f, 5), 8);
      // From end of line (the \n at offset 7)
      expect(MotionActions.paragraphNext(e, f, 7), 8);
    });

    test('paragraphNext from empty line moves to next empty line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\n\ndef\n\nghi\n';
      // Text structure: 'abc\n\ndef\n\nghi\n'
      // Offsets:         0123 4 5678 9 ...
      // First empty line at 4, second at 9

      // From first empty line, should move to second
      expect(MotionActions.paragraphNext(e, f, 4), 9);
    });

    test('paragraphNext treats consecutive empty lines as one boundary', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\n\n\n\ndef\n';
      // Text structure: 'abc\n\n\n\ndef\n'
      // Offsets:         0123 4 5 6 789...
      // Empty lines at 4, 5, 6

      // From start, should land on first empty line
      int pos = MotionActions.paragraphNext(e, f, 0);
      expect(pos, 4);

      // Successive calls should move through each empty line
      // until reaching the end or no more matches
      pos = MotionActions.paragraphNext(e, f, pos);
      expect(pos, 5);
      pos = MotionActions.paragraphNext(e, f, pos);
      expect(pos, 6);
    });

    test('paragraphNext stays at end when no more paragraphs', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\ndef\n';
      // No empty lines, should stay at current position
      expect(MotionActions.paragraphNext(e, f, 0), 0);
    });

    test('paragraphPrev moves to previous empty line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\n\ndef\n';
      // Text structure: 'abc\n\ndef\n'
      // Offsets:         0123 4 5678
      // Empty line at 4

      // From end of file, should move to empty line
      expect(MotionActions.paragraphPrev(e, f, 8), 4);
      // From 'def', should move to empty line
      expect(MotionActions.paragraphPrev(e, f, 6), 4);
    });

    test('paragraphPrev from empty line moves to previous empty line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\n\ndef\n\nghi\n';
      // First empty line at 4, second at 9

      // From second empty line, should move to first
      expect(MotionActions.paragraphPrev(e, f, 9), 4);
    });

    test('paragraphPrev moves to start of file when no empty line before', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'abc\ndef\n';
      // No empty lines, first paragraph starts at 0

      // From middle of file, should move to start
      expect(MotionActions.paragraphPrev(e, f, 5), 0);
      // From first empty line, should move to start
      f.text = 'abc\n\ndef\n';
      expect(MotionActions.paragraphPrev(e, f, 4), 0);
    });
  });

  group('sentence motions', () {
    test('sentenceNext moves to next sentence after period', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'Hello world. This is next.\n';
      // Text:    'Hello world. This is next.\n'
      // Offsets:  0          11 13
      // 'T' of "This" is at offset 13

      // From start, should move to 'T' of "This"
      expect(MotionActions.sentenceNext(e, f, 0), 13);
    });

    test('sentenceNext moves past end of line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'First sentence.\nSecond sentence.\n';
      // 'S' of "Second" is at offset 16

      // From end of first line (offset 15 = \n), should move to 'S'
      expect(MotionActions.sentenceNext(e, f, 15), 16);
      // From middle of first sentence, should move to 'S'
      expect(MotionActions.sentenceNext(e, f, 5), 16);
    });

    test('sentenceNext with exclamation and question marks', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'What! Really? Yes.\n';
      // 'R' at 6, 'Y' at 14

      expect(MotionActions.sentenceNext(e, f, 0), 6); // What! -> Really
      expect(MotionActions.sentenceNext(e, f, 6), 14); // Really? -> Yes
    });

    test('sentenceNext from sentence start moves to next sentence', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'One. Two. Three.\n';
      // 'O' at 0, 'T' at 5, 'T' at 10

      int pos = 0;
      pos = MotionActions.sentenceNext(e, f, pos);
      expect(pos, 5); // -> Two
      pos = MotionActions.sentenceNext(e, f, pos);
      expect(pos, 10); // -> Three
    });

    test('sentenceNext lands on empty line before next paragraph', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'First para.\n\nSecond para.\n';
      // Text:    'First para.\n\nSecond para.\n'
      // Offsets:  0          11 12 13
      // Empty line at 12, 'S' at 13

      // From start, should first land on empty line
      expect(MotionActions.sentenceNext(e, f, 0), 12);
      // From empty line, should move to 'S'
      expect(MotionActions.sentenceNext(e, f, 12), 13);
    });

    test('sentencePrev moves to previous sentence', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'Hello world. This is next.\n';
      // 'H' at 0, 'T' at 13

      // From end, should move to 'T' of "This"
      expect(MotionActions.sentencePrev(e, f, 25), 13);
      // From 'T', should move to 'H'
      expect(MotionActions.sentencePrev(e, f, 13), 0);
    });

    test('sentencePrev with multiple sentences', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'One. Two. Three.\n';
      // 'O' at 0, 'T' at 5, 'T' at 10

      expect(MotionActions.sentencePrev(e, f, 16), 10); // end -> Three
      expect(MotionActions.sentencePrev(e, f, 10), 5); // Three -> Two
      expect(MotionActions.sentencePrev(e, f, 5), 0); // Two -> One
    });
  });

  group('matchBracket motions', () {
    test('matchBracket from opening paren to closing', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(bar)\n';
      // Offsets: f=0, o=1, o=2, (=3, b=4, a=5, r=6, )=7
      expect(MotionActions.matchBracket(e, f, 3), 7); // ( -> )
    });

    test('matchBracket from closing paren to opening', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(bar)\n';
      expect(MotionActions.matchBracket(e, f, 7), 3); // ) -> (
    });

    test('matchBracket with nested parens', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(a(b)c)\n';
      // Offsets: f=0, o=1, o=2, (=3, a=4, (=5, b=6, )=7, c=8, )=9
      expect(MotionActions.matchBracket(e, f, 3), 9); // outer ( -> outer )
      expect(MotionActions.matchBracket(e, f, 5), 7); // inner ( -> inner )
      expect(MotionActions.matchBracket(e, f, 7), 5); // inner ) -> inner (
      expect(MotionActions.matchBracket(e, f, 9), 3); // outer ) -> outer (
    });

    test('matchBracket with curly braces', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'if {foo}\n';
      // Offsets: i=0, f=1, space=2, {=3, f=4, o=5, o=6, }=7
      expect(MotionActions.matchBracket(e, f, 3), 7); // { -> }
      expect(MotionActions.matchBracket(e, f, 7), 3); // } -> {
    });

    test('matchBracket with square brackets', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'arr[0]\n';
      // Offsets: a=0, r=1, r=2, [=3, 0=4, ]=5
      expect(MotionActions.matchBracket(e, f, 3), 5); // [ -> ]
      expect(MotionActions.matchBracket(e, f, 5), 3); // ] -> [
    });

    test('matchBracket searches forward on line when not on bracket', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(bar)\n';
      // From 'f', should find '(' and jump to ')'
      expect(MotionActions.matchBracket(e, f, 0), 7); // f -> )
      expect(MotionActions.matchBracket(e, f, 1), 7); // first o -> )
    });

    test('matchBracket stays when no bracket found on line', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'no brackets here\n';
      expect(MotionActions.matchBracket(e, f, 0), 0); // stays at 0
      expect(MotionActions.matchBracket(e, f, 5), 5); // stays at 5
    });

    test('matchBracket stays when no matching bracket', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'unmatched(\n';
      expect(MotionActions.matchBracket(e, f, 9), 9); // stays at (
    });

    test('matchBracket with mixed bracket types', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo([{bar}])\n';
      // Offsets: f=0, o=1, o=2, (=3, [=4, {=5, b=6, a=7, r=8, }=9, ]=10, )=11
      expect(MotionActions.matchBracket(e, f, 3), 11); // ( -> )
      expect(MotionActions.matchBracket(e, f, 4), 10); // [ -> ]
      expect(MotionActions.matchBracket(e, f, 5), 9); // { -> }
    });

    test('matchBracket via keybinding', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(bar)\n';
      f.cursor = 3; // at (
      e.input('%');
      expect(f.cursor, 7); // now at )
      e.input('%');
      expect(f.cursor, 3); // back to (
    });

    test('matchBracket multiline', () {
      final e = Editor(
        terminal: TestTerminal(width: 80, height: 24),
        redraw: false,
      );
      final f = e.file;
      f.text = 'foo(\n  bar\n)\n';
      // Offsets: f=0, o=1, o=2, (=3, \n=4, space=5,6, b=7, a=8, r=9, \n=10, )=11
      expect(MotionActions.matchBracket(e, f, 3), 11); // ( -> )
      expect(MotionActions.matchBracket(e, f, 11), 3); // ) -> (
    });
  });
}
