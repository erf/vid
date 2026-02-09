import 'dart:io';

import '../config.dart';
import '../editor.dart';
import '../error_or.dart';
import '../features/lsp/lsp_command_actions.dart';
import '../file_buffer/file_buffer.dart';
import '../popup/file_browser.dart';
import '../selection.dart';
import '../types/line_edit_action_base.dart';
import 'normal_actions.dart';

// ===== Basic commands =====

/// No operation - just returns to normal mode.
class CmdNoop extends LineEditAction {
  const CmdNoop();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
  }
}

/// Open file or directory (:e, :edit, :o, :open).
class CmdOpen extends LineEditAction {
  const CmdOpen();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    if (args.length < 2 || args[1].isEmpty) {
      // No path specified - show file browser in current directory
      FileBrowser.show(e);
      return;
    }
    String path = args[1];

    // Check if path is a directory
    final dir = Directory(path);
    if (dir.existsSync()) {
      // Path is a directory - show file browser
      FileBrowser.show(e, path);
      return;
    }

    // Path is a file - open it directly
    ErrorOr<FileBuffer> result = e.loadFile(path);
    if (result.hasError) {
      e.showMessage(.error(result.error!));
    } else {
      e.showMessage(.info('Opened \'$path\''));
    }
  }
}

/// Read file into buffer (:r, :read).
class CmdRead extends LineEditAction {
  const CmdRead();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    if (args.length < 2 || args[1].isEmpty) {
      e.showMessage(.error('No file name'));
      return;
    }
    String path = args[1];
    ErrorOr result = f.insertFile(e, path);
    if (result.hasError) {
      e.showMessage(.error(result.error!));
    } else {
      e.showMessage(.info('Read \'$path\''));
    }
  }
}

/// Write buffer to file (:w, :write).
class CmdWrite extends LineEditAction {
  const CmdWrite();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    _write(e, f, args, force: false);
  }

  static Future<void> _write(
    Editor e,
    FileBuffer f,
    List<String> args, {
    required bool force,
  }) async {
    String? path = f.path;
    if (args.length > 1) {
      path = args[1];
    }

    // Check if writing to a different path and file already exists
    if (!force && path != null && path != f.path && File(path).existsSync()) {
      e.showMessage(.error('File exists (use :w! to override): \'$path\''));
      return;
    }

    // Format on save if configured
    final formatted = await maybeFormatOnSave(e, f);

    final ErrorOr<bool> result = f.save(e, path);
    if (result.hasError) {
      e.showMessage(.error(result.error!));
    } else {
      f.path = path; // set path after successful save
      final msg = formatted ? 'Saved \'$path\' (formatted)' : 'Saved \'$path\'';
      e.showMessage(.info(msg));
    }
  }
}

/// Force write buffer to file (:w!, :write!).
class CmdForceWrite extends LineEditAction {
  const CmdForceWrite();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    CmdWrite._write(e, f, args, force: true);
  }
}

/// Write and quit (:wq, :x, :exit).
class CmdWriteAndQuit extends LineEditAction {
  const CmdWriteAndQuit();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    _writeAndQuit(e, f, args);
  }

  Future<void> _writeAndQuit(Editor e, FileBuffer f, List<String> args) async {
    // If a path argument is provided, save current buffer to that path first
    if (args.length > 1) {
      final path = args[1];
      await maybeFormatOnSave(e, f);
      final result = f.save(e, path);
      if (result.hasError) {
        e.showMessage(.error(result.error!));
        return;
      }
      f.path = path;
    }

    // Save all modified buffers
    final List<String> errors = [];
    for (final buffer in e.buffers) {
      if (!buffer.modified) continue;

      if (buffer.path == null || buffer.path!.isEmpty) {
        final name = buffer.relativePath ?? '[No Name]';
        errors.add('No file name for buffer \'$name\'');
        continue;
      }

      // Format on save for each modified buffer
      await maybeFormatOnSave(e, buffer);

      final result = buffer.save(e, buffer.path);
      if (result.hasError) {
        errors.add(result.error!);
      }
    }

    if (errors.isNotEmpty) {
      e.showMessage(.error(errors.first));
    } else {
      e.quit();
    }
  }
}

/// Quit (:q, :quit).
class CmdQuit extends LineEditAction {
  const CmdQuit();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    const Quit()(e, f);
  }
}

/// Force quit (:q!, :quit!).
class CmdForceQuit extends LineEditAction {
  const CmdForceQuit();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    e.quit();
  }
}

// ===== Wrap mode commands =====

/// Set wrap mode (:nowrap, :charwrap, :wordwrap).
class CmdSetWrap extends LineEditAction {
  final WrapMode mode;
  final String label;
  const CmdSetWrap(this.mode, this.label);

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    e.setWrapMode(mode);
    e.showMessage(.info('Wrap: $label'));
  }
}

// ===== Selection commands =====

/// Select all matches of a regex pattern (:sel pattern).
///
/// If there's an active visual selection (from visual or visual line mode),
/// only matches within that selection are returned.
class CmdSelect extends LineEditAction {
  const CmdSelect();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    if (args.length < 2) {
      f.setMode(e, .normal);
      e.showMessage(.error('Pattern required: :sel <pattern>'));
      return;
    }
    final pattern = args.skip(1).join(' ');
    try {
      final regex = RegExp(pattern);

      // Check if we have a visual selection to scope the search
      final List<Selection> selections;
      if (f.hasVisualSelection) {
        // Search within each visual selection and combine results
        final results = <Selection>[];
        for (final sel in f.selections) {
          // Visual mode is inclusive, extend end by one grapheme
          final rangeEnd = f.nextGrapheme(sel.end);
          final matches = selectAllMatches(
            f.text,
            regex,
            start: sel.start,
            end: rangeEnd,
          );
          results.addAll(matches);
        }
        selections = results;
      } else {
        selections = selectAllMatches(f.text, regex);
      }

      if (selections.isEmpty) {
        f.setMode(e, .normal);
        e.showMessage(.info('No matches found'));
        return;
      }
      f.selections = selections;
      // Enter visual mode for multiple visual selections
      f.setMode(e, .visual);
      e.showMessage(.info('${selections.length} selection(s)'));
    } on FormatException catch (ex) {
      f.setMode(e, .normal);
      e.showMessage(.error('Invalid regex: ${ex.message}'));
    }
  }
}

/// Clear all selections (:selclear).
class CmdSelectClear extends LineEditAction {
  const CmdSelectClear();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    f.setMode(e, .normal);
    f.selections = [f.selection.collapse()];
    e.showMessage(.info('Selections cleared'));
  }
}

/// Substitute pattern (:s/pattern/replacement/[g]).
class CmdSubstitute extends LineEditAction {
  const CmdSubstitute();

  @override
  void call(Editor e, FileBuffer f, List<String> args) {
    List<String> parts = args.first.split('/');
    String pattern = parts[1];
    String replacement = parts.length >= 3 ? parts[2] : '';
    bool global = parts.length >= 4 && parts[3] == 'g';

    f.setMode(e, .normal);
    final regex = RegExp(RegExp.escape(pattern));
    while (true) {
      Match? match = regex.firstMatch(f.text);
      if (match == null) {
        break;
      }
      f.replace(match.start, match.end, replacement, config: e.config);
      f.cursor = match.start;
      f.clampCursor();
      if (!global) {
        break;
      }
    }
  }
}
