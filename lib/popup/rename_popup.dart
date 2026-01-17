import 'package:characters/characters.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../message.dart';
import '../features/lsp/lsp_feature.dart';
import '../features/lsp/lsp_protocol.dart';
import 'popup.dart';

/// Reference location value for rename preview items.
class _RenameLocation {
  final String filePath;
  final int line;
  final int character;

  const _RenameLocation({
    required this.filePath,
    required this.line,
    required this.character,
  });
}

/// Show rename popup and handle the rename flow.
class RenamePopup {
  /// Show rename popup for symbol at current cursor position.
  ///
  /// Flow:
  /// 1. Call prepareRename to validate and get current name
  /// 2. Find all references to show what will be changed
  /// 3. Show popup with references and input field for new name
  /// 4. On Enter, apply the rename
  static Future<void> show(Editor editor, FileBuffer file) async {
    if (file.absolutePath == null) {
      editor.showMessage(Message.error('File not saved'));
      return;
    }

    final lsp = editor.featureRegistry?.get<LspFeature>();
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

    // Calculate line and character from cursor offset
    final line = file.lineNumber(file.cursor);
    final lineStart = file.lineOffset(line);
    final char = file.cursor - lineStart;

    // First, call prepareRename to validate and get current name
    editor.showMessage(Message.info('Preparing rename...'));

    try {
      final prepareResult = await protocol.prepareRename(uri, line, char);

      if (prepareResult == null) {
        editor.showMessage(Message.error('Cannot rename at this location'));
        return;
      }

      if (prepareResult.isError) {
        editor.showMessage(Message.error(prepareResult.errorMessage!));
        return;
      }

      // Get current symbol name
      String currentName = '';
      if (prepareResult.placeholder != null) {
        currentName = prepareResult.placeholder!;
      } else if (prepareResult.range != null) {
        final range = prepareResult.range!;
        final startOffset = _lspPositionToOffset(
          file,
          range.startLine,
          range.startChar,
        );
        final endOffset = _lspPositionToOffset(
          file,
          range.endLine,
          range.endChar,
        );
        if (startOffset < endOffset && endOffset <= file.text.length) {
          currentName = file.text.substring(startOffset, endOffset);
        }
      }

      if (currentName.isEmpty) {
        currentName = _wordAtCursor(file);
      }

      // Find all references to show what will be renamed
      editor.showMessage(Message.info('Finding references...'));
      editor.draw();

      final locations = await lsp.findReferences(editor, file);

      if (locations.isEmpty) {
        editor.showMessage(Message.error('No references found'));
        return;
      }

      editor.message = null;

      // Show rename popup with references and input field
      _showRenamePopup(
        editor,
        protocol,
        uri,
        line,
        char,
        currentName,
        locations,
      );
    } catch (e) {
      editor.showMessage(Message.error('LSP error: $e'));
    }
  }

  /// Show popup with references and input field for new name.
  static void _showRenamePopup(
    Editor editor,
    LspProtocol protocol,
    String uri,
    int line,
    int char,
    String currentName,
    List<LspLocation> locations,
  ) {
    final items = _buildReferenceItems(editor, locations);
    final fileCount = locations.map((l) => l.filePath).toSet().length;
    final fileText = fileCount == 1 ? 'file' : 'files';

    // Use a custom filter that doesn't actually filter - we want all items visible
    List<PopupItem<_RenameLocation>> noFilter(
      List<PopupItem<_RenameLocation>> items,
      String filter,
    ) => items;

    editor.showPopup(
      PopupState<_RenameLocation>(
        title: 'Rename (${locations.length} in $fileText)',
        allItems: items,
        items: items, // All items always visible
        filterText: currentName, // Pre-fill with current name
        filterCursor: currentName.length, // Cursor at end of pre-filled text
        showFilter: true,
        customFilter: noFilter,
        onSelect: (item) {
          // Read from editor.popup which has the current state with updated filterText
          final currentPopup = editor.popup as PopupState<_RenameLocation>?;
          final newName = currentPopup?.filterText ?? currentName;
          if (newName == currentName) {
            editor.showMessage(Message.error('New name must be different'));
            return;
          }
          editor.closePopup();
          _performRename(editor, protocol, uri, line, char, newName);
        },
        onCancel: () => editor.closePopup(),
      ),
    );
  }

  /// Build popup items from locations.
  static List<PopupItem<_RenameLocation>> _buildReferenceItems(
    Editor editor,
    List<LspLocation> locations,
  ) {
    final items = <PopupItem<_RenameLocation>>[];

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
        PopupItem<_RenameLocation>(
          label: label,
          detail: filePath != shortPath ? filePath : null,
          value: _RenameLocation(
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

  /// Shorten path for display.
  static String _shortenPath(String path) {
    final parts = path.split('/');
    if (parts.length <= 2) return path;
    return parts.sublist(parts.length - 2).join('/');
  }

  /// Perform the actual rename operation.
  static Future<void> _performRename(
    Editor editor,
    LspProtocol protocol,
    String uri,
    int line,
    int char,
    String newName,
  ) async {
    if (newName.isEmpty) {
      editor.showMessage(Message.error('Name cannot be empty'));
      return;
    }

    editor.showMessage(Message.info('Renaming...'));

    try {
      final workspaceEdit = await protocol.rename(uri, line, char, newName);

      if (workspaceEdit == null || workspaceEdit.isEmpty) {
        editor.showMessage(Message.error('Rename returned no changes'));
        return;
      }

      // Apply the workspace edit
      final result = await _applyWorkspaceEdit(editor, workspaceEdit);

      if (result.success) {
        final fileText = result.fileCount == 1 ? 'file' : 'files';
        editor.showMessage(
          Message.info(
            'Renamed: ${result.editCount} occurrences in ${result.fileCount} $fileText',
          ),
        );
      } else {
        editor.showMessage(Message.error(result.error ?? 'Rename failed'));
      }
    } catch (e) {
      editor.showMessage(Message.error('Rename failed: $e'));
    }
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

  /// Get word at cursor position.
  static String _wordAtCursor(FileBuffer file) {
    final text = file.text;
    final cursor = file.cursor;

    if (cursor >= text.length) return '';

    int start = cursor;
    int end = cursor;

    while (start > 0 && _isWordChar(text[start - 1])) {
      start--;
    }

    while (end < text.length && _isWordChar(text[end])) {
      end++;
    }

    if (start >= end) return '';
    return text.substring(start, end);
  }

  static bool _isWordChar(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 0x30 && code <= 0x39) || // 0-9
        (code >= 0x41 && code <= 0x5A) || // A-Z
        (code >= 0x61 && code <= 0x7A) || // a-z
        code == 0x5F; // _
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
