import 'feature.dart';
import '../file_buffer/file_buffer.dart';

class FeatureRegistry {
  final List<Feature> _features;

  const FeatureRegistry(this._features);

  /// Get an feature by type.
  T? get<T extends Feature>() {
    for (final feature in _features) {
      if (feature is T) return feature;
    }
    return null;
  }

  void notifyInit() {
    for (final feature in _features) {
      feature.onInit();
    }
  }

  void notifyQuit() {
    for (final feature in _features) {
      feature.onQuit();
    }
  }

  void notifyFileOpen(FileBuffer file) {
    for (final feature in _features) {
      feature.onFileOpen(file);
    }
  }

  void notifyBufferSwitch(FileBuffer previous, FileBuffer next) {
    for (final feature in _features) {
      feature.onBufferSwitch(previous, next);
    }
  }

  void notifyBufferClose(FileBuffer file) {
    for (final feature in _features) {
      feature.onBufferClose(file);
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
      feature.onTextChange(file, start, end, newText, oldText);
    }
  }
}
