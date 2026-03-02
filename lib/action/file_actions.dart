import '../editor.dart';
import '../error_or.dart';
import '../features/lsp/lsp_command_actions.dart';
import '../file_buffer/file_buffer.dart';
import 'action_base.dart';

/// Quit editor if no unsaved changes.
class Quit extends Action {
  const Quit();

  @override
  void call(Editor e, FileBuffer f) {
    final unsavedCount = e.unsavedBufferCount;
    if (unsavedCount > 0) {
      e.showMessage(.error('$unsavedCount buffer(s) have unsaved changes'));
    } else {
      e.quit();
    }
  }
}

/// Quit without saving.
class QuitWithoutSaving extends Action {
  const QuitWithoutSaving();

  @override
  void call(Editor e, FileBuffer f) {
    e.quit();
  }
}

/// Save and quit (ZZ).
class WriteAndQuit extends Action {
  const WriteAndQuit();

  @override
  void call(Editor e, FileBuffer f) {
    _saveAndQuit(e, f);
  }

  Future<void> _saveAndQuit(Editor e, FileBuffer f) async {
    // Format on save if configured
    await maybeFormatOnSave(e, f);

    ErrorOr result = f.save(e, f.path);
    if (result.hasError) {
      e.showMessage(.error(result.error!));
    } else {
      e.quit();
    }
  }
}

/// Save file.
class Save extends Action {
  const Save();

  @override
  void call(Editor e, FileBuffer f) {
    _save(e, f);
  }

  Future<void> _save(Editor e, FileBuffer f) async {
    // Format on save if configured
    final formatted = await maybeFormatOnSave(e, f);

    ErrorOr result = f.save(e, f.path);
    if (result.hasError) {
      e.showMessage(.error(result.error!));
    } else {
      final msg = formatted ? 'Saved (formatted)' : 'File saved';
      e.showMessage(.info(msg));
    }
  }
}
