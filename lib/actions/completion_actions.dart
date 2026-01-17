import 'dart:async';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../features/lsp/lsp_feature.dart';
import '../popup/popup.dart';
import '../types/action_base.dart';

/// Show word completion popup using LSP.
class ShowCompletion extends Action {
  const ShowCompletion();

  @override
  void call(Editor e, FileBuffer f) {
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null || !lsp.isConnected || f.absolutePath == null) {
      e.showMessage(.info('LSP not connected'));
      return;
    }

    // Capture word boundaries upfront before async operations
    final wordStart = getWordStart(f);
    final wordEnd = f.cursor;

    showLspCompletion(e, f, wordStart, wordEnd, lsp);
  }

  /// Get the start offset of the word being completed.
  int getWordStart(FileBuffer f) {
    if (f.cursor == 0) return 0;

    int start = f.cursor;
    while (start > 0) {
      final prevChar = f.text[start - 1];
      if (!RegExp(r'[\w\u00C0-\u024F]').hasMatch(prevChar)) break;
      start--;
    }

    return start;
  }

  /// Show LSP-based completion.
  void showLspCompletion(
    Editor e,
    FileBuffer f,
    int wordStart,
    int wordEnd,
    LspFeature lsp,
  ) async {
    final uri = 'file://${f.absolutePath}';
    final line = f.lineNumber(f.cursor);
    final lineStart = f.lineStart(f.cursor);
    final char = f.cursor - lineStart;

    try {
      final items = await lsp.protocol?.completion(uri, line, char);

      // Check we're still in insert mode after async call
      if (f.mode != .insert) return;

      if (items == null || items.isEmpty) {
        e.showMessage(.info('No completions'));
        e.draw();
        return;
      }

      // Convert LSP items to popup items
      final popupItems = items.map((item) {
        return PopupItem<String>(
          label: item.label,
          detail: item.detail,
          value: item.insertText ?? item.label,
        );
      }).toList();

      showCompletionPopup(e, f, wordStart, wordEnd, popupItems);
    } on TimeoutException {
      if (f.mode != .insert) return;
      e.showMessage(.info('Completion timed out'));
      e.draw();
    } catch (err) {
      if (f.mode != .insert) return;
      e.showMessage(.error('$err'));
      e.draw();
    }
  }

  /// Show the completion popup.
  void showCompletionPopup(
    Editor e,
    FileBuffer f,
    int wordStart,
    int wordEnd,
    List<PopupItem<String>> items,
  ) {
    final popup = PopupState<String>.create(
      title: 'Complete',
      items: items,
      showFilter: false,
      onSelect: (item) {
        f.replace(wordStart, wordEnd, item.value, config: e.config);
        f.cursor = wordStart + item.value.length;
        e.closePopup();
        f.setMode(e, .insert);
      },
      onCancel: () {
        e.closePopup();
        f.setMode(e, .insert);
      },
    );

    e.showPopup(popup);
  }
}
