import 'package:vid/editor.dart';
import 'package:vid/extensions/extension.dart';
import 'package:vid/file_buffer.dart';

class ExtensionRegistry {
  final Editor _editor;
  final List<Extension> _extensions;

  const ExtensionRegistry(this._editor, this._extensions);

  void notifyInit() {
    for (final extension in _extensions) {
      extension.onInit(_editor);
    }
  }

  void notifyQuit() {
    for (final extension in _extensions) {
      extension.onQuit(_editor);
    }
  }

  void notifyFileOpen(FileBuffer file) {
    for (final extension in _extensions) {
      extension.onFileOpen(_editor, file);
    }
  }
}
