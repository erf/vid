import 'dart:io';

import '../editor.dart';
import '../message.dart';
import 'popup.dart';

/// Buffer selector popup for switching between open buffers.
class BufferSelector {
  /// Show buffer selector popup.
  static void show(Editor editor) {
    final items = _listBuffers(editor);

    if (items.isEmpty) {
      editor.showMessage(Message.info('No buffers open'));
      return;
    }

    // Pre-select current buffer
    final selectedIndex = editor.currentBufferIndex;

    editor.showPopup(
      PopupState.create(
        title: 'Buffers',
        items: items,
        onSelect: (item) => _onSelect(editor, item as PopupItem<int>),
        onCancel: () => editor.closePopup(),
      ).copyWith(selectedIndex: selectedIndex),
    );
  }

  /// List open buffers as popup items.
  static List<PopupItem<int>> _listBuffers(Editor editor) {
    final items = <PopupItem<int>>[];

    for (int i = 0; i < editor.bufferCount; i++) {
      final buffer = editor.buffers[i];
      final isCurrent = i == editor.currentBufferIndex;
      final isModified = buffer.modified;

      // Get filename or [No Name]
      final path = buffer.path;
      String name;
      String? detail;

      if (path != null) {
        name = path.split(Platform.pathSeparator).last;
        // Show parent directory as detail
        final parts = path.split(Platform.pathSeparator);
        if (parts.length > 1) {
          detail = parts.sublist(0, parts.length - 1).join('/');
          // Shorten long paths
          if (detail.length > 30) {
            final dirParts = detail.split('/');
            if (dirParts.length > 3) {
              detail = '.../${dirParts.sublist(dirParts.length - 2).join('/')}';
            }
          }
        }
      } else {
        name = '[No Name]';
      }

      final prefix = isCurrent ? '> ' : '  ';
      items.add(
        PopupItem(
          label: '$prefix${i + 1}. $name${isModified ? ' *' : ''}',
          detail: detail,
          value: i,
        ),
      );
    }

    return items;
  }

  /// Handle buffer selection.
  static void _onSelect(Editor editor, PopupItem<int> item) {
    editor.closePopup();
    editor.switchBuffer(item.value);
    editor.showMessage(
      Message.info('Buffer ${item.value + 1}/${editor.bufferCount}'),
    );
  }
}
