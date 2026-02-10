import 'package:characters/characters.dart';

import '../../editor.dart';
import '../../file_buffer/file_buffer.dart';
import '../../message.dart';
import '../../popup/popup.dart';
import 'lsp_protocol.dart';

/// Code action popup for quick fixes and refactorings.
class CodeActionsPopup {
  /// Show code actions popup for cursor position.
  static Future<void> show(Editor editor, FileBuffer file) async {
    if (file.absolutePath == null) {
      editor.showMessage(Message.error('File not saved'));
      return;
    }

    final lsp = editor.lsp;
    if (lsp == null) {
      editor.showMessage(Message.error('LSP not available'));
      return;
    }

    final protocol = lsp.getProtocolForPath(file.absolutePath!);
    if (protocol == null) {
      editor.showMessage(Message.error('No LSP server for this file type'));
      return;
    }

    final uri = 'file://${file.absolutePath}';

    // Use selection range (supports visual mode selections for refactorings)
    final selection = file.selections.first;
    final startLine = file.lineNumber(selection.start);
    final startLineOffset = file.lineOffset(startLine);
    final startChar = selection.start - startLineOffset;

    final endLine = file.lineNumber(selection.end);
    final endLineOffset = file.lineOffset(endLine);
    final endChar = selection.end - endLineOffset;

    // Get diagnostics in range to include in request
    final allDiagnostics = lsp.getDiagnostics(uri);
    final rangeDiagnostics = allDiagnostics
        .where((d) => d.startLine >= startLine && d.startLine <= endLine)
        .toList();

    editor.showMessage(Message.info('Fetching code actions...'));

    try {
      final actions = await protocol.codeAction(
        uri,
        startLine,
        startChar,
        endLine,
        endChar,
        diagnostics: rangeDiagnostics.isNotEmpty ? rangeDiagnostics : null,
      );

      editor.clearMessage();

      if (actions == null || actions.isEmpty) {
        editor.showMessage(Message.info('No code actions available'));
        return;
      }

      // If only one action and it's preferred, apply directly
      if (actions.length == 1 && actions.first.isPreferred) {
        await _applyAction(editor, protocol, actions.first);
        return;
      }

      _showActionsPopup(editor, protocol, actions);
    } catch (e) {
      editor.showMessage(Message.error('LSP error: $e'));
    }
  }

  /// Show popup with available code actions.
  static void _showActionsPopup(
    Editor editor,
    LspProtocol protocol,
    List<LspCodeAction> actions,
  ) {
    // Sort: preferred first, then quickfixes, then refactors, then source
    actions.sort((a, b) {
      // Preferred actions first
      if (a.isPreferred != b.isPreferred) {
        return a.isPreferred ? -1 : 1;
      }
      // Then by kind
      final kindOrder = _kindOrder(a.kind) - _kindOrder(b.kind);
      if (kindOrder != 0) return kindOrder;
      // Finally alphabetically
      return a.title.compareTo(b.title);
    });

    final items = actions.map((action) {
      final icon = _kindIcon(action.kind);
      final label = '$icon ${action.title}';

      return PopupItem<LspCodeAction>(
        label: label,
        detail: action.kind,
        value: action,
      );
    }).toList();

    editor.showPopup(
      PopupState<LspCodeAction>.create(
        title: 'Code Actions',
        items: items,
        onSelect: (item) {
          editor.closePopup();
          _applyAction(editor, protocol, item.value);
        },
        onCancel: () => editor.closePopup(),
      ),
    );
  }

  /// Get sort order for action kind.
  static int _kindOrder(String? kind) {
    if (kind == null) return 99;
    if (kind.startsWith('quickfix')) return 0;
    if (kind.startsWith('refactor')) return 1;
    if (kind.startsWith('source')) return 2;
    return 99;
  }

  /// Get icon for action kind.
  static String _kindIcon(String? kind) {
    if (kind == null) return '*';
    if (kind.startsWith('quickfix')) return '*'; // fix
    if (kind.startsWith('refactor.extract')) return '>'; // extract
    if (kind.startsWith('refactor.inline')) return '<'; // inline
    if (kind.startsWith('refactor')) return '~'; // refactor
    if (kind.startsWith('source')) return '#'; // source
    return '*';
  }

  /// Apply a code action.
  static Future<void> _applyAction(
    Editor editor,
    LspProtocol protocol,
    LspCodeAction action,
  ) async {
    // If action has an edit, apply it
    if (action.edit != null && !action.edit!.isEmpty) {
      final result = await _applyWorkspaceEdit(editor, action.edit!);
      if (result.success) {
        final fileText = result.fileCount == 1 ? 'file' : 'files';
        editor.showMessage(
          Message.info(
            'Applied: ${action.title} (${result.editCount} edits in ${result.fileCount} $fileText)',
          ),
        );
      } else {
        editor.showMessage(Message.error(result.error ?? 'Failed to apply'));
      }
      return;
    }

    // If action has a command, execute it
    if (action.command != null) {
      try {
        await protocol.executeCommand(
          action.command!.command,
          action.command!.arguments,
        );
        editor.showMessage(Message.info('Executed: ${action.title}'));
      } catch (e) {
        editor.showMessage(Message.error('Command failed: $e'));
      }
      return;
    }

    // Action has neither edit nor command - shouldn't happen
    editor.showMessage(Message.error('Action has no edit or command'));
  }

  /// Apply workspace edit across potentially multiple files.
  static Future<_ApplyResult> _applyWorkspaceEdit(
    Editor editor,
    WorkspaceEdit workspaceEdit,
  ) async {
    int totalEdits = 0;
    int filesChanged = 0;

    for (final entry in workspaceEdit.changes.entries) {
      final fileUri = entry.key;
      final lspEdits = entry.value;

      if (lspEdits.isEmpty) continue;

      // Convert URI to path
      final filePath = Uri.parse(fileUri).toFilePath();

      // Load the file without switching to it
      final loadResult = editor.loadFile(filePath, switchTo: false);
      if (loadResult.hasError) {
        return _ApplyResult.failure('Failed to load $filePath');
      }

      final buffer = loadResult.value!;

      // Convert LSP edits to our TextEdit format
      final edits = <TextEdit>[];
      for (final lspEdit in lspEdits) {
        final startOffset = _lspPositionToOffset(
          buffer,
          lspEdit.range.startLine,
          lspEdit.range.startChar,
        );
        final endOffset = _lspPositionToOffset(
          buffer,
          lspEdit.range.endLine,
          lspEdit.range.endChar,
        );
        edits.add(TextEdit(startOffset, endOffset, lspEdit.newText));
      }

      // Apply edits to buffer
      applyEdits(buffer, edits, editor.config);

      totalEdits += edits.length;
      filesChanged++;
    }

    return _ApplyResult.success(totalEdits, filesChanged);
  }

  /// Convert LSP position (line, character) to byte offset.
  static int _lspPositionToOffset(FileBuffer file, int line, int char) {
    final lineStart = file.lineOffset(line);
    final lineText = file.lineTextAt(line);

    int offset = 0;
    int charCount = 0;
    for (final c in lineText.characters) {
      if (charCount >= char) break;
      charCount++;
      offset += c.length;
    }

    return lineStart + offset;
  }
}

/// Result of applying workspace edit.
class _ApplyResult {
  final bool success;
  final int editCount;
  final int fileCount;
  final String? error;

  _ApplyResult.success(this.editCount, this.fileCount)
    : success = true,
      error = null;

  _ApplyResult.failure(this.error)
    : success = false,
      editCount = 0,
      fileCount = 0;
}
