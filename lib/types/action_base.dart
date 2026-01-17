import 'dart:math';

import 'package:characters/characters.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../selection.dart';
import '../string_ext.dart';
import '../utils.dart';

/// Base class for general editor actions (normal mode, insert mode, etc.)
///
/// Actions are operations that modify editor state.
/// They take Editor and FileBuffer parameters.
///
/// Note: This is distinct from [MotionAction], [OperatorAction], and
/// [TextObjectAction] which have different call signatures.
///
/// All actions should be const-constructible to avoid runtime allocation.
///
/// Example usage:
///   const MyAction()(editor, fileBuffer);
abstract class Action {
  /// Const constructor for subclasses.
  const Action();

  /// Execute the action.
  void call(Editor e, FileBuffer f);

  // ===== Utility methods for action implementations =====

  /// Move the selection with cursor at [cursorPos] to front of list.
  void moveToFront(List<Selection> selections, int cursorPos) {
    for (int i = 0; i < selections.length; i++) {
      if (selections[i].cursor == cursorPos) {
        final sel = selections.removeAt(i);
        selections.insert(0, sel);
        return;
      }
    }
  }

  /// Get visual column of offset.
  static int visualColumn(FileBuffer f, int offset, int tabWidth) {
    final lineStart = f.lineStart(offset);
    final beforeCursor = f.text.substring(lineStart, offset);
    return beforeCursor.renderLength(tabWidth);
  }

  /// Get byte offset at target visual column on a line.
  int offsetAtVisualColumn(
    FileBuffer f,
    int targetLine,
    int targetVisualCol,
    int tabWidth,
  ) {
    final targetLineStart = f.lines[targetLine].start;
    final targetLineEnd = f.lines[targetLine].end;
    final targetLineText = f.text.substring(targetLineStart, targetLineEnd);

    // Find position in target line with similar visual column
    int nextLen = 0;
    final chars = targetLineText.characters.takeWhile((c) {
      nextLen += c.charWidth(tabWidth);
      return nextLen <= targetVisualCol;
    });

    // Clamp to valid position in target line
    final targetCharLen = targetLineText.characters.length;
    final charIndex = clamp(chars.length, 0, max(0, targetCharLen - 1));

    // Convert char index to byte offset
    return targetLineStart +
        targetLineText.characters.take(charIndex).string.length;
  }
}
