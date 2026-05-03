import 'package:flutter/material.dart';
import 'package:manny_ui/components/frosted_glass.dart';
import 'package:manny_ui/src/sheets/frosted_material_sheet.dart';

/// Reusable alert dialog component for confirmation actions.
/// Displays as an iOS-style bottom sheet with rounded corners,
/// drag handle, and configurable action buttons.
///
/// Example usage:
/// ```dart
/// AppAlertDialog.show(
///   context: context,
///   title: 'Delete Node?',
///   message: 'This action cannot be undone.',
///   actionText: 'Delete',
///   actionColor: Colors.red,
///   onActionPressed: () {
///     // Handle deletion
///   },
/// );
/// ```
class AppAlertDialog {
  /// Show a confirmation dialog with customizable title, message, and action.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onActionPressed,
    Color? actionColor,
    Color? titleColor,
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) {
    final theme = Theme.of(context);
    final effectiveActionColor =
        actionColor ?? (isDangerous ? Colors.red : theme.colorScheme.primary);
    final effectiveTitleColor =
        titleColor ??
        (isDangerous ? Colors.red : theme.textTheme.titleLarge?.color);

    return showFrostedMaterialSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => _AlertDialogContent(
        title: title,
        message: message,
        actionText: actionText,
        actionColor: effectiveActionColor,
        titleColor: effectiveTitleColor,
        cancelText: cancelText,
        onActionPressed: onActionPressed,
        theme: theme,
      ),
    );
  }

  /// Show a dangerous action confirmation (red title and action button).
  static Future<void> showDanger({
    required BuildContext context,
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onActionPressed,
    String cancelText = 'Cancel',
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      actionText: actionText,
      onActionPressed: onActionPressed,
      cancelText: cancelText,
      isDangerous: true,
    );
  }

  /// Show a dialog with text input field.
  /// Returns the input value via callback when action is pressed.
  ///
  /// Example usage:
  /// ```dart
  /// AppAlertDialog.showWithInput(
  ///   context: context,
  ///   title: 'Rename Node',
  ///   message: 'Enter a new name for this node.',
  ///   hintText: 'Enter node name...',
  ///   actionText: 'Rename',
  ///   validator: (value) => value.isEmpty ? 'Name is required' : null,
  ///   onActionPressed: (name) {
  ///     // Handle rename
  ///   },
  /// );
  /// ```
  static Future<void> showWithInput({
    required BuildContext context,
    required String title,
    required String message,
    required String actionText,
    required void Function(String value) onActionPressed,
    String? hintText,
    String? initialValue,
    String? Function(String value)? validator,
    bool multiLine = false,
    int maxLines = 4,
    Color? actionColor,
    Color? titleColor,
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) {
    final theme = Theme.of(context);
    final effectiveActionColor =
        actionColor ?? (isDangerous ? Colors.red : theme.colorScheme.primary);
    final effectiveTitleColor =
        titleColor ??
        (isDangerous ? Colors.red : theme.textTheme.titleLarge?.color);

    return showFrostedMaterialSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => _AlertDialogWithInputContent(
        title: title,
        message: message,
        actionText: actionText,
        actionColor: effectiveActionColor,
        titleColor: effectiveTitleColor,
        cancelText: cancelText,
        hintText: hintText,
        initialValue: initialValue,
        validator: validator,
        multiLine: multiLine,
        maxLines: maxLines,
        onActionPressed: onActionPressed,
        theme: theme,
      ),
    );
  }

  /// Show an informational alert (just OK button).
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String okText = 'OK',
  }) {
    final theme = Theme.of(context);

    return showFrostedMaterialSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => Container(
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
              const SizedBox(height: 16),

              // Message
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // OK Button
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      okText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
    );
  }
}

/// Internal widget for alert dialog content.
class _AlertDialogContent extends StatelessWidget {
  final String title;
  final String message;
  final String actionText;
  final String cancelText;
  final Color actionColor;
  final Color? titleColor;
  final VoidCallback onActionPressed;
  final ThemeData theme;

  const _AlertDialogContent({
    required this.title,
    required this.message,
    required this.actionText,
    required this.cancelText,
    required this.actionColor,
    required this.titleColor,
    required this.onActionPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),

          // Message
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              // Cancel Button
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        cancelText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Action Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onActionPressed();
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: actionColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        actionText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Internal stateful widget for alert dialog with text input.
class _AlertDialogWithInputContent extends StatefulWidget {
  final String title;
  final String message;
  final String actionText;
  final String cancelText;
  final Color actionColor;
  final Color? titleColor;
  final String? hintText;
  final String? initialValue;
  final String? Function(String value)? validator;
  final bool multiLine;
  final int maxLines;
  final void Function(String value) onActionPressed;
  final ThemeData theme;

  const _AlertDialogWithInputContent({
    required this.title,
    required this.message,
    required this.actionText,
    required this.cancelText,
    required this.actionColor,
    required this.titleColor,
    required this.hintText,
    required this.initialValue,
    required this.validator,
    required this.multiLine,
    required this.maxLines,
    required this.onActionPressed,
    required this.theme,
  });

  @override
  State<_AlertDialogWithInputContent> createState() =>
      _AlertDialogWithInputContentState();
}

class _AlertDialogWithInputContentState
    extends State<_AlertDialogWithInputContent> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAction() {
    final value = _controller.text.trim();

    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != null) {
        setState(() => _errorText = error);
        return;
      }
    }

    Navigator.pop(context);
    widget.onActionPressed(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.theme.colorScheme.onSurface.withValues(
                  alpha: 0.2,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              widget.title,
              style: widget.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.titleColor,
              ),
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              widget.message,
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                color: widget.theme.colorScheme.onSurface.withValues(
                  alpha: 0.7,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Text Input Field
            FrostedGlass(
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.all(2),
              shadow: false,
              child: TextField(
                controller: _controller,
                maxLines: widget.multiLine ? widget.maxLines : 1,
                minLines: widget.multiLine ? 2 : 1,
                textInputAction: widget.multiLine
                    ? TextInputAction.newline
                    : TextInputAction.done,
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  errorText: _errorText,
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: widget.theme.colorScheme.surface.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          widget.cancelText,
                          style: widget.theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Action Button
                Expanded(
                  child: InkWell(
                    onTap: _handleAction,
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: widget.actionColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          widget.actionText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
