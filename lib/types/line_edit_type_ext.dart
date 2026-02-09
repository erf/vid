import '../actions/buffer_actions.dart';
import '../actions/line_edit_actions.dart';
import '../actions/popup_command_actions.dart';
import '../config.dart';
import '../features/lsp/lsp_command_actions.dart';
import 'line_edit_action_base.dart';
import 'line_edit_type.dart';

extension LineEditTypeExt on LineEditType {
  /// The action that implements this line edit command.
  LineEditAction get fn => switch (this) {
    // Basic commands
    .noop => const CmdNoop(),
    .quit => const CmdQuit(),
    .forceQuit => const CmdForceQuit(),
    .open => const CmdOpen(),
    .read => const CmdRead(),
    .write => const CmdWrite(),
    .forceWrite => const CmdForceWrite(),
    .writeAndQuit => const CmdWriteAndQuit(),

    // Wrap modes
    .setNoWrap => const CmdSetWrap(WrapMode.none, 'off'),
    .setCharWrap => const CmdSetWrap(WrapMode.char, 'char'),
    .setWordWrap => const CmdSetWrap(WrapMode.word, 'word'),

    // Buffer commands
    .nextBuffer => const CmdNextBuffer(),
    .prevBuffer => const CmdPrevBuffer(),
    .switchToBuffer => const CmdSwitchToBuffer(),
    .closeBuffer => const CmdCloseBuffer(),
    .forceCloseBuffer => const CmdForceCloseBuffer(),
    .listBuffers => const CmdListBuffers(),

    // LSP commands
    .lsp => const CmdLsp(),
    .diagnostics => const CmdDiagnostics(),
    .diagnosticsAll => const CmdDiagnosticsAll(),
    .lspRename => const CmdLspRename(),
    .format => const CmdFormat(),
    .symbols => const CmdSymbols(),

    // Selection commands
    .select => const CmdSelect(),
    .selectClear => const CmdSelectClear(),

    // Popup commands
    .themes => const CmdThemes(),
    .files => const CmdFiles(),
    .references => const CmdReferences(),
  };
}
