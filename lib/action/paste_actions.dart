import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../operator/operator_actions.dart';
import '../yank_buffer.dart';
import 'action_base.dart';

/// Paste after cursor.
/// Helper to paste at multiple cursors with proper position tracking.
void _pasteAtCursors(
  Editor e,
  FileBuffer f,
  YankBuffer yank,
  int Function(int cursor) getInsertPos,
  bool cursorAtEnd,
) {
  final n = f.selections.length;
  // Build one edit per cursor, tagged with the original index for piece mapping.
  final items = <CursorEdit>[];
  for (int i = 0; i < n; i++) {
    final pos = getInsertPos(f.selections[i].cursor);
    final text = yank.textForCursor(i, n);
    final edit = TextEdit.insert(pos, text);
    items.add(
      cursorAtEnd ? CursorEdit.atEnd(edit, -1) : CursorEdit.atStart(edit),
    );
  }

  f.selections = applyEditsWithCursors(f, e.config, items);
  f.clampCursor();
}

/// Where to paste relative to the cursor.
enum PasteWhere { after, before }

/// Paste from yank buffer relative to each cursor.
class Paste extends Action {
  final PasteWhere where;
  const Paste(this.where);

  @override
  void call(Editor e, FileBuffer f) {
    if (e.yankBuffer == null) return;
    final yank = e.yankBuffer!;

    switch (where) {
      case .after:
        if (yank.linewise) {
          _pasteAtCursors(e, f, yank, (c) {
            final pos = f.lineEnd(c) + 1;
            return pos > f.text.length ? f.text.length : pos;
          }, false);
        } else {
          _pasteAtCursors(e, f, yank, (c) {
            final line = f.lineText(c);
            return (line.isEmpty || line == ' ')
                ? f.lineStart(c)
                : f.nextGrapheme(c);
          }, true);
        }
      case .before:
        if (yank.linewise) {
          _pasteAtCursors(e, f, yank, (c) => f.lineStart(c), false);
        } else {
          _pasteAtCursors(e, f, yank, (c) => c, false);
        }
    }
  }
}

/// Paste in visual mode - replace selection(s) with yank buffer content.
/// The replaced text is yanked (Vim default behavior).
class VisualPaste extends Action {
  const VisualPaste();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.yankBuffer == null) return;

    final isVisualLineMode = f.mode == .visualLine;
    final isVisualMode = f.mode == .visual;

    // In visual line mode, even collapsed selections represent full line selection.
    // In visual mode, we need actual non-collapsed selections.
    if (!isVisualLineMode && !isVisualMode) {
      const Paste(.after).call(e, f);
      return;
    }

    // In visual mode (not visual line), if selection is collapsed, fall back
    if (isVisualMode && !f.hasVisualSelection) {
      const Paste(.after).call(e, f);
      return;
    }

    // Get ranges to replace - use same logic as operator actions
    final ranges = OperatorActions.getVisualRanges(f, isVisualLineMode);
    if (ranges.isEmpty) return;

    final yank = e.yankBuffer!;
    final numSelections = ranges.length;

    // Get paste text for each selection
    // If yank has same number of pieces as selections, distribute them
    final pasteTexts = <String>[];
    for (int i = 0; i < numSelections; i++) {
      pasteTexts.add(yank.textForCursor(i, numSelections));
    }

    // Yank the selected text before replacing (Vim default behavior)
    final selectedPieces = ranges
        .map((s) => f.text.substring(s.start, s.end))
        .toList();
    e.yankBuffer = YankBuffer(selectedPieces, linewise: isVisualLineMode);

    // Build edits: replace each selection with its corresponding paste content,
    // cursor lands at start of pasted text.
    final items = <CursorEdit>[];
    for (int i = 0; i < ranges.length; i++) {
      items.add(
        CursorEdit.atStart(
          TextEdit(ranges[i].start, ranges[i].end, pasteTexts[i]),
        ),
      );
    }
    f.selections = applyEditsWithCursors(f, e.config, items);
    f.clampCursor();

    f.setMode(e, .normal);
  }
}
