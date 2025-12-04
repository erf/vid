import 'package:vid/file_buffer/file_buffer_mode.dart';
import 'package:vid/file_buffer/file_buffer_text.dart';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import 'command.dart';

class ReplaceDefaultCommand extends Command {
  const ReplaceDefaultCommand();

  @override
  void execute(Editor e, FileBuffer f, String s) {
    f.setMode(e, .normal);
    // Check if text is empty (just a trailing newline)
    if (f.text.length <= 1) return;
    f.replaceAt(f.cursor, s, config: e.config);
  }
}
