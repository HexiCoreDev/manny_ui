import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:manny_ui/components/frosted_glass.dart';
import 'package:manny_ui/src/sheets/frosted_material_sheet.dart';

/// A generic, reusable search bottom sheet.
///
/// Strips all DMW-specific business logic and provides a clean search
/// pattern with configurable search callback, item builder, and optional
/// search history support.
///
/// Example usage:
/// ```dart
/// SearchSheet.show<Product>(
///   context: context,
///   hintText: 'Search products...',
///   onSearch: (query) async {
///     return await productService.search(query);
///   },
///   itemBuilder: (context, product) {
///     return ListTile(
///       title: Text(product.name),
///       subtitle: Text(product.price.toString()),
///     );
///   },
///   onItemSelected: (product) {
///     Navigator.push(context, ProductDetailPage(product));
///   },
/// );
/// ```
class SearchSheet<T> extends StatefulWidget {
  const SearchSheet({
    super.key,
    required this.onSearch,
    required this.itemBuilder,
    this.onItemSelected,
    this.hintText = 'Search...',
    this.emptyMessage = 'No results found',
    this.emptyIcon = IconlyBroken.search,
    this.idleMessage = 'Start typing to search',
    this.idleIcon = IconlyBroken.search,
    this.debounceMs = 300,
    this.searchHistory,
    this.onHistoryItemTapped,
    this.onDeleteHistoryItem,
    this.onClearHistory,
    this.autofocus = true,
  });

  /// Callback that performs the search and returns results.
  final Future<List<T>> Function(String query) onSearch;

  /// Builder for each result item.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Optional callback when an item is tapped.
  final ValueChanged<T>? onItemSelected;

  /// Placeholder text for the search field.
  final String hintText;

  /// Message shown when search returns no results.
  final String emptyMessage;

  /// Icon shown when search returns no results.
  final IconData emptyIcon;

  /// Message shown when user hasn't typed anything.
  final String idleMessage;

  /// Icon shown in idle state.
  final IconData idleIcon;

  /// Debounce duration in milliseconds.
  final int debounceMs;

  /// Optional list of recent search queries.
  final List<String>? searchHistory;

  /// Callback when a search history item is tapped.
  final ValueChanged<String>? onHistoryItemTapped;

  /// Callback to delete a single history item.
  final ValueChanged<String>? onDeleteHistoryItem;

  /// Callback to clear all history.
  final VoidCallback? onClearHistory;

  /// Whether to autofocus the search field.
  final bool autofocus;

  /// Show the search sheet as a full-height modal.
  static Future<void> show<T>({
    required BuildContext context,
    required Future<List<T>> Function(String query) onSearch,
    required Widget Function(BuildContext context, T item) itemBuilder,
    ValueChanged<T>? onItemSelected,
    String hintText = 'Search...',
    String emptyMessage = 'No results found',
    IconData emptyIcon = IconlyBroken.search,
    String idleMessage = 'Start typing to search',
    IconData idleIcon = IconlyBroken.search,
    int debounceMs = 300,
    List<String>? searchHistory,
    ValueChanged<String>? onHistoryItemTapped,
    ValueChanged<String>? onDeleteHistoryItem,
    VoidCallback? onClearHistory,
    bool autofocus = true,
  }) {
    return showFrostedMaterialSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
        child: SearchSheet<T>(
          onSearch: onSearch,
          itemBuilder: itemBuilder,
          onItemSelected: onItemSelected,
          hintText: hintText,
          emptyMessage: emptyMessage,
          emptyIcon: emptyIcon,
          idleMessage: idleMessage,
          idleIcon: idleIcon,
          debounceMs: debounceMs,
          searchHistory: searchHistory,
          onHistoryItemTapped: onHistoryItemTapped,
          onDeleteHistoryItem: onDeleteHistoryItem,
          onClearHistory: onClearHistory,
          autofocus: autofocus,
        ),
      ),
    );
  }

  @override
  State<SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<SearchSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  List<T> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    try {
      final results = await widget.onSearch(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
          _hasSearched = true;
        });
      }
    }
  }

  void _onHistoryTapped(String query) {
    _searchController.text = query;
    _onSearchChanged(query);
    widget.onHistoryItemTapped?.call(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FrostedGlass(
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.all(2),
              shadow: false,
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                  prefixIcon: Icon(IconlyBroken.search, color: theme.hintColor),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
              ),
            ),
          ),

          // Content
          Expanded(child: _buildContent(theme)),

          // Bottom padding for keyboard
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    // Show loading indicator.
    if (_isLoading) {
      return Center(
        child: CupertinoActivityIndicator(
          radius: 14,
          color: theme.colorScheme.primary,
        ),
      );
    }

    // Show results if searching.
    if (_searchController.text.isNotEmpty && _hasSearched) {
      if (_results.isEmpty) {
        return _buildEmptyState(theme);
      }
      return _buildResultsList(theme);
    }

    // Show search history if idle.
    if (_searchController.text.isEmpty) {
      return _buildHistoryOrIdle(theme);
    }

    return const SizedBox.shrink();
  }

  Widget _buildResultsList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return GestureDetector(
          onTap: () {
            widget.onItemSelected?.call(item);
          },
          child: widget.itemBuilder(context, item),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.emptyIcon,
            size: 48,
            color: theme.hintColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyMessage,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryOrIdle(ThemeData theme) {
    final history = widget.searchHistory;

    if (history == null || history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.idleIcon,
              size: 64,
              color: theme.hintColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              widget.idleMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.onClearHistory != null)
                TextButton(
                  onPressed: widget.onClearHistory,
                  child: Text(
                    'Clear All',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),

        // History list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                leading: Icon(IconlyBroken.time_circle, color: theme.hintColor),
                title: Text(item),
                trailing: widget.onDeleteHistoryItem != null
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: theme.hintColor,
                        ),
                        onPressed: () => widget.onDeleteHistoryItem!(item),
                      )
                    : null,
                onTap: () => _onHistoryTapped(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
