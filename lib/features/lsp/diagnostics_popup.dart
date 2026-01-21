import '../../editor.dart';
import '../../file_buffer/file_buffer.dart';
import '../../message.dart';
import '../../popup/popup.dart';
import 'lsp_feature.dart';
import 'lsp_protocol.dart';

/// Diagnostic item value containing location info.
class _DiagnosticLocation {
  final String? filePath;
  final int line;
  final int character;

  const _DiagnosticLocation({
    this.filePath,
    required this.line,
    required this.character,
  });
}

/// LSP diagnostics popup for viewing and navigating to errors/warnings.
class DiagnosticsPopup {
  /// Show diagnostics popup for current file.
  static void show(Editor editor) {
    final lsp = editor.featureRegistry?.get<LspFeature>();
    if (lsp == null || !lsp.isConnected) {
      editor.showMessage(Message.error('LSP not connected'));
      return;
    }

    final file = editor.file;
    if (file.absolutePath == null) {
      editor.showMessage(Message.error('File not saved'));
      return;
    }

    final uri = 'file://${file.absolutePath}';
    final diagnostics = lsp.getDiagnostics(uri);

    if (diagnostics.isEmpty) {
      editor.showMessage(Message.info('No diagnostics'));
      return;
    }

    final items = _buildItems(diagnostics, file.absolutePath);

    editor.showPopup(
      PopupState.create(
        title: 'Diagnostics',
        items: items,
        onSelect: (item) => _onSelect(editor, item),
        onCancel: () => editor.closePopup(),
      ),
    );
  }

  /// Show diagnostics popup for all open files.
  static void showAll(Editor editor) {
    final lsp = editor.featureRegistry?.get<LspFeature>();
    if (lsp == null || !lsp.isConnected) {
      editor.showMessage(Message.error('LSP not connected'));
      return;
    }

    final items = <PopupItem<_DiagnosticLocation>>[];

    // Gather diagnostics from all open buffers
    for (final buffer in editor.buffers) {
      if (buffer.absolutePath == null) continue;

      final uri = 'file://${buffer.absolutePath}';
      final diagnostics = lsp.getDiagnostics(uri);

      if (diagnostics.isNotEmpty) {
        items.addAll(_buildItems(diagnostics, buffer.absolutePath));
      }
    }

    if (items.isEmpty) {
      editor.showMessage(Message.info('No diagnostics'));
      return;
    }

    // Sort by file, then by line
    items.sort((a, b) {
      final aFile = a.value.filePath ?? '';
      final bFile = b.value.filePath ?? '';
      if (aFile != bFile) return aFile.compareTo(bFile);
      return a.value.line.compareTo(b.value.line);
    });

    editor.showPopup(
      PopupState.create(
        title: 'All Diagnostics',
        items: items,
        onSelect: (item) => _onSelect(editor, item),
        onCancel: () => editor.closePopup(),
      ),
    );
  }

  /// Build popup items from diagnostics.
  static List<PopupItem<_DiagnosticLocation>> _buildItems(
    List<LspDiagnostic> diagnostics,
    String? filePath,
  ) {
    return diagnostics.map((diag) {
      final prefix = switch (diag.severity) {
        DiagnosticSeverity.error => 'E',
        DiagnosticSeverity.warning => 'W',
        DiagnosticSeverity.information => 'I',
        DiagnosticSeverity.hint => 'H',
      };

      // Truncate message if too long
      var message = diag.message;
      if (message.length > 60) {
        message = '${message.substring(0, 57)}...';
      }

      // Remove newlines from message
      message = message.replaceAll('\n', ' ');

      final label = '[$prefix] L${diag.startLine + 1}: $message';

      return PopupItem<_DiagnosticLocation>(
        label: label,
        detail: filePath != null ? _shortenPath(filePath) : null,
        value: _DiagnosticLocation(
          filePath: filePath,
          line: diag.startLine,
          character: diag.startChar,
        ),
      );
    }).toList();
  }

  /// Handle diagnostic selection.
  static void _onSelect(Editor editor, PopupItem<_DiagnosticLocation> item) {
    editor.closePopup();

    final loc = item.value;

    // Switch to file if needed
    if (loc.filePath != null && editor.file.absolutePath != loc.filePath) {
      final result = editor.loadFile(loc.filePath!);
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
    return parts.last;
  }
}
