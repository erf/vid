import 'dart:io';

import '../editor.dart';
import '../message.dart';
import 'popup.dart';

/// File picker popup that lists all files recursively.
class FileBrowser {
  /// Show file picker popup starting at the given path.
  static void show(Editor editor, [String? path]) {
    final rootPath = _resolvePath(path);
    final items = _listAllFiles(rootPath);

    editor.showPopup(
      PopupState.create(
        title: 'Open File',
        items: items,
        onSelect: (item) => _onSelect(editor, item as PopupItem<String>),
        onCancel: () => editor.closePopup(),
        customFilter: (items, filter) =>
            _fuzzyFilter(items.cast<PopupItem<String>>(), filter),
      ),
    );
  }

  /// Resolve path to an absolute directory path.
  static String _resolvePath(String? path) {
    if (path == null || path.isEmpty || path == '.') {
      return Directory.current.path;
    }
    final resolved = Directory(path);
    if (resolved.existsSync()) {
      return resolved.absolute.path;
    }
    return Directory.current.path;
  }

  /// List all files recursively from the root path.
  static List<PopupItem<String>> _listAllFiles(String rootPath) {
    final items = <PopupItem<String>>[];
    final rootDir = Directory(rootPath);
    final rootLen = rootPath.length + 1;

    void scanDir(Directory dir, int depth) {
      if (depth > 10) return; // Prevent too deep recursion
      try {
        final entries = dir.listSync()..sort(_compareEntries);
        for (final entry in entries) {
          final name = entry.path.split(Platform.pathSeparator).last;
          // Skip all hidden files/directories
          if (name.startsWith('.')) continue;
          if (entry is Directory) {
            scanDir(entry, depth + 1);
          } else if (entry is File) {
            final relativePath = entry.path.length > rootLen
                ? entry.path.substring(rootLen)
                : name;
            items.add(PopupItem(label: relativePath, value: entry.path));
          }
        }
      } catch (e) {
        // Skip directories we can't read
      }
    }

    scanDir(rootDir, 0);
    return items;
  }

  /// Compare directory entries for sorting (directories first, then alphabetically).
  static int _compareEntries(FileSystemEntity a, FileSystemEntity b) {
    final aIsDir = a is Directory;
    final bIsDir = b is Directory;
    if (aIsDir && !bIsDir) return -1;
    if (!aIsDir && bIsDir) return 1;
    final aName = a.path.split(Platform.pathSeparator).last.toLowerCase();
    final bName = b.path.split(Platform.pathSeparator).last.toLowerCase();
    return aName.compareTo(bName);
  }

  /// Handle item selection.
  static void _onSelect(Editor editor, PopupItem<String> item) {
    editor.closePopup();
    final result = editor.loadFile(item.value);
    if (result.hasError) {
      editor.showMessage(Message.error(result.error!));
    }
  }

  /// Fuzzy filter for file paths.
  static List<PopupItem<String>> _fuzzyFilter(
    List<PopupItem<String>> items,
    String filter,
  ) {
    if (filter.isEmpty) return items;
    final lowerFilter = filter.toLowerCase();
    final results = <(PopupItem<String>, int)>[];
    for (final item in items) {
      final score = _fuzzyScore(item.label.toLowerCase(), lowerFilter);
      if (score > 0) results.add((item, score));
    }
    results.sort((a, b) => b.$2.compareTo(a.$2));
    return results.map((r) => r.$1).toList();
  }

  /// Calculate fuzzy match score.
  static int _fuzzyScore(String text, String pattern) {
    if (pattern.isEmpty) return 1;
    if (text.isEmpty) return 0;
    // Exact substring match gets high score
    if (text.contains(pattern)) {
      if (text.startsWith(pattern)) return 100 + pattern.length;
      // Bonus for matching filename part
      final lastSlash = text.lastIndexOf('/');
      if (lastSlash >= 0 && text.substring(lastSlash + 1).contains(pattern)) {
        return 80 + pattern.length;
      }
      return 50 + pattern.length;
    }
    // Check if all pattern chars exist in order
    int patternIndex = 0;
    int score = 0;
    bool prevMatched = false;
    for (int i = 0; i < text.length && patternIndex < pattern.length; i++) {
      if (text[i] == pattern[patternIndex]) {
        patternIndex++;
        score += prevMatched ? 2 : 1;
        prevMatched = true;
      } else {
        prevMatched = false;
      }
    }
    return patternIndex == pattern.length ? score : 0;
  }
}
