import 'config.dart';
import 'file_buffer/file_buffer.dart';
import 'selection.dart';

/// An input event produced by [BracketedPasteHandler.feed].
sealed class PasteInputEvent {}

/// Input that should be processed through the normal event flow.
final class PasteNormalInput extends PasteInputEvent {
  final String text;
  PasteNormalInput(this.text);
}

/// A completed bracketed paste; [content] should be inserted as a single
/// bulk operation (one undo entry).
final class PasteContent extends PasteInputEvent {
  final String content;
  PasteContent(this.content);
}

/// Handles bracketed paste sequences (`ESC[200~` … `ESC[201~`).
///
/// Feed raw input via [feed]; it returns the events found in that chunk, in
/// order. Paste content is buffered across calls until the end marker
/// arrives, then emitted as a single [PasteContent] event. Any input before
/// or after paste markers is emitted as [PasteNormalInput].
class BracketedPasteHandler {
  static const _pasteStart = '\x1b[200~';
  static const _pasteEnd = '\x1b[201~';

  /// Whether we're currently receiving bracketed paste input.
  bool _inPaste = false;

  /// Buffer for accumulating bracketed paste content.
  final StringBuffer _buffer = StringBuffer();

  /// Feed a chunk of raw input and return the events it contains.
  List<PasteInputEvent> feed(String str) {
    final events = <PasteInputEvent>[];
    var rest = str;

    while (rest.isNotEmpty) {
      if (_inPaste) {
        final endIdx = rest.indexOf(_pasteEnd);
        if (endIdx == -1) {
          // No end marker yet, buffer everything.
          _buffer.write(rest);
          break;
        }
        // Found end marker - complete the paste.
        _buffer.write(rest.substring(0, endIdx));
        _finish(events);
        rest = rest.substring(endIdx + _pasteEnd.length);
      } else {
        final startIdx = rest.indexOf(_pasteStart);
        if (startIdx == -1) {
          // No paste sequence, pass through as-is.
          events.add(PasteNormalInput(rest));
          break;
        }
        // Emit any input before the paste marker as normal input.
        if (startIdx > 0) {
          events.add(PasteNormalInput(rest.substring(0, startIdx)));
        }
        _inPaste = true;
        _buffer.clear();
        rest = rest.substring(startIdx + _pasteStart.length);
      }
    }

    return events;
  }

  /// Complete the paste by emitting the buffered content (if any).
  void _finish(List<PasteInputEvent> events) {
    _inPaste = false;
    final content = _buffer.toString();
    _buffer.clear();
    if (content.isNotEmpty) {
      events.add(PasteContent(content));
    }
  }

  /// Insert paste [content] at all cursor positions as a single undo
  /// operation, bypassing insert mode's per-character processing.
  static void insertContent(FileBuffer f, String content, Config config) {
    if (content.isEmpty) return;

    // Sort selections by position (ascending).
    final sorted = f.selections.sortedByCursor();

    // Build edits for all cursor positions and apply them as a single
    // grouped undo operation.
    final edits = sorted
        .map((sel) => TextEdit.insert(sel.cursor, content))
        .toList();
    applyEdits(f, edits, config);

    // Update cursor positions to after the inserted content.
    final newSelections = <Selection>[];
    int offset = 0;
    for (final sel in sorted) {
      newSelections.add(
        Selection.collapsed(sel.cursor + offset + content.length),
      );
      offset += content.length;
    }
    f.selections = newSelections;
  }
}
