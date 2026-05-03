import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:manny_ui/config/ui_constants.dart';
import 'package:manny_ui/src/sheets/frosted_material_sheet.dart';

/// Reusable options menu component with consistent design.
///
/// Displays options in a bottom sheet with the iOS-style design language.
///
/// Example usage:
/// ```dart
/// OptionsMenu.show(
///   context: context,
///   title: 'Post Options',
///   options: [
///     MenuOption(
///       icon: IconlyBroken.bookmark,
///       label: 'Save post',
///       onTap: () => handleSave(),
///     ),
///     MenuOption(
///       icon: IconlyBroken.delete,
///       label: 'Delete post',
///       isDestructive: true,
///       onTap: () => handleDelete(),
///     ),
///   ],
/// );
/// ```
class OptionsMenu {
  /// Show options menu as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<MenuOption> options,
  }) {
    final theme = Theme.of(context);

    return showFrostedMaterialSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 24),

                // Title
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Options list
                ...options.map(
                  (option) => _buildOption(context, theme, option),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
      ),
    );
  }

  /// Build individual option item.
  static Widget _buildOption(
    BuildContext context,
    ThemeData theme,
    MenuOption option,
  ) {
    final Color iconColor = option.isDestructive
        ? Colors.red
        : (option.iconColor ?? theme.colorScheme.primary);

    final Color textColor = option.isDestructive
        ? Colors.red
        : (option.textColor ?? theme.textTheme.bodyLarge!.color!);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (option.dismissOnTap) {
            Navigator.pop(context);
          }
          option.onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(
              alpha: UIConstants.glassElementOpacity,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(option.icon, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle!,
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
              if (option.trailing != null) option.trailing!,
              if (option.trailing == null)
                Icon(
                  IconlyBold.arrow_right_2,
                  color: theme.iconTheme.color?.withValues(alpha: 0.4),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual menu option configuration.
class MenuOption {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool dismissOnTap;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;

  const MenuOption({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.dismissOnTap = true,
    this.iconColor,
    this.textColor,
    this.trailing,
  });
}
