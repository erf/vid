import '../../editor.dart';
import '../../file_buffer/file_buffer.dart';
import '../../message.dart';
import '../../popup/popup.dart';
import 'lsp_feature.dart';
import 'lsp_protocol.dart';

/// Reference location value for popup items.
class ReferenceLocation {
  final String filePath;
  final int line;
  final int character;

  const ReferenceLocation({
    required this.filePath,
    required this.line,
    required this.character,
  });
}

/// LSP references popup for viewing and navigating to symbol usages.
class ReferencesPopup {
  /// Show references popup for symbol at cursor.
  static Future<void> show(Editor editor, FileBuffer file) async {
    final lsp = editor.featureRegistry?.get<LspFeature>();
    if (lsp == null || !lsp.isConnected) {
      editor.showMessage(Message.error('LSP not connected'));
      return;
    }

    if (file.absolutePath == null) {
      editor.showMessage(Message.error('File not saved'));
      return;
    }

    editor.showMessage(Message.info('Finding references...'));
    editor.draw();

    final locations = await lsp.findReferences(editor, file);

    if (locations.isEmpty) {
      // Message already shown by findReferences
      return;
    }

    // If only one reference, jump directly
    if (locations.length == 1) {
      _jumpToLocation(editor, locations.first);
      return;
    }

    final items = await _buildItems(editor, locations);

    editor.showPopup(
      PopupState.create(
        title: 'References (${locations.length})',
        items: items,
        onSelect: (item) => _onSelect(editor, item),
        onCancel: () => editor.closePopup(),
      ),
    );
  }

  /// Build popup items from locations.
  static Future<List<PopupItem<ReferenceLocation>>> _buildItems(
    Editor editor,
    List<LspLocation> locations,
  ) async {
    final items = <PopupItem<ReferenceLocation>>[];

    for (final loc in locations) {
      final filePath = loc.filePath;
      final lineNum = loc.line + 1; // Convert to 1-based for display

      // Try to get line preview from buffer
      String? preview;
      final buffer = _findBuffer(editor, filePath);
      if (buffer != null && loc.line < buffer.totalLines) {
        preview = _getLinePreview(buffer, loc.line);
      }

      final shortPath = _shortenPath(filePath);
      final label = preview != null
          ? '$shortPath:$lineNum  $preview'
          : '$shortPath:$lineNum';

      items.add(
        PopupItem<ReferenceLocation>(
          label: label,
          detail: filePath != shortPath ? filePath : null,
          value: ReferenceLocation(
            filePath: filePath,
            line: loc.line,
            character: loc.character,
          ),
        ),
      );
    }

    // Sort by file path, then by line number
    items.sort((a, b) {
      final pathCompare = a.value.filePath.compareTo(b.value.filePath);
      if (pathCompare != 0) return pathCompare;
      return a.value.line.compareTo(b.value.line);
    });

    return items;
  }

  /// Find buffer by file path.
  static FileBuffer? _findBuffer(Editor editor, String filePath) {
    for (final buffer in editor.buffers) {
      if (buffer.absolutePath == filePath) {
        return buffer;
      }
    }
    return null;
  }

  /// Get a preview of the line content.
  static String _getLinePreview(FileBuffer buffer, int line) {
    final lineStart = buffer.lineOffset(line);
    final lineEnd = buffer.lineEnd(lineStart);
    var text = buffer.text.substring(lineStart, lineEnd);

    // Trim whitespace and truncate
    text = text.trim();
    if (text.length > 50) {
      text = '${text.substring(0, 47)}...';
    }
    return text;
  }

  /// Handle reference selection.
  static void _onSelect(Editor editor, PopupItem<ReferenceLocation> item) {
    editor.closePopup();
    _jumpToLocation(
      editor,
      LspLocation(
        uri: 'file://${item.value.filePath}',
        line: item.value.line,
        character: item.value.character,
      ),
    );
  }

  /// Jump to a location, switching files if needed.
  static void _jumpToLocation(Editor editor, LspLocation loc) {
    final targetPath = loc.filePath;

    // Save current position to jump list before jumping
    editor.pushJumpLocation();

    // Switch to file if needed
    if (editor.file.absolutePath != targetPath) {
      final result = editor.loadFile(targetPath);
      if (result.hasError) {
        editor.showMessage(Message.error(result.error!));
        return;
      }
    }

    // Jump to line and character
    final file = editor.file;
    if (loc.line < file.totalLines) {
      final lineStart = file.lineOffset(loc.line);
      file.cursor = lineStart + loc.character;
      file.clampCursor();
      file.centerViewport(editor.terminal);
      editor.draw();
    }
  }

  /// Shorten path for display.
  static String _shortenPath(String path) {
    final parts = path.split('/');
    if (parts.length <= 2) return path;
    // Show last 2 components for context
    return parts.sublist(parts.length - 2).join('/');
  }
}
