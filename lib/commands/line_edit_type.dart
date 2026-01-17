import '../actions/line_edit.dart';
import '../editor.dart';
import '../features/lsp/lsp_actions.dart';
import '../file_buffer/file_buffer.dart';

/// Types of line edit commands - used for :commands.
enum LineEditType {
  // Basic commands
  noop,
  quit,
  forceQuit,
  open,
  read,
  write,
  writeAndQuit,

  // Wrap modes
  setNoWrap,
  setCharWrap,
  setWordWrap,

  // Buffer commands
  nextBuffer,
  prevBuffer,
  switchToBuffer,
  closeBuffer,
  forceCloseBuffer,
  listBuffers,

  // LSP commands
  lsp,
  diagnostics,
  diagnosticsAll,
  lspRename,

  // Selection commands
  select,
  selectClear,

  // Popup commands
  themes,
  files,
  references,
}

extension LineEditTypeExt on LineEditType {
  /// The function that implements this line edit command.
  void Function(Editor, FileBuffer, List<String>) get fn => switch (this) {
    // Basic commands
    .noop => LineEdit.noop,
    .quit => LineEdit.quit,
    .forceQuit => LineEdit.forceQuit,
    .open => LineEdit.open,
    .read => LineEdit.read,
    .write => LineEdit.write,
    .writeAndQuit => LineEdit.writeAndQuit,

    // Wrap modes
    .setNoWrap => LineEdit.setNoWrap,
    .setCharWrap => LineEdit.setCharWrap,
    .setWordWrap => LineEdit.setWordWrap,

    // Buffer commands
    .nextBuffer => BufferCommands.nextBuffer,
    .prevBuffer => BufferCommands.prevBuffer,
    .switchToBuffer => BufferCommands.switchToBuffer,
    .closeBuffer => BufferCommands.closeBuffer,
    .forceCloseBuffer => BufferCommands.forceCloseBuffer,
    .listBuffers => BufferCommands.listBuffers,

    // LSP commands
    .lsp => LspCommands.lsp,
    .diagnostics => LspCommands.diagnostics,
    .diagnosticsAll => LspCommands.diagnosticsAll,
    .lspRename => LspCommands.rename,

    // Selection commands
    .select => LineEdit.select,
    .selectClear => LineEdit.selectClear,

    // Popup commands
    .themes => PopupCommands.themes,
    .files => PopupCommands.files,
    .references => PopupCommands.references,
  };
}
