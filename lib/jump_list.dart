/// A saved jump location (file + cursor position).
class JumpLocation {
  final String path;
  final int cursor;

  const JumpLocation(this.path, this.cursor);

  @override
  bool operator ==(Object other) =>
      other is JumpLocation && other.path == path && other.cursor == cursor;

  @override
  int get hashCode => Object.hash(path, cursor);
}

/// Manages navigation history for Ctrl-o / Ctrl-i jumping.
class JumpList {
  final List<JumpLocation> _list = [];
  int _index = -1;
  final int maxSize;

  JumpList({this.maxSize = 100});

  /// Push current location to jump list (call before jumping).
  /// Returns without adding if [path] is null or location is duplicate.
  void push(String? path, int cursor) {
    if (path == null) return;

    final loc = JumpLocation(path, cursor);

    // Remove any forward history when pushing new location
    if (_index >= 0 && _index < _list.length - 1) {
      _list.removeRange(_index + 1, _list.length);
    }

    // Don't add duplicate of current position
    if (_list.isNotEmpty && _list.last == loc) {
      return;
    }

    _list.add(loc);
    if (_list.length > maxSize) {
      _list.removeAt(0);
    }
    _index = _list.length - 1;
  }

  /// Go back in jump list (Ctrl-o).
  /// Pass current [path] and [cursor] to save position if at end of list.
  /// Returns the location to jump to, or null if can't go back.
  JumpLocation? back(String? path, int cursor) {
    if (_list.isEmpty || _index < 0) {
      return null;
    }

    // Save current position if we're at the end
    if (_index == _list.length - 1 && path != null) {
      final currentLoc = JumpLocation(path, cursor);
      if (_list.isEmpty || _list.last != currentLoc) {
        _list.add(currentLoc);
        _index = _list.length - 1;
      }
    }

    if (_index > 0) {
      _index--;
      return _list[_index];
    }
    return null;
  }

  /// Go forward in jump list (Ctrl-i).
  /// Returns the location to jump to, or null if can't go forward.
  JumpLocation? forward() {
    if (_index < _list.length - 1) {
      _index++;
      return _list[_index];
    }
    return null;
  }
}
