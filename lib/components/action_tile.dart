import 'package:flutter/material.dart';

/// A simple action list tile with icon, title, and tap handler.
///
/// Supports destructive styling for dangerous actions.
///
/// Example usage:
/// ```dart
/// ActionTile(
///   icon: Icons.delete,
///   title: 'Delete Item',
///   isDestructive: true,
///   onTap: () => handleDelete(),
/// )
/// ```
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDestructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDestructive
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
