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
typedef PopupSelectCallback = void Function(PopupItem item);

/// Callback when popup is cancelled.
typedef PopupCancelCallback = void Function();

/// Callback when filter text changes (for custom filtering).
typedef PopupFilterCallback =
    List<PopupItem> Function(List<PopupItem> items, String filter);

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

  /// Callback when an item is selected.
  final PopupSelectCallback? onSelect;

  /// Callback when an item is highlighted (selection changes).
  final PopupSelectCallback? onHighlight;

  /// Callback when popup is cancelled.
  final PopupCancelCallback? onCancel;

  /// Custom filter function (optional).
  final PopupFilterCallback? customFilter;

  /// Whether to show filter input.
  final bool showFilter;

  /// Maximum visible items (popup height).
  final int maxVisibleItems;

  const PopupState({
    required this.title,
    required this.allItems,
    required this.items,
    this.selectedIndex = 0,
    this.scrollOffset = 0,
    this.filterText = '',
    this.onSelect,
    this.onHighlight,
    this.onCancel,
    this.customFilter,
    this.showFilter = true,
    this.maxVisibleItems = 15,
  });

  /// Create initial popup state.
  factory PopupState.create({
    required String title,
    required List<PopupItem<T>> items,
    PopupSelectCallback? onSelect,
    PopupSelectCallback? onHighlight,
    PopupCancelCallback? onCancel,
    PopupFilterCallback? customFilter,
    bool showFilter = true,
    int maxVisibleItems = 15,
  }) {
    return PopupState<T>(
      title: title,
      allItems: items,
      items: items,
      selectedIndex: 0,
      scrollOffset: 0,
      filterText: '',
      onSelect: onSelect,
      onHighlight: onHighlight,
      onCancel: onCancel,
      customFilter: customFilter,
      showFilter: showFilter,
      maxVisibleItems: maxVisibleItems,
    );
  }

  /// Get currently selected item, or null if no items.
  PopupItem<T>? get selectedItem =>
      items.isNotEmpty && selectedIndex < items.length
      ? items[selectedIndex]
      : null;

  /// Create a copy with modified fields.
  PopupState<T> copyWith({
    String? title,
    List<PopupItem<T>>? allItems,
    List<PopupItem<T>>? items,
    int? selectedIndex,
    int? scrollOffset,
    String? filterText,
    PopupSelectCallback? onSelect,
    PopupSelectCallback? onHighlight,
    PopupCancelCallback? onCancel,
    PopupFilterCallback? customFilter,
    bool? showFilter,
    int? maxVisibleItems,
  }) {
    return PopupState<T>(
      title: title ?? this.title,
      allItems: allItems ?? this.allItems,
      items: items ?? this.items,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      filterText: filterText ?? this.filterText,
      onSelect: onSelect ?? this.onSelect,
      onHighlight: onHighlight ?? this.onHighlight,
      onCancel: onCancel ?? this.onCancel,
      customFilter: customFilter ?? this.customFilter,
      showFilter: showFilter ?? this.showFilter,
      maxVisibleItems: maxVisibleItems ?? this.maxVisibleItems,
    );
  }

  /// Move selection down.
  PopupState<T> moveDown() {
    if (items.isEmpty) return this;
    final newIndex = (selectedIndex + 1).clamp(0, items.length - 1);
    var newScroll = scrollOffset;
    // Scroll down if selection goes below visible area
    if (newIndex >= scrollOffset + maxVisibleItems) {
      newScroll = newIndex - maxVisibleItems + 1;
    }
    return copyWith(selectedIndex: newIndex, scrollOffset: newScroll);
  }

  /// Move selection up.
  PopupState<T> moveUp() {
    if (items.isEmpty) return this;
    final newIndex = (selectedIndex - 1).clamp(0, items.length - 1);
    var newScroll = scrollOffset;
    // Scroll up if selection goes above visible area
    if (newIndex < scrollOffset) {
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

  /// Update filter and re-filter items.
  PopupState<T> setFilter(String newFilter) {
    final filteredItems = _filterItems(newFilter);
    return copyWith(
      filterText: newFilter,
      items: filteredItems,
      selectedIndex: 0,
      scrollOffset: 0,
    );
  }

  /// Add character to filter.
  PopupState<T> addFilterChar(String char) {
    return setFilter(filterText + char);
  }

  /// Remove last character from filter.
  PopupState<T> removeFilterChar() {
    if (filterText.isEmpty) return this;
    return setFilter(filterText.substring(0, filterText.length - 1));
  }

  /// Filter items based on filter text.
  List<PopupItem<T>> _filterItems(String filter) {
    if (filter.isEmpty) return allItems;

    // Use custom filter if provided
    if (customFilter != null) {
      final result = customFilter!(allItems.cast<PopupItem>(), filter);
      return result.cast<PopupItem<T>>();
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
              ? customFilter!(
                  newItems.cast<PopupItem>(),
                  filterText,
                ).cast<PopupItem<T>>()
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
