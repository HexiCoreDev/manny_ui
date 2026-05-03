import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:manny_ui/config/ui_constants.dart';
import 'package:manny_ui/src/sheets/frosted_material_sheet.dart';

/// Custom Dropdown Component.
///
/// Beautiful dropdown that follows the alert dialog design pattern.
/// Shows options in a bottom sheet with the app's design language.
///
/// Usage:
/// ```dart
/// final result = await CustomDropdown.show<String>(
///   context: context,
///   title: 'Sort By',
///   items: [
///     DropdownItem(value: 'recent', label: 'Recent'),
///     DropdownItem(value: 'oldest', label: 'Oldest'),
///     DropdownItem(value: 'popular', label: 'Popular'),
///   ],
///   currentValue: selectedSort,
/// );
/// ```
class CustomDropdown {
  /// Show dropdown as bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<DropdownItem<T>> items,
    T? currentValue,
    String? subtitle,
    bool showIcons = true,
  }) {
    return showFrostedMaterialSheet<T>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _CustomDropdownContent<T>(
        title: title,
        items: items,
        currentValue: currentValue,
        subtitle: subtitle,
        showIcons: showIcons,
      ),
    );
  }

  /// Show simple dropdown with string values.
  static Future<String?> showSimple({
    required BuildContext context,
    required String title,
    required List<String> options,
    String? currentValue,
    String? subtitle,
  }) {
    final items = options
        .map(
          (option) => DropdownItem<String>(
            value: option,
            label: option,
            icon: IconlyBroken.arrow_right_3,
          ),
        )
        .toList();

    return show<String>(
      context: context,
      title: title,
      items: items,
      currentValue: currentValue,
      subtitle: subtitle,
      showIcons: false,
    );
  }
}

/// Dropdown item model.
class DropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  const DropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconColor,
  });
}

/// Internal dropdown content widget.
class _CustomDropdownContent<T> extends StatelessWidget {
  final String title;
  final List<DropdownItem<T>> items;
  final T? currentValue;
  final String? subtitle;
  final bool showIcons;

  const _CustomDropdownContent({
    required this.title,
    required this.items,
    this.currentValue,
    this.subtitle,
    required this.showIcons,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Divider
          Divider(
            height: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),

          // Options List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item.value == currentValue;

                return _DropdownOptionTile<T>(
                  item: item,
                  isSelected: isSelected,
                  showIcon: showIcons,
                  onTap: () => Navigator.pop(context, item.value),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Dropdown option tile.
class _DropdownOptionTile<T> extends StatelessWidget {
  final DropdownItem<T> item;
  final bool isSelected;
  final bool showIcon;
  final VoidCallback onTap;

  const _DropdownOptionTile({
    required this.item,
    required this.isSelected,
    required this.showIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          border: isSelected
              ? Border(
                  left: BorderSide(color: theme.colorScheme.primary, width: 4),
                )
              : null,
        ),
        child: Row(
          children: [
            // Icon (if provided and showIcon is true)
            if (showIcon && item.icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surface.withValues(
                          alpha: UIConstants.glassElementOpacity,
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color:
                      item.iconColor ??
                      (isSelected
                          ? theme.colorScheme.primary
                          : theme.iconTheme.color),
                ),
              ),
              const SizedBox(width: 16),
            ],

            // Label and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Check mark if selected
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
