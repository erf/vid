import '../../editor.dart';
import '../../file_buffer/file_buffer.dart';
import '../../message.dart';
import '../../popup/popup.dart';
import 'lsp_protocol.dart';

/// Symbol location value for popup items.
class SymbolLocation {
  final int line;
  final int character;

  const SymbolLocation({required this.line, required this.character});
}

/// LSP document symbols popup for viewing and navigating to symbols.
class SymbolsPopup {
  /// Show document symbols popup.
  static Future<void> show(Editor editor, FileBuffer file) async {
    final lsp = editor.lsp;
    if (lsp == null || !lsp.isConnected) {
      editor.showMessage(Message.error('LSP not connected'));
      return;
    }

    if (file.absolutePath == null) {
      editor.showMessage(Message.error('File not saved'));
      return;
    }

    editor.showMessage(Message.info('Loading symbols...'));
    editor.draw();

    final symbols = await lsp.getDocumentSymbols(editor, file);

    if (symbols.isEmpty) {
      // Message already shown by getDocumentSymbols
      return;
    }

    final items = _buildItems(symbols);

    editor.showPopup(
      PopupState.create(
        title: 'Symbols (${items.length})',
        items: items,
        onSelect: (item) => _onSelect(editor, file, item),
        onCancel: () => editor.closePopup(),
      ),
    );
  }

  /// Build popup items from symbols (flattening hierarchy).
  static List<PopupItem<SymbolLocation>> _buildItems(
    List<LspDocumentSymbol> symbols, {
    int indent = 0,
  }) {
    final items = <PopupItem<SymbolLocation>>[];

    for (final symbol in symbols) {
      final lineNum = symbol.selectionRange.startLine + 1; // 1-based display
      final indentStr = '  ' * indent;
      final detail = symbol.detail;

      // Format: "icon name : line" with optional detail
      final label = '$indentStr${symbol.kind.icon} ${symbol.name}';

      items.add(
        PopupItem<SymbolLocation>(
          label: label,
          detail: detail != null ? '$detail  L$lineNum' : 'L$lineNum',
          value: SymbolLocation(
            line: symbol.selectionRange.startLine,
            character: symbol.selectionRange.startChar,
          ),
        ),
      );

      // Add children with increased indent
      if (symbol.children.isNotEmpty) {
        items.addAll(_buildItems(symbol.children, indent: indent + 1));
      }
    }

    return items;
  }

  /// Handle symbol selection.
  static void _onSelect(
    Editor editor,
    FileBuffer file,
    PopupItem<SymbolLocation> item,
  ) {
    editor.closePopup();
    _jumpToSymbol(editor, file, item.value);
  }

  /// Jump to a symbol location.
  static void _jumpToSymbol(
    Editor editor,
    FileBuffer file,
    SymbolLocation loc,
  ) {
    // Calculate byte offset from line and character
    final lineStart = file.lineOffset(loc.line);
    final lineEnd = file.lineEnd(lineStart);
    final lineText = file.text.substring(lineStart, lineEnd);

    // Convert character offset to byte offset within the line
    int byteOffset = 0;
    int charCount = 0;
    final codeUnits = lineText.codeUnits;
    for (int i = 0; i < codeUnits.length && charCount < loc.character; i++) {
      byteOffset++;
      // Count UTF-16 code units (what LSP uses as "character")
      charCount++;
    }

    final targetOffset = lineStart + byteOffset;
    file.cursor = targetOffset.clamp(0, file.text.length - 1);

    // Center the view on the symbol
    file.centerViewport(editor.terminal);
  }
}
