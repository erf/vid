import 'package:characters/characters.dart';

import '../../editor.dart';
import '../../file_buffer/file_buffer.dart';
import '../../message.dart';
import '../../types/line_edit_action_base.dart';
import 'diagnostics_popup.dart';
import 'lsp_feature.dart';
import 'lsp_protocol.dart';
import 'rename_popup.dart';

// ===== LSP commands =====

/// Show LSP status or run LSP subcommand (:lsp).
class CmdLsp extends LineEditAction {
  const CmdLsp();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    if (args.length < 2) {
      _status(e, f);
      return;
    }
    switch (args[1]) {
      case 'restart':
        _restart(e, f);
      case 'status':
        _status(e, f);
      default:
        f.setMode(e, .normal);
        e.showMessage(.error('Unknown lsp command: ${args[1]}'));
    }
  }

  void _restart(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.error('LSP not available'));
      return;
    }
    lsp.restart(e);
  }

  void _status(Editor e, FileBuffer f) {
    f.setMode(e, .normal);
    final lsp = e.featureRegistry?.get<LspFeature>();
    if (lsp == null) {
      e.showMessage(.info('LSP: not loaded'));
      return;
    }
    lsp.showStatus(e);
  }
}

/// Show diagnostics popup (:diagnostics, :d).
class CmdDiagnostics extends LineEditAction {
  const CmdDiagnostics();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    DiagnosticsPopup.show(e);
  }
}

/// Show all diagnostics popup (:da).
class CmdDiagnosticsAll extends LineEditAction {
  const CmdDiagnosticsAll();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    DiagnosticsPopup.showAll(e);
  }
}

/// Rename symbol at cursor (:rename).
class CmdLspRename extends LineEditAction {
  const CmdLspRename();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    RenamePopup.show(e, f);
  }
}

/// Format document via LSP (:format, :fmt).
class CmdFormat extends LineEditAction {
  const CmdFormat();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    formatBuffer(e, f);
  }
}

/// Result of a formatting operation.
enum FormatResult {
  /// Formatting was applied successfully.
  success,

  /// No formatting changes needed.
  noChanges,

  /// LSP not available for this file.
  noLsp,

  /// No file path set.
  noPath,

  /// Formatting failed with an error.
  error,
}

/// Format a buffer via LSP.
///
/// Returns the result of the formatting operation.
/// If [showMessages] is true (default), shows status messages to the user.
/// If [redraw] is true (default), redraws the editor after formatting.
Future<FormatResult> formatBuffer(
  Editor e,
  FileBuffer f, {
  bool showMessages = true,
  bool redraw = true,
}) async {
  final lsp = e.featureRegistry?.get<LspFeature>();
  if (lsp == null) {
    if (showMessages) e.showMessage(Message.error('LSP not available'));
    return FormatResult.noLsp;
  }

  final path = f.absolutePath;
  if (path == null) {
    if (showMessages) e.showMessage(Message.error('No file path'));
    return FormatResult.noPath;
  }

  final protocol = lsp.getProtocolForPath(path);
  if (protocol == null) {
    if (showMessages) {
      e.showMessage(Message.error('No LSP server for this file type'));
    }
    return FormatResult.noLsp;
  }

  final uri = 'file://$path';

  try {
    final lspEdits = await protocol.formatting(
      uri,
      tabSize: e.config.tabWidth,
      insertSpaces: true,
    );

    if (lspEdits == null || lspEdits.isEmpty) {
      if (showMessages) e.showMessage(Message.info('No formatting changes'));
      return FormatResult.noChanges;
    }

    // Convert LSP edits to our TextEdit format
    final edits = <TextEdit>[];
    for (final lspEdit in lspEdits) {
      final startOffset = _lspPositionToOffset(
        f,
        lspEdit.range.startLine,
        lspEdit.range.startChar,
      );
      final endOffset = _lspPositionToOffset(
        f,
        lspEdit.range.endLine,
        lspEdit.range.endChar,
      );
      edits.add(TextEdit(startOffset, endOffset, lspEdit.newText));
    }

    // Apply edits to buffer
    applyEdits(f, edits, e.config);

    if (showMessages) {
      e.showMessage(Message.info('Formatted (${edits.length} edits)'));
    }
    if (redraw) e.draw();
    return FormatResult.success;
  } catch (err) {
    if (showMessages) e.showMessage(Message.error('Format failed: $err'));
    return FormatResult.error;
  }
}

/// Convert LSP position (line, character) to byte offset.
int _lspPositionToOffset(FileBuffer file, int line, int char) {
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

/// Check if format-on-save should run for the given file.
///
/// Returns true if:
/// - formatOnSave is enabled in config
/// - Either formatOnSaveLanguages is empty (format all) or contains this file's language
bool shouldFormatOnSave(Editor e, FileBuffer f) {
  if (!e.config.formatOnSave) return false;

  final path = f.absolutePath;
  if (path == null) return false;

  final langs = e.config.formatOnSaveLanguages;
  if (langs.isEmpty) return true; // empty = format all languages

  final languageId = languageIdFromPath(path);
  return langs.contains(languageId);
}

/// Format buffer on save if configured.
///
/// Returns true if formatting was applied successfully.
/// Shows no messages by default since it's part of the save flow.
Future<bool> maybeFormatOnSave(Editor e, FileBuffer f) async {
  if (!shouldFormatOnSave(e, f)) return false;

  final result = await formatBuffer(e, f, showMessages: false, redraw: false);
  return result == FormatResult.success;
}
