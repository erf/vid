import 'package:vid/file_buffer/file_buffer_lines.dart';
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
    if (f.empty) return;
    f.replaceAt(e, f.cursor, s);
  }
}
