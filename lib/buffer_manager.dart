import 'error_or.dart';
import 'file_buffer/file_buffer.dart';

/// Owns the list of open buffers and the active buffer index.
///
/// Editor-facing behavior that crosses concerns (terminal title, feature
/// notifications, redraw, quitting) is delegated back via callbacks so the
/// manager itself only deals with buffer list mechanics.
class BufferManager {
  /// Called when a buffer becomes managed; should attach text-change
  /// listeners and notify features.
  final void Function(FileBuffer buffer) onAttach;

  /// Called when the active buffer (or its path) changes; should update the
  /// terminal title and redraw.
  final void Function(FileBuffer buffer) onActivated;

  /// Called when the active buffer switches to a different buffer.
  final void Function(FileBuffer oldBuffer, FileBuffer newBuffer)
  onBufferSwitch;

  /// Called after a buffer was opened; should notify features and redraw.
  final void Function(FileBuffer buffer) onOpened;

  /// Called when a buffer is about to be closed; should notify features.
  final void Function(FileBuffer buffer) onClosing;

  /// Called when the last buffer is closed; should quit the editor.
  final void Function() onEmpty;

  final String workingDirectory;

  final List<FileBuffer> _buffers = [];
  int _currentIndex = 0;

  BufferManager({
    required this.workingDirectory,
    required this.onAttach,
    required this.onActivated,
    required this.onBufferSwitch,
    required this.onOpened,
    required this.onClosing,
    required this.onEmpty,
  });

  // Getters and setters
  //
  // Invariant: `_buffers` is never empty during normal operation. The Editor
  // seeds it with one buffer, and the only path that drains it is `close`
  // which triggers `onEmpty` (which exits the process) before returning.
  // Accessing `current` when buffers is empty would be a programming error
  // and intentionally throws.
  FileBuffer get current => _buffers[_currentIndex];

  /// Replace the current buffer without attaching listeners (mirrors the
  /// historical behavior of the `Editor.file` setter).
  set current(FileBuffer buffer) {
    _buffers[_currentIndex] = buffer;
  }

  List<FileBuffer> get buffers => _buffers;
  int get count => _buffers.length;
  int get currentIndex => _currentIndex;

  /// Attach listeners and append [buffer] to the list.
  void add(FileBuffer buffer) {
    onAttach(buffer);
    _buffers.add(buffer);
  }

  /// Replace the buffer at [index], attaching listeners.
  void replace(int index, FileBuffer buffer) {
    onAttach(buffer);
    _buffers[index] = buffer;
  }

  /// Load a file into a buffer, optionally switching to it.
  ErrorOr<FileBuffer> load(String path, {bool switchTo = true}) {
    // Check if file is already open
    final existingIndex = _buffers.indexWhere(
      (b) =>
          b.absolutePath != null &&
          b.absolutePath == FileBufferIo.toAbsolutePath(path),
    );
    if (existingIndex != -1) {
      if (switchTo) switchToBuffer(existingIndex);
      return ErrorOr.value(_buffers[existingIndex]);
    }

    final result = FileBuffer.load(
      path,
      createIfNotExists: false,
      cwd: workingDirectory,
    );
    if (result.hasError) {
      return result;
    }
    final buffer = result.value!;

    // Replace untouched buffer instead of adding a new one (vim behavior)
    if (current.isUntouched) {
      replace(_currentIndex, buffer);
    } else {
      add(buffer);
      if (switchTo) {
        _currentIndex = _buffers.length - 1;
      }
    }

    if (switchTo) {
      onActivated(buffer);
    }
    onOpened(buffer);
    return result;
  }

  /// Switch to buffer at given index
  void switchToBuffer(int index) {
    if (index < 0 || index >= _buffers.length) return;
    final oldBuffer = current;
    _currentIndex = index;
    onActivated(current);
    onBufferSwitch(oldBuffer, current);
  }

  /// Switch to next buffer
  void next() {
    if (_buffers.length <= 1) return;
    switchToBuffer((_currentIndex + 1) % _buffers.length);
  }

  /// Switch to previous buffer
  void prev() {
    if (_buffers.length <= 1) return;
    switchToBuffer((_currentIndex - 1 + _buffers.length) % _buffers.length);
  }

  /// Close buffer at given index, returns true if closed
  bool close(int index, {bool force = false}) {
    if (index < 0 || index >= _buffers.length) return false;
    final buffer = _buffers[index];

    if (!force && buffer.modified) {
      return false;
    }

    onClosing(buffer);
    _buffers.removeAt(index);

    if (_buffers.isEmpty) {
      // Last buffer closed, quit editor
      onEmpty();
      return true;
    }

    // Adjust current index if needed
    if (_currentIndex >= _buffers.length) {
      _currentIndex = _buffers.length - 1;
    } else if (_currentIndex > index) {
      _currentIndex--;
    }

    onActivated(current);
    return true;
  }

  /// Check if any buffer has unsaved changes
  bool get hasUnsavedChanges => _buffers.any((b) => b.modified);

  /// Get count of buffers with unsaved changes
  int get unsavedCount => _buffers.where((b) => b.modified).length;

  /// Get list of buffer info for display
  List<String> get list => _buffers.asMap().entries.map((e) {
    final idx = e.key;
    final buf = e.value;
    final current = idx == _currentIndex ? '%' : ' ';
    final modified = buf.modified ? '+' : ' ';
    final name = buf.relativePath ?? '[No Name]';
    return '${idx + 1}$current$modified "$name"';
  }).toList();
}
