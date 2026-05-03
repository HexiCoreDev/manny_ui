import 'package:flutter/material.dart';
import 'package:manny_ui/config/ui_constants.dart';
import 'package:manny_ui/src/sheets/frosted_material_sheet.dart';

/// Configuration for a filter group within the filter sheet.
///
/// Each filter group represents a section (e.g., "Sort By", "Category", "Tags")
/// with its own UI type and data.
class FilterGroup {
  /// Unique identifier for this filter group.
  final String id;

  /// Display label for the section header.
  final String label;

  /// Icon shown next to the section header.
  final IconData icon;

  /// The type of filter UI to render.
  final FilterGroupType type;

  /// Options for chip or pill filter types.
  final List<FilterOption>? options;

  /// Configuration for range slider type.
  final RangeFilterConfig? rangeConfig;

  /// Initial selected value(s).
  /// - For [FilterGroupType.chips]: a `String?` (selected option id)
  /// - For [FilterGroupType.pills]: a `String?` (selected option id)
  /// - For [FilterGroupType.rangeSlider]: a `RangeValues`
  final dynamic initialValue;

  const FilterGroup({
    required this.id,
    required this.label,
    required this.icon,
    required this.type,
    this.options,
    this.rangeConfig,
    this.initialValue,
  });
}

/// A single filter option within a chip or pill group.
class FilterOption {
  final String id;
  final String label;

  const FilterOption({required this.id, required this.label});
}

/// Configuration for a range slider filter.
class RangeFilterConfig {
  final double min;
  final double max;
  final int divisions;
  final String Function(double value)? labelFormatter;

  const RangeFilterConfig({
    required this.min,
    required this.max,
    this.divisions = 20,
    this.labelFormatter,
  });
}

/// Types of filter UI within a filter group.
enum FilterGroupType {
  /// Wrap of FilterChip widgets.
  chips,

  /// Horizontal scrolling pill buttons.
  pills,

  /// A RangeSlider for numeric ranges.
  rangeSlider,
}

/// Result of applying filters, keyed by filter group ID.
typedef FilterResults = Map<String, dynamic>;

/// A generic, configurable filter bottom sheet.
///
/// Provides a reusable filter UI pattern with configurable filter groups.
/// Use iconly icons when passing [FilterGroup.icon] for consistency.
///
/// Example usage:
/// ```dart
/// FilterSheet.show(
///   context: context,
///   title: 'Filter & Sort',
///   groups: [
///     FilterGroup(
///       id: 'sort',
///       label: 'Sort By',
///       icon: IconlyBroken.filter,
///       type: FilterGroupType.chips,
///       options: [
///         FilterOption(id: 'popular', label: 'Popularity'),
///         FilterOption(id: 'newest', label: 'Newest'),
///       ],
///     ),
///     FilterGroup(
///       id: 'price',
///       label: 'Price Range',
///       icon: IconlyBroken.wallet,
///       type: FilterGroupType.rangeSlider,
///       rangeConfig: RangeFilterConfig(min: 0, max: 1000),
///     ),
///   ],
///   onApply: (results) {
///     print('Sort: ${results["sort"]}');
///     print('Price: ${results["price"]}');
///   },
/// );
/// ```
class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.groups,
    required this.onApply,
    this.onReset,
    this.title = 'Filter & Sort',
    this.applyButtonText = 'Apply Filters',
    this.resetButtonText = 'Reset',
  });

  /// Filter groups to display.
  final List<FilterGroup> groups;

  /// Callback when filters are applied.
  final ValueChanged<FilterResults> onApply;

  /// Optional callback when filters are reset.
  final VoidCallback? onReset;

  /// Title shown in the header.
  final String title;

  /// Text for the apply button.
  final String applyButtonText;

  /// Text for the reset button.
  final String resetButtonText;

  /// Show filter sheet as modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required List<FilterGroup> groups,
    required ValueChanged<FilterResults> onApply,
    VoidCallback? onReset,
    String title = 'Filter & Sort',
    String applyButtonText = 'Apply Filters',
    String resetButtonText = 'Reset',
  }) {
    return showFrostedMaterialSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => FilterSheet(
        groups: groups,
        onApply: onApply,
        onReset: onReset,
        title: title,
        applyButtonText: applyButtonText,
        resetButtonText: resetButtonText,
      ),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Map<String, dynamic> _values;

  @override
  void initState() {
    super.initState();
    _values = {};
    for (final group in widget.groups) {
      if (group.initialValue != null) {
        _values[group.id] = group.initialValue;
      } else if (group.type == FilterGroupType.rangeSlider &&
          group.rangeConfig != null) {
        _values[group.id] = RangeValues(
          group.rangeConfig!.min,
          group.rangeConfig!.max,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < widget.groups.length; i++) ...[
                    _buildFilterGroup(theme, widget.groups[i]),
                    if (i < widget.groups.length - 1)
                      const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildBottomActions(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterGroup(ThemeData theme, FilterGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(group.icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              group.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter UI based on type
        switch (group.type) {
          FilterGroupType.chips => _buildChips(theme, group),
          FilterGroupType.pills => _buildPills(theme, group),
          FilterGroupType.rangeSlider => _buildRangeSlider(theme, group),
        },
      ],
    );
  }

  Widget _buildChips(ThemeData theme, FilterGroup group) {
    final selectedId = _values[group.id] as String?;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: (group.options ?? []).map((option) {
        final isSelected = selectedId == option.id;
        return FilterChip(
          label: Text(option.label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _values[group.id] = selected ? option.id : null;
            });
          },
          backgroundColor: theme.colorScheme.surface.withValues(
            alpha: UIConstants.glassElementOpacity,
          ),
          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          checkmarkColor: theme.colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? theme.colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPills(ThemeData theme, FilterGroup group) {
    final selectedId = _values[group.id] as String?;

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: group.options?.length ?? 0,
        itemBuilder: (context, index) {
          final option = group.options![index];
          final isSelected = selectedId == option.id;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _buildPill(theme, group, option, isSelected),
          );
        },
      ),
    );
  }

  Widget _buildPill(
    ThemeData theme,
    FilterGroup group,
    FilterOption option,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _values[group.id] = isSelected ? null : option.id;
        });
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: isSelected
              ? null
              : theme.colorScheme.surface.withValues(
                  alpha: UIConstants.glassElementOpacity,
                ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          option.label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : theme.textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSlider(ThemeData theme, FilterGroup group) {
    final config = group.rangeConfig;
    if (config == null) return const SizedBox.shrink();

    final range =
        _values[group.id] as RangeValues? ??
        RangeValues(config.min, config.max);

    final formatLabel = config.labelFormatter ?? (v) => v.round().toString();

    return Column(
      children: [
        RangeSlider(
          values: range,
          min: config.min,
          max: config.max,
          divisions: config.divisions,
          labels: RangeLabels(formatLabel(range.start), formatLabel(range.end)),
          onChanged: (values) {
            setState(() {
              _values[group.id] = values;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatLabel(range.start),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                formatLabel(range.end),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Reset Button
            Expanded(
              child: OutlinedButton(
                onPressed: _resetFilters,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: theme.colorScheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  widget.resetButtonText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Apply Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  widget.applyButtonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _values.clear();
      for (final group in widget.groups) {
        if (group.type == FilterGroupType.rangeSlider &&
            group.rangeConfig != null) {
          _values[group.id] = RangeValues(
            group.rangeConfig!.min,
            group.rangeConfig!.max,
          );
        }
      }
    });

    widget.onReset?.call();
    Navigator.pop(context);
  }

  void _applyFilters() {
    widget.onApply(_values);
    Navigator.pop(context);
  }
}
