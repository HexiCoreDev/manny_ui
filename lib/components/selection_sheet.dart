import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:manny_ui/components/frosted_glass.dart';
import 'package:manny_ui/src/sheets/frosted_material_sheet.dart';

/// Theme data for customizing the selection sheet appearance.
class SelectionSheetThemeData {
  /// The bottom sheet's background color.
  final Color? backgroundColor;

  /// The style to use for item label text.
  final TextStyle? textStyle;

  /// The style to use for search box text.
  final TextStyle? searchTextStyle;

  /// The decoration used for the search field.
  final InputDecoration? inputDecoration;

  /// The border radius of the bottom sheet.
  final BorderRadius? borderRadius;

  /// Bottom sheet height. By default it's 70% of screen height.
  final double? bottomSheetHeight;

  /// The padding of the bottom sheet content.
  final EdgeInsets? padding;

  /// The margin of the bottom sheet.
  final EdgeInsets? margin;

  const SelectionSheetThemeData({
    this.backgroundColor,
    this.textStyle,
    this.searchTextStyle,
    this.inputDecoration,
    this.borderRadius,
    this.bottomSheetHeight,
    this.padding,
    this.margin,
  });
}

/// Generic selection item for the selection sheet.
class SelectionItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;

  const SelectionItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.leading,
  });
}

/// A reusable generic selection sheet component.
///
/// Shows a modal bottom sheet with search and list of selectable items.
///
/// Example usage:
/// ```dart
/// SelectionSheet.show<String>(
///   context: context,
///   items: [
///     SelectionItem(value: 'us', label: 'United States'),
///     SelectionItem(value: 'uk', label: 'United Kingdom'),
///   ],
///   title: 'Select Country',
///   onSelect: (value) => print('Selected: $value'),
/// );
/// ```
class SelectionSheet<T> extends StatefulWidget {
  const SelectionSheet({
    super.key,
    required this.items,
    required this.onSelect,
    this.title,
    this.selectedValue,
    this.searchHint = 'Search',
    this.emptyMessage = 'No items found',
    this.showSearch = true,
    this.searchAutofocus = false,
    this.favorites,
    this.theme,
    this.sortAlphabetically = true,
  });

  /// List of items to display.
  final List<SelectionItem<T>> items;

  /// Callback when an item is selected.
  final ValueChanged<T> onSelect;

  /// Optional title shown at top.
  final String? title;

  /// Currently selected value (for highlighting).
  final T? selectedValue;

  /// Hint text for search field.
  final String searchHint;

  /// Message shown when no items match search.
  final String emptyMessage;

  /// Whether to show the search field.
  final bool showSearch;

  /// Whether to autofocus the search field.
  final bool searchAutofocus;

  /// List of favorite item values to show at top with divider.
  final List<T>? favorites;

  /// Theme customization.
  final SelectionSheetThemeData? theme;

  /// Whether to sort items alphabetically by label.
  final bool sortAlphabetically;

  /// Show the selection sheet and return the selected item.
  static Future<T?> show<T>({
    required BuildContext context,
    required List<SelectionItem<T>> items,
    required ValueChanged<T> onSelect,
    String? title,
    T? selectedValue,
    String searchHint = 'Search',
    String emptyMessage = 'No items found',
    bool showSearch = true,
    bool searchAutofocus = false,
    List<T>? favorites,
    SelectionSheetThemeData? theme,
    bool sortAlphabetically = true,
  }) {
    return showFrostedMaterialSheet<T>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SelectionSheet<T>(
        items: items,
        onSelect: onSelect,
        title: title,
        selectedValue: selectedValue,
        searchHint: searchHint,
        emptyMessage: emptyMessage,
        showSearch: showSearch,
        searchAutofocus: searchAutofocus,
        favorites: favorites,
        theme: theme,
        sortAlphabetically: sortAlphabetically,
      ),
    );
  }

  @override
  State<SelectionSheet<T>> createState() => _SelectionSheetState<T>();
}

class _SelectionSheetState<T> extends State<SelectionSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  late List<SelectionItem<T>> _allItems;
  late List<SelectionItem<T>> _filteredItems;
  List<SelectionItem<T>>? _favoriteItems;

  @override
  void initState() {
    super.initState();
    _initializeItems();
  }

  void _initializeItems() {
    _allItems = List.from(widget.items);
    if (widget.sortAlphabetically) {
      _allItems.sort(
        (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );
    }

    if (widget.favorites != null && widget.favorites!.isNotEmpty) {
      _favoriteItems = _allItems
          .where((item) => widget.favorites!.contains(item.value))
          .toList();
    }

    _filteredItems = List.from(_allItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSearchResults(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(_allItems);
      } else {
        final lowercaseQuery = query.toLowerCase();
        _filteredItems = _allItems.where((item) {
          return item.label.toLowerCase().contains(lowercaseQuery) ||
              (item.subtitle?.toLowerCase().contains(lowercaseQuery) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final deviceHeight = mediaQuery.size.height;

    final height = widget.theme?.bottomSheetHeight ?? deviceHeight * 0.7;

    Widget content = Column(
      children: [
        const SizedBox(height: 12),

        // Search field
        if (widget.showSearch) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: FrostedGlass(
              borderRadius: BorderRadius.circular(15),
              padding: const EdgeInsets.all(2),
              shadow: false,
              child: TextField(
                autofocus: widget.searchAutofocus,
                controller: _searchController,
                style: widget.theme?.searchTextStyle ?? _defaultTextStyle,
                decoration:
                    widget.theme?.inputDecoration ??
                    InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(IconlyBroken.search),
                      filled: false,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                onChanged: _filterSearchResults,
              ),
            ),
          ),
        ],

        // List of items
        Expanded(
          child: _filteredItems.isEmpty
              ? _buildEmptyState(themeData)
              : ListView(
                  children: [
                    // Favorite items at top
                    if (_favoriteItems != null &&
                        _favoriteItems!.isNotEmpty &&
                        _searchController.text.isEmpty) ...[
                      ..._favoriteItems!.map(
                        (item) => _buildListItem(themeData, item),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Divider(thickness: 1),
                      ),
                    ],
                    // Regular items
                    ..._filteredItems.map(
                      (item) => _buildListItem(themeData, item),
                    ),
                    // Bottom padding for safe area
                    SizedBox(height: mediaQuery.padding.bottom + 16),
                  ],
                ),
        ),
      ],
    );

    final padding = widget.theme?.padding;
    if (padding != null) {
      content = Padding(padding: padding, child: content);
    }

    return SizedBox(height: height, child: content);
  }

  Widget _buildListItem(ThemeData themeData, SelectionItem<T> item) {
    final isSelected = widget.selectedValue == item.value;
    final textStyle = widget.theme?.textStyle ?? _defaultTextStyle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onSelect(item.value);
          Navigator.pop(context, item.value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
          child: Row(
            children: [
              // Leading widget or icon
              if (item.leading != null) ...[
                item.leading!,
                const SizedBox(width: 15),
              ] else if (item.icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (item.iconColor ?? themeData.colorScheme.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.iconColor ?? themeData.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 15),
              ],

              // Label and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: textStyle.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? themeData.colorScheme.primary
                            : themeData.colorScheme.onSurface,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: themeData.textTheme.bodySmall?.copyWith(
                          color: themeData.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Selected checkmark
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: themeData.colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData themeData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconlyBroken.search,
              size: 48,
              color: themeData.hintColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage,
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _defaultTextStyle => const TextStyle(fontSize: 16);
}

/// A tappable field widget that looks like a form field but opens a selection sheet.
///
/// Example usage:
/// ```dart
/// SelectionField<String>(
///   label: 'Country',
///   hint: 'Select a country',
///   icon: Icons.flag,
///   items: countryItems,
///   value: selectedCountry,
///   displayText: selectedCountryName,
///   onSelected: (value) => setState(() => selectedCountry = value),
/// )
/// ```
class SelectionField<T> extends StatelessWidget {
  const SelectionField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onSelected,
    this.value,
    this.displayText,
    this.sheetTitle,
    this.searchHint,
    this.favorites,
    this.sortAlphabetically = true,
  });

  final String label;
  final String hint;
  final IconData icon;
  final List<SelectionItem<T>> items;
  final void Function(T? value) onSelected;
  final T? value;
  final String? displayText;
  final String? sheetTitle;
  final String? searchHint;
  final List<T>? favorites;
  final bool sortAlphabetically;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null && displayText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            await SelectionSheet.show<T>(
              context: context,
              items: items,
              title: sheetTitle ?? label,
              selectedValue: value,
              searchHint: searchHint ?? 'Search...',
              favorites: favorites,
              sortAlphabetically: sortAlphabetically,
              onSelect: (selectedValue) {
                onSelected(selectedValue);
              },
            );
          },
          child: FrostedGlass(
            borderRadius: BorderRadius.circular(15),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasValue ? displayText! : hint,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: hasValue
                          ? FontWeight.w500
                          : FontWeight.normal,
                      color: hasValue
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
