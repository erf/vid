import '../editor.dart';
import '../file_buffer/file_buffer.dart';

/// Feature interface that all features must implement
abstract class Feature {
  final Editor editor;

  Feature(this.editor);

  void onInit();

  void onQuit();

  void onFileOpen(FileBuffer file) {}

  void onBufferSwitch(FileBuffer previous, FileBuffer next) {}

  void onBufferClose(FileBuffer file) {}

  /// Called when text changes in a buffer.
  /// [start] and [end] are byte offsets in the old text.
  /// [newText] is the replacement text.
  /// [oldText] is the text that was replaced.
  void onTextChange(
    FileBuffer file,
    int start,
    int end,
    String newText,
    String oldText,
  ) {}
}
