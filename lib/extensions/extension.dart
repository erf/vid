import '../editor.dart';
import '../file_buffer/file_buffer.dart';

/// Extension interface that all extensions must implement
abstract class Extension {
  void onInit(Editor editor);

  void onQuit(Editor editor);

  void onFileOpen(Editor editor, FileBuffer file) {}

  void onBufferSwitch(Editor editor, FileBuffer previous, FileBuffer next) {}

  void onBufferClose(Editor editor, FileBuffer file) {}
}
