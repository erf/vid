/// A generic popup menu item.
class PopupItem<T> {
  /// Display text for this item.
  final String label;

  /// Optional secondary text (e.g., file path, description).
  final String? detail;

  /// Optional icon/prefix character.
  final String? icon;

  /// The value associated with this item.
  final T value;

  /// Whether this item represents a directory (for file browser).
  final bool isDirectory;

  const PopupItem({
    required this.label,
    this.detail,
    this.icon,
    required this.value,
    this.isDirectory = false,
  });

  /// Create a copy with modified fields.
  PopupItem<T> copyWith({
    String? label,
    String? detail,
    String? icon,
    T? value,
    bool? isDirectory,
  }) {
    return PopupItem<T>(
      label: label ?? this.label,
      detail: detail ?? this.detail,
      icon: icon ?? this.icon,
      value: value ?? this.value,
      isDirectory: isDirectory ?? this.isDirectory,
    );
  }
}

/// Callback when an item is selected.
typedef PopupSelectCallback<T> = void Function(PopupItem<T> item);

/// Callback when popup is cancelled.
typedef PopupCancelCallback = void Function();

/// Callback when filter text changes (for custom filtering).
typedef PopupFilterCallback<T> =
    List<PopupItem<T>> Function(List<PopupItem<T>> items, String filter);

/// A generic popup menu state.
class PopupState<T> {
  /// Title displayed at the top of the popup.
  final String title;

  /// All items (unfiltered).
  final List<PopupItem<T>> allItems;

  /// Currently visible items (after filtering).
  final List<PopupItem<T>> items;

  /// Currently selected index in [items].
  final int selectedIndex;

  /// Scroll offset (first visible item index).
  final int scrollOffset;

  /// Current filter text.
  final String filterText;

  /// Cursor position within filter text (byte offset).
  final int filterCursor;

  /// Callback when an item is selected.
  final PopupSelectCallback<T>? onSelect;

  /// Callback when an item is highlighted (selection changes).
  final PopupSelectCallback<T>? onHighlight;

  /// Callback when popup is cancelled.
  final PopupCancelCallback? onCancel;

  /// Custom filter function (optional).
  final PopupFilterCallback<T>? customFilter;

  /// Whether to show filter input.
  final bool showFilter;

  /// Maximum visible items (popup height).
  final int maxVisibleItems;

  /// Maximum width of the popup (null for auto-sizing).
  final int? maxWidth;

  const PopupState({
    required this.title,
    required this.allItems,
    required this.items,
    this.selectedIndex = 0,
    this.scrollOffset = 0,
    this.filterText = '',
    this.filterCursor = 0,
    this.onSelect,
    this.onHighlight,
    this.onCancel,
    this.customFilter,
    this.showFilter = true,
    this.maxVisibleItems = 15,
    this.maxWidth,
  });

  /// Create initial popup state.
  factory PopupState.create({
    required String title,
    required List<PopupItem<T>> items,
    PopupSelectCallback<T>? onSelect,
    PopupSelectCallback<T>? onHighlight,
    PopupCancelCallback? onCancel,
    PopupFilterCallback<T>? customFilter,
    bool showFilter = true,
    int maxVisibleItems = 15,
    int? maxWidth,
  }) {
    return PopupState<T>(
      title: title,
      allItems: items,
      items: items,
      selectedIndex: 0,
      scrollOffset: 0,
      filterText: '',
      filterCursor: 0,
      onSelect: onSelect,
      onHighlight: onHighlight,
      onCancel: onCancel,
      customFilter: customFilter,
      showFilter: showFilter,
      maxVisibleItems: maxVisibleItems,
      maxWidth: maxWidth,
    );
  }

  /// Get currently selected item, or null if no items.
  PopupItem<T>? get selectedItem =>
      items.isNotEmpty && selectedIndex < items.length
      ? items[selectedIndex]
      : null;

  /// Invoke onSelect callback with the selected item (type-safe).
  void invokeSelect() {
    final item = selectedItem;
    if (item != null && onSelect != null) {
      onSelect!(item);
    }
  }

  /// Invoke onHighlight callback with the selected item (type-safe).
  void invokeHighlight() {
    final item = selectedItem;
    if (item != null && onHighlight != null) {
      onHighlight!(item);
    }
  }

  /// Create a copy with modified fields.
  PopupState<T> copyWith({
    String? title,
    List<PopupItem<T>>? allItems,
    List<PopupItem<T>>? items,
    int? selectedIndex,
    int? scrollOffset,
    String? filterText,
    int? filterCursor,
    PopupSelectCallback<T>? onSelect,
    PopupSelectCallback<T>? onHighlight,
    PopupCancelCallback? onCancel,
    PopupFilterCallback<T>? customFilter,
    bool? showFilter,
    int? maxVisibleItems,
    int? maxWidth,
  }) {
    return PopupState<T>(
      title: title ?? this.title,
      allItems: allItems ?? this.allItems,
      items: items ?? this.items,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      filterText: filterText ?? this.filterText,
      filterCursor: filterCursor ?? this.filterCursor,
      onSelect: onSelect ?? this.onSelect,
      onHighlight: onHighlight ?? this.onHighlight,
      onCancel: onCancel ?? this.onCancel,
      customFilter: customFilter ?? this.customFilter,
      showFilter: showFilter ?? this.showFilter,
      maxVisibleItems: maxVisibleItems ?? this.maxVisibleItems,
      maxWidth: maxWidth ?? this.maxWidth,
    );
  }

  /// Move selection down (wraps to top when at bottom).
  PopupState<T> moveDown() {
    if (items.isEmpty) return this;
    final newIndex = (selectedIndex + 1) % items.length;
    var newScroll = scrollOffset;
    if (newIndex == 0) {
      // Wrapped to top
      newScroll = 0;
    } else if (newIndex >= scrollOffset + maxVisibleItems) {
      // Scroll down if selection goes below visible area
      newScroll = newIndex - maxVisibleItems + 1;
    }
    return copyWith(selectedIndex: newIndex, scrollOffset: newScroll);
  }

  /// Move selection up (wraps to bottom when at top).
  PopupState<T> moveUp() {
    if (items.isEmpty) return this;
    final newIndex = (selectedIndex - 1 + items.length) % items.length;
    var newScroll = scrollOffset;
    if (newIndex == items.length - 1 && selectedIndex == 0) {
      // Wrapped to bottom
      newScroll = (newIndex - maxVisibleItems + 1).clamp(0, newIndex);
    } else if (newIndex < scrollOffset) {
      // Scroll up if selection goes above visible area
      newScroll = newIndex;
    }
    return copyWith(selectedIndex: newIndex, scrollOffset: newScroll);
  }

  /// Move selection to top.
  PopupState<T> moveToTop() {
    if (items.isEmpty) return this;
    return copyWith(selectedIndex: 0, scrollOffset: 0);
  }

  /// Move selection to bottom.
  PopupState<T> moveToBottom() {
    if (items.isEmpty) return this;
    final newIndex = items.length - 1;
    final newScroll = (newIndex - maxVisibleItems + 1).clamp(0, newIndex);
    return copyWith(selectedIndex: newIndex, scrollOffset: newScroll);
  }

  /// Move selection down by half a page (Ctrl+D style).
  PopupState<T> pageDown() {
    if (items.isEmpty) return this;
    final halfPage = (maxVisibleItems ~/ 2).clamp(1, maxVisibleItems);
    return scrollViewport(halfPage);
  }

  /// Move selection up by half a page (Ctrl+U style).
  PopupState<T> pageUp() {
    if (items.isEmpty) return this;
    final halfPage = (maxVisibleItems ~/ 2).clamp(1, maxVisibleItems);
    return scrollViewport(-halfPage);
  }

  /// Scroll viewport by delta lines.
  PopupState<T> scrollViewport(int delta) {
    if (items.isEmpty) return this;

    final maxScroll = items.length - maxVisibleItems;
    if (maxScroll <= 0) return this; // All items fit in view

    final newScroll = (scrollOffset + delta).clamp(0, maxScroll);
    final newIndex = (selectedIndex + delta).clamp(0, items.length - 1);

    return copyWith(selectedIndex: newIndex, scrollOffset: newScroll);
  }

  /// Update filter and re-filter items.
  PopupState<T> setFilter(String newFilter, {int? cursor}) {
    final filteredItems = _filterItems(newFilter);
    return copyWith(
      filterText: newFilter,
      filterCursor: cursor ?? newFilter.length,
      items: filteredItems,
      selectedIndex: 0,
      scrollOffset: 0,
    );
  }

  /// Add character to filter at cursor position.
  PopupState<T> addFilterChar(String char) {
    final newText =
        filterText.substring(0, filterCursor) +
        char +
        filterText.substring(filterCursor);
    return setFilter(newText, cursor: filterCursor + char.length);
  }

  /// Remove character before cursor from filter.
  PopupState<T> removeFilterChar() {
    if (filterText.isEmpty || filterCursor == 0) return this;
    final newText =
        filterText.substring(0, filterCursor - 1) +
        filterText.substring(filterCursor);
    return setFilter(newText, cursor: filterCursor - 1);
  }

  /// Move filter cursor left.
  PopupState<T> moveFilterCursorLeft() {
    if (filterCursor == 0) return this;
    return copyWith(filterCursor: filterCursor - 1);
  }

  /// Move filter cursor right.
  PopupState<T> moveFilterCursorRight() {
    if (filterCursor >= filterText.length) return this;
    return copyWith(filterCursor: filterCursor + 1);
  }

  /// Move filter cursor to start.
  PopupState<T> moveFilterCursorToStart() {
    if (filterCursor == 0) return this;
    return copyWith(filterCursor: 0);
  }

  /// Move filter cursor to end.
  PopupState<T> moveFilterCursorToEnd() {
    if (filterCursor >= filterText.length) return this;
    return copyWith(filterCursor: filterText.length);
  }

  /// Filter items based on filter text.
  List<PopupItem<T>> _filterItems(String filter) {
    if (filter.isEmpty) return allItems;

    // Use custom filter if provided
    if (customFilter != null) {
      return customFilter!(allItems, filter);
    }

    // Default: case-insensitive substring match on label
    final lowerFilter = filter.toLowerCase();
    return allItems
        .where((item) => item.label.toLowerCase().contains(lowerFilter))
        .toList();
  }

  /// Refresh items (e.g., after directory change in file browser).
  PopupState<T> refreshItems(List<PopupItem<T>> newItems) {
    final filteredItems = filterText.isEmpty
        ? newItems
        : (customFilter != null
              ? customFilter!(newItems, filterText)
              : newItems
                    .where(
                      (item) => item.label.toLowerCase().contains(
                        filterText.toLowerCase(),
                      ),
                    )
                    .toList());
    return copyWith(
      allItems: newItems,
      items: filteredItems,
      selectedIndex: 0,
      scrollOffset: 0,
    );
  }
}
