import 'dart:async';
import 'dart:io';

import '../editor.dart';
import '../message.dart';
import 'popup.dart';

/// File picker popup that lists all files recursively.
class FileBrowser {
  /// Show file picker popup starting at the given path.
  static void show(Editor editor, [String? path]) {
    final rootPath = _resolvePath(path);

    // Show popup immediately with "Scanning..." message
    editor.showPopup(
      PopupState.create(
        title: 'Files (scanning...)',
        items: <PopupItem<String>>[],
        onSelect: (item) => _onSelect(editor, item),
        onCancel: () {
          _cancelScan = true;
          editor.closePopup();
        },
        customFilter: (items, filter) => _fuzzyFilter(items, filter),
      ),
    );

    // Start async scanning
    _scanFilesAsync(editor, rootPath);
  }

  /// Flag to cancel ongoing scan.
  static bool _cancelScan = false;

  /// Scan files asynchronously and update popup progressively.
  static Future<void> _scanFilesAsync(Editor editor, String rootPath) async {
    _cancelScan = false;
    final items = <PopupItem<String>>[];
    final rootLen = rootPath.length + 1;
    var lastUpdateCount = 0;
    var scanComplete = false;
    final maxFiles = editor.config.fileBrowserMaxFiles;
    final maxDepth = editor.config.fileBrowserMaxDepth;

    Future<void> scanDir(Directory dir, int depth) async {
      if (_cancelScan || items.length >= maxFiles) return;
      if (depth > maxDepth) return;

      try {
        final entries = dir.listSync()..sort(_compareEntries);
        for (final entry in entries) {
          if (_cancelScan || items.length >= maxFiles) return;

          final name = entry.path.split(Platform.pathSeparator).last;

          // Skip hidden files/directories unless configured to show them
          if (!editor.config.fileBrowserShowHidden && name.startsWith('.')) {
            continue;
          }

          final relativePath = entry.path.length > rootLen
              ? entry.path.substring(rootLen)
              : name;

          if (entry is Directory) {
            // Skip excluded directories
            if (editor.config.fileBrowserExcludeDirs.contains(name)) continue;
            await scanDir(entry, depth + 1);
          } else if (entry is File) {
            items.add(PopupItem(label: relativePath, value: entry.path));

            // Update popup every 100 files for progressive loading
            if (items.length - lastUpdateCount >= 100) {
              lastUpdateCount = items.length;
              _updatePopup(editor, items, scanComplete);
              // Yield to allow UI updates
              await Future.delayed(Duration.zero);
            }
          }
        }
      } catch (e) {
        // Skip directories we can't read
      }
    }

    await scanDir(Directory(rootPath), 0);
    scanComplete = true;

    if (!_cancelScan) {
      _updatePopup(editor, items, scanComplete);
    }
  }

  /// Update the popup with current items.
  static void _updatePopup(
    Editor editor,
    List<PopupItem<String>> items,
    bool complete,
  ) {
    if (editor.popup == null) return;

    final currentPopup = editor.popup as PopupState<String>;
    final title = complete ? 'Files' : 'Files (scanning...)';

    final newPopup = currentPopup.copyWith(
      title: title,
      allItems: List.of(items),
      items: currentPopup.filterText.isEmpty
          ? List.of(items)
          : _fuzzyFilter(List.of(items), currentPopup.filterText),
    );

    editor.popup = newPopup;
    editor.draw();
  }

  /// Resolve path to an absolute directory path.
  static String _resolvePath(String? path) {
    if (path == null || path.isEmpty || path == '.') {
      return Directory.current.path;
    }
    final resolved = Directory(path);
    if (resolved.existsSync()) {
      var absPath = resolved.absolute.path;
      // Remove trailing slash to ensure consistent path handling
      if (absPath.endsWith('/') && absPath.length > 1) {
        absPath = absPath.substring(0, absPath.length - 1);
      }
      return absPath;
    }
    return Directory.current.path;
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
