import '../editor.dart';
import '../file_buffer.dart';

abstract class Command {
  const Command();

  void execute(Editor e, FileBuffer f, String s) {}
}
