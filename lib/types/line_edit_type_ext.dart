import '../actions/buffer_actions.dart';
import '../actions/line_edit_actions.dart';
import '../actions/popup_command_actions.dart';
import '../editor.dart';
import '../features/lsp/lsp_command_actions.dart';
import '../file_buffer/file_buffer.dart';
import 'line_edit_type.dart';

extension LineEditTypeExt on LineEditType {
  /// The function that implements this line edit command.
  void Function(Editor, FileBuffer, List<String>) get fn => switch (this) {
    // Basic commands
    .noop => LineEditActions.noop,
    .quit => LineEditActions.quit,
    .forceQuit => LineEditActions.forceQuit,
    .open => LineEditActions.open,
    .read => LineEditActions.read,
    .write => LineEditActions.write,
    .writeAndQuit => LineEditActions.writeAndQuit,

    // Wrap modes
    .setNoWrap => LineEditActions.setNoWrap,
    .setCharWrap => LineEditActions.setCharWrap,
    .setWordWrap => LineEditActions.setWordWrap,

    // Buffer commands
    .nextBuffer => BufferActions.nextBuffer,
    .prevBuffer => BufferActions.prevBuffer,
    .switchToBuffer => BufferActions.switchToBuffer,
    .closeBuffer => BufferActions.closeBuffer,
    .forceCloseBuffer => BufferActions.forceCloseBuffer,
    .listBuffers => BufferActions.listBuffers,

    // LSP commands
    .lsp => LspCommandActions.lsp,
    .diagnostics => LspCommandActions.diagnostics,
    .diagnosticsAll => LspCommandActions.diagnosticsAll,
    .lspRename => LspCommandActions.rename,

    // Selection commands
    .select => LineEditActions.select,
    .selectClear => LineEditActions.selectClear,

    // Popup commands
    .themes => PopupCommandActions.themes,
    .files => PopupCommandActions.files,
    .references => PopupCommandActions.references,
  };
}
