import 'package:vid/editor.dart';
import 'package:vid/features/feature.dart';
import 'package:vid/file_buffer/file_buffer.dart';

class FeatureRegistry {
  final Editor _editor;
  final List<Feature> _features;

  const FeatureRegistry(this._editor, this._features);

  /// Get an feature by type.
  T? get<T extends Feature>() {
    for (final feature in _features) {
      if (feature is T) return feature;
    }
    return null;
  }

  void notifyInit() {
    for (final feature in _features) {
      feature.onInit(_editor);
    }
  }

  void notifyQuit() {
    for (final feature in _features) {
      feature.onQuit(_editor);
    }
  }

  void notifyFileOpen(FileBuffer file) {
    for (final feature in _features) {
      feature.onFileOpen(_editor, file);
    }
  }

  void notifyBufferSwitch(FileBuffer previous, FileBuffer next) {
    for (final feature in _features) {
      feature.onBufferSwitch(_editor, previous, next);
    }
  }

  void notifyBufferClose(FileBuffer file) {
    for (final feature in _features) {
      feature.onBufferClose(_editor, file);
    }
  }

  void notifyTextChange(
    FileBuffer file,
    int start,
    int end,
    String newText,
    String oldText,
  ) {
    for (final feature in _features) {
      feature.onTextChange(_editor, file, start, end, newText, oldText);
    }
  }
}
