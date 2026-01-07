import '../editor.dart';
import '../file_buffer/file_buffer.dart';

/// Feature interface that all features must implement
abstract class Feature {
  void onInit(Editor editor);

  void onQuit(Editor editor);

  void onFileOpen(Editor editor, FileBuffer file) {}

  void onBufferSwitch(Editor editor, FileBuffer previous, FileBuffer next) {}

  void onBufferClose(Editor editor, FileBuffer file) {}

  /// Called when text changes in a buffer.
  /// [start] and [end] are byte offsets in the old text.
  /// [newText] is the replacement text.
  /// [oldText] is the text that was replaced.
  void onTextChange(
    Editor editor,
    FileBuffer file,
    int start,
    int end,
    String newText,
    String oldText,
  ) {}
}
