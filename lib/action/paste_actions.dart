import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../operator/operator_actions.dart';
import '../selection.dart';
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
  // Sort by position, keep original indices for piece mapping
  final sorted = List.generate(n, (i) => i)
    ..sort((a, b) => f.selections[a].cursor.compareTo(f.selections[b].cursor));

  // Build edits and track insert info (from end to preserve positions)
  final edits = <TextEdit>[];
  final insertInfo = <(int, String)>[]; // (pos, text) in sorted order
  for (int i = sorted.length - 1; i >= 0; i--) {
    final idx = sorted[i];
    final pos = getInsertPos(f.selections[idx].cursor);
    final text = yank.textForCursor(idx, n);
    edits.add(TextEdit(pos, pos, text));
    insertInfo.insert(0, (pos, text));
  }

  applyEdits(f, edits, e.config);

  // Update cursor positions
  var offset = 0;
  final newSels = <Selection>[];
  for (final (pos, text) in insertInfo) {
    final cur = pos + offset + (cursorAtEnd ? text.length - 1 : 0);
    newSels.add(Selection.collapsed(cur));
    offset += text.length;
  }
  f.selections = newSels;
  f.clampCursor();
}

/// Paste after cursor.
class PasteAfter extends Action {
  const PasteAfter();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.yankBuffer == null) return;
    final yank = e.yankBuffer!;

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
  }
}

/// Paste before cursor.
class PasteBefore extends Action {
  const PasteBefore();

  @override
  void call(Editor e, FileBuffer f) {
    if (e.yankBuffer == null) return;
    final yank = e.yankBuffer!;

    if (yank.linewise) {
      _pasteAtCursors(e, f, yank, (c) => f.lineStart(c), false);
    } else {
      _pasteAtCursors(e, f, yank, (c) => c, false);
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
      const PasteAfter().call(e, f);
      return;
    }

    // In visual mode (not visual line), if selection is collapsed, fall back
    if (isVisualMode && !f.hasVisualSelection) {
      const PasteAfter().call(e, f);
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

    // Build edits: replace each selection with its corresponding paste content
    final edits = <TextEdit>[];
    for (int i = ranges.length - 1; i >= 0; i--) {
      edits.add(TextEdit(ranges[i].start, ranges[i].end, pasteTexts[i]));
    }
    applyEdits(f, edits, e.config);

    // Collapse selections to start of pasted content
    var offset = 0;
    final newSelections = <Selection>[];
    for (int i = 0; i < ranges.length; i++) {
      final range = ranges[i];
      final newCursor = range.start + offset;
      newSelections.add(Selection.collapsed(newCursor));
      // Adjust offset: old range removed, paste text added
      offset += pasteTexts[i].length - (range.end - range.start);
    }
    f.selections = newSelections;
    f.clampCursor();

    f.setMode(e, .normal);
  }
}
