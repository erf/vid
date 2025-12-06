import 'dart:math';

import '../config.dart';
import '../editor.dart';
import '../error_or.dart';
import '../file_buffer/file_buffer.dart';
import '../regex.dart';
import '../text_op.dart';

class Normal {
  static void moveDownHalfPage(Editor e, FileBuffer f) {
    int targetLine = f.cursorLine + e.terminal.height ~/ 2;
    targetLine = min(targetLine, f.totalLines - 1);
    f.cursor = f.offsetOfLine(targetLine);
  }

  static void moveUpHalfPage(Editor e, FileBuffer f) {
    int targetLine = f.cursorLine - e.terminal.height ~/ 2;
    targetLine = max(targetLine, 0);
    f.cursor = f.offsetOfLine(targetLine);
  }

  static void pasteAfter(Editor e, FileBuffer f) {
    if (f.yankBuffer == null) return;
    final YankBuffer yank = f.yankBuffer!;

    if (yank.linewise) {
      // Paste after current line - insert after the newline at end of line
      int lineEndOffset = f.lineEnd(f.cursor);
      // Insert after the newline (at start of next line position)
      int insertPos = lineEndOffset + 1;
      if (insertPos > f.text.length) insertPos = f.text.length;
      f.insertAt(insertPos, yank.text, config: e.config);
      // Move cursor to start of pasted content
      f.cursor = insertPos;
      f.clampCursor();
    } else {
      // Check if line is empty (only has trailing space/newline)
      String lineText = f.lineText(f.cursor);
      if (lineText.isEmpty || lineText == ' ') {
        f.insertAt(f.lineStart(f.cursor), yank.text, config: e.config);
      } else {
        // Paste after cursor
        int insertPos = f.nextGrapheme(f.cursor);
        f.insertAt(insertPos, yank.text, config: e.config);
        // Move cursor to end of pasted content (last char, not past it)
        f.cursor = insertPos + yank.text.length - 1;
        f.clampCursor();
      }
    }
  }

  static void pasteBefore(Editor e, FileBuffer f) {
    if (f.yankBuffer == null) return;
    final YankBuffer yank = f.yankBuffer!;
    if (yank.linewise) {
      // Paste before current line
      int lineStartOffset = f.lineStart(f.cursor);
      f.insertAt(lineStartOffset, yank.text, config: e.config);
      f.cursor = lineStartOffset;
    } else {
      // Paste at cursor position
      f.insertAt(f.cursor, yank.text, config: e.config);
    }
  }

  static void quit(Editor e, FileBuffer f) {
    if (f.modified) {
      e.showMessage(.error('File has unsaved changes'));
    } else {
      e.quit();
    }
  }

  static void quitWithoutSaving(Editor e, FileBuffer f) {
    e.quit();
  }

  static void save(Editor e, FileBuffer f) {
    ErrorOr result = f.save(e, f.path);
    if (result.hasError) {
      e.showMessage(.error(result.error!));
    } else {
      e.showMessage(.info('File saved'));
    }
  }

  static void appendCharNext(Editor e, FileBuffer f) {
    f.setMode(e, .insert);
    // Move cursor right by one grapheme, but don't go past line end
    int nextPos = f.nextGrapheme(f.cursor);
    int lineEndPos = f.lines[f.cursorLine].end;
    f.cursor = min(nextPos, lineEndPos);
  }

  static void joinLines(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      int lineEndOffset = f.lineEnd(f.cursor);
      // Check if there's a line below to join
      if (lineEndOffset >= f.text.length - 1) {
        return;
      }
      // Delete the newline at end of current line
      f.deleteAt(lineEndOffset, config: e.config);
    }
  }

  static void undo(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      TextOp? op = f.undo();
      if (op != null) {
        f.cursor = op.cursor;
        f.clampCursor();
      }
    }
    f.edit = EditOperation();
  }

  static void redo(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      TextOp? op = f.redo();
      if (op != null) {
        f.cursor = op.cursor;
        f.clampCursor();
      }
    }
    f.edit = EditOperation();
  }

  static void repeat(Editor e, FileBuffer f) {
    if (f.prevEdit == null || !f.prevEdit!.canRepeatWithDot) {
      return;
    }
    f.edit = f.prevEdit!;
    e.commitEdit(f.edit);
  }

  static void repeatFindStr(Editor e, FileBuffer f) {
    if (f.prevEdit == null || !f.prevEdit!.canRepeatFind) {
      return;
    }
    f.edit = f.prevEdit!;
    e.commitEdit(f.edit);
  }

  static void increaseNextWord(Editor e, FileBuffer f, int count) {
    int lineNum = f.cursorLine;
    int lineStartOffset = f.lines[lineNum].start;
    String lineText = f.lineTextAt(lineNum);
    int cursorInLine = f.cursor - lineStartOffset;

    final matches = Regex.number.allMatches(lineText);
    if (matches.isEmpty) return;

    final m = matches.firstWhere(
      (m) => cursorInLine < m.end,
      orElse: () => matches.last,
    );
    if (cursorInLine >= m.end) return;

    final s = m.group(1)!;
    final num = int.parse(s);
    final numstr = (num + count).toString();

    int matchStart = lineStartOffset + m.start;
    int matchEnd = lineStartOffset + m.end;
    f.replace(matchStart, matchEnd, numstr, config: e.config);
    f.cursor = matchStart + numstr.length - 1;
  }

  static void increase(Editor e, FileBuffer f) {
    increaseNextWord(e, f, 1);
  }

  static void decrease(Editor e, FileBuffer f) {
    increaseNextWord(e, f, -1);
  }

  static void toggleWrap(Editor e, FileBuffer f) {
    // Cycle through: none -> char -> word -> none
    WrapMode next = switch (e.config.wrapMode) {
      .none => .char,
      .char => .word,
      .word => .none,
    };
    e.setWrapMode(next);

    String label = switch (next) {
      .none => 'off',
      .char => 'char',
      .word => 'word',
    };
    e.showMessage(.info('Wrap: $label'));
  }

  static void centerView(Editor e, FileBuffer f) {
    f.centerViewport(e.terminal);
  }
}
