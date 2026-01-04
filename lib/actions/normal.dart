import 'dart:math';

import 'package:termio/termio.dart';
import 'package:vid/yank_buffer.dart';

import '../config.dart';
import '../editor.dart';
import '../error_or.dart';
import '../file_buffer/file_buffer.dart';
import 'insert_actions.dart';
import '../popup/buffer_selector.dart';
import '../popup/diagnostics_popup.dart';
import '../popup/file_browser.dart';
import '../popup/theme_selector.dart';
import '../regex.dart';
import '../text_op.dart';

class Normal {
  static void moveDownHalfPage(Editor e, FileBuffer f) {
    int targetLine = f.lineNumber(f.cursor) + e.terminal.height ~/ 2;
    targetLine = min(targetLine, f.totalLines - 1);
    f.cursor = f.lineOffset(targetLine);
  }

  static void moveUpHalfPage(Editor e, FileBuffer f) {
    int targetLine = f.lineNumber(f.cursor) - e.terminal.height ~/ 2;
    targetLine = max(targetLine, 0);
    f.cursor = f.lineOffset(targetLine);
  }

  static void pasteAfter(Editor e, FileBuffer f) {
    if (e.yankBuffer == null) return;
    final YankBuffer yank = e.yankBuffer!;

    if (yank.linewise) {
      // Paste after current line - insert after the newline at end of line
      int lineEndOffset = f.lineEnd(f.cursor);
      // Insert after the newline (at start of next line position)
      int insertPos = lineEndOffset + 1;
      if (insertPos > f.text.length) insertPos = f.text.length;
      f.insertAt(insertPos, yank.text, config: e.config, editor: e);
      // Move cursor to start of pasted content
      f.cursor = insertPos;
      f.clampCursor();
    } else {
      // Check if line is empty (only has trailing space/newline)
      String lineText = f.lineText(f.cursor);
      if (lineText.isEmpty || lineText == ' ') {
        f.insertAt(
          f.lineStart(f.cursor),
          yank.text,
          config: e.config,
          editor: e,
        );
      } else {
        // Paste after cursor
        int insertPos = f.nextGrapheme(f.cursor);
        f.insertAt(insertPos, yank.text, config: e.config, editor: e);
        // Move cursor to end of pasted content (last char, not past it)
        f.cursor = insertPos + yank.text.length - 1;
        f.clampCursor();
      }
    }
  }

  static void pasteBefore(Editor e, FileBuffer f) {
    if (e.yankBuffer == null) return;
    final YankBuffer yank = e.yankBuffer!;
    if (yank.linewise) {
      // Paste before current line
      int lineStartOffset = f.lineStart(f.cursor);
      f.insertAt(lineStartOffset, yank.text, config: e.config, editor: e);
      f.cursor = lineStartOffset;
    } else {
      // Paste at cursor position
      f.insertAt(f.cursor, yank.text, config: e.config, editor: e);
    }
  }

  static void quit(Editor e, FileBuffer f) {
    final unsavedCount = e.unsavedBufferCount;
    if (unsavedCount > 0) {
      e.showMessage(.error('$unsavedCount buffer(s) have unsaved changes'));
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
    int lineEndPos = f.lines[f.lineNumber(f.cursor)].end;
    f.cursor = min(nextPos, lineEndPos);
  }

  static void openLineAbove(Editor e, FileBuffer f) {
    String indent = '';
    if (e.config.autoIndent) {
      indent = InsertActions.getIndent(f, f.cursor, fullLine: true);
    }

    int lineStart = f.lineStart(f.cursor);
    f.insertAt(lineStart, indent + Keys.newline, config: e.config, editor: e);
    f.cursor = lineStart + indent.length;
    f.setMode(e, .insert);
  }

  static void openLineBelow(Editor e, FileBuffer f) {
    String indent = '';
    if (e.config.autoIndent) {
      indent = InsertActions.getSmartIndent(e, f, f.cursor, fullLine: true);
    }

    int lineEnd = f.lineEnd(f.cursor);
    f.insertAt(lineEnd, Keys.newline + indent, config: e.config, editor: e);
    f.cursor = lineEnd + 1 + indent.length;
    f.setMode(e, .insert);
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
      TextOp? op = f.undo(editor: e);
      if (op != null) {
        f.cursor = op.cursor;
        f.clampCursor();
      }
    }
    f.edit.reset();
  }

  static void redo(Editor e, FileBuffer f) {
    for (int i = 0; i < (f.edit.count ?? 1); i++) {
      TextOp? op = f.redo(editor: e);
      if (op != null) {
        f.cursor = op.cursor;
        f.clampCursor();
      }
    }
    f.edit.reset();
  }

  static void repeat(Editor e, FileBuffer f) {
    if (f.prevEdit == null || !f.prevEdit!.canRepeatWithDot) {
      return;
    }
    e.commitEdit(f.prevEdit!);
  }

  static void repeatFindStr(Editor e, FileBuffer f) {
    if (f.prevEdit == null || !f.prevEdit!.canRepeatFind) {
      return;
    }
    e.commitEdit(f.prevEdit!);
  }

  static void increaseNextWord(Editor e, FileBuffer f, int count) {
    int lineNum = f.lineNumber(f.cursor);
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
    f.replace(matchStart, matchEnd, numstr, config: e.config, editor: e);
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

  static void toggleSyntax(Editor e, FileBuffer f) {
    e.toggleSyntax();
  }

  static void cycleTheme(Editor e, FileBuffer f) {
    e.cycleTheme();
  }

  static void openFilePicker(Editor e, FileBuffer f) {
    FileBrowser.show(e);
  }

  static void openBufferSelector(Editor e, FileBuffer f) {
    BufferSelector.show(e);
  }

  static void openThemeSelector(Editor e, FileBuffer f) {
    ThemeSelector.show(e);
  }

  static void openDiagnostics(Editor e, FileBuffer f) {
    DiagnosticsPopup.show(e);
  }
}
