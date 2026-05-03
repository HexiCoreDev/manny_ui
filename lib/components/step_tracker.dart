import 'package:flutter/material.dart';

/// Status of a step in the tracker.
enum StepStatus {
  /// Step has not been reached yet.
  pending,

  /// Step is currently active/in progress.
  active,

  /// Step has been completed.
  completed,

  /// Step was skipped or failed.
  failed,
}

/// A single step configuration for the [StepTracker].
class TrackerStep {
  /// Display label for this step.
  final String label;

  /// Description text shown below the label.
  final String description;

  /// Icon for this step. Use iconly icons for consistency (e.g., IconlyBroken.time_circle).
  final IconData icon;

  /// Current status of this step.
  final StepStatus status;

  /// Color override for this step. If null, derived from status.
  final Color? color;

  /// Optional timestamp string to display.
  final String? timestamp;

  /// Optional additional notes.
  final String? notes;

  const TrackerStep({
    required this.label,
    required this.description,
    required this.icon,
    this.status = StepStatus.pending,
    this.color,
    this.timestamp,
    this.notes,
  });
}

/// A generic timeline/stepper widget that visualizes a sequence of steps.
///
/// Ported from DMW's DeliveryTracker but made fully generic. Supports
/// both compact (progress bar) and full (timeline) modes.
///
/// Example usage:
/// ```dart
/// StepTracker(
///   steps: [
///     TrackerStep(
///       label: 'Initiated',
///       description: 'Task has been created',
///       icon: IconlyBroken.time_circle,
///       status: StepStatus.completed,
///     ),
///     TrackerStep(
///       label: 'Processing',
///       description: 'Task is being executed',
///       icon: IconlyBroken.document,
///       status: StepStatus.active,
///     ),
///     TrackerStep(
///       label: 'Done',
///       description: 'Task completed successfully',
///       icon: IconlyBroken.shield_done,
///       status: StepStatus.pending,
///     ),
///   ],
/// )
/// ```
class StepTracker extends StatelessWidget {
  /// The list of steps to display.
  final List<TrackerStep> steps;

  /// Whether to show compact (progress bar) view instead of full timeline.
  final bool isCompact;

  /// Optional label shown alongside the compact progress bar.
  final String? compactLabel;

  /// Optional info widget shown below the active step (e.g., estimated time).
  final Widget? activeStepInfo;

  const StepTracker({
    super.key,
    required this.steps,
    this.isCompact = false,
    this.compactLabel,
    this.activeStepInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCompact) {
      return _buildCompactTracker(theme);
    }

    return _buildFullTracker(theme);
  }

  Color _getStatusColor(StepStatus status) {
    switch (status) {
      case StepStatus.pending:
        return Colors.grey;
      case StepStatus.active:
        return Colors.blue;
      case StepStatus.completed:
        return Colors.green;
      case StepStatus.failed:
        return Colors.red;
    }
  }

  Widget _buildCompactTracker(ThemeData theme) {
    final activeIndex = steps.indexWhere((s) => s.status == StepStatus.active);
    final completedCount = steps
        .where((s) => s.status == StepStatus.completed)
        .length;
    final progress = steps.isNotEmpty
        ? (completedCount + (activeIndex >= 0 ? 0.5 : 0)) / steps.length
        : 0.0;

    final activeStep = activeIndex >= 0 ? steps[activeIndex] : steps.last;
    final activeColor = activeStep.color ?? _getStatusColor(activeStep.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                compactLabel ?? activeStep.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                ),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(activeColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          activeStep.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFullTracker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(steps.length, (index) {
          final step = steps[index];
          final isLast = index == steps.length - 1;

          return _buildTimelineItem(theme, step, isLast: isLast, index: index);
        }),
      ],
    );
  }

  Widget _buildTimelineItem(
    ThemeData theme,
    TrackerStep step, {
    required bool isLast,
    required int index,
  }) {
    final isCompleted = step.status == StepStatus.completed;
    final isActive = step.status == StepStatus.active;
    final isFailed = step.status == StepStatus.failed;
    final color =
        step.color ??
        (isCompleted || isActive || isFailed
            ? _getStatusColor(step.status)
            : theme.colorScheme.onSurface.withValues(alpha: 0.3));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? color.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: isActive ? 3 : 2),
              ),
              child: Icon(step.icon, size: 20, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color,
                      isCompleted
                          ? color
                          : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isCompleted || isActive
                              ? color
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                      ),
                    ),
                    if (step.timestamp != null)
                      Text(
                        step.timestamp!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  step.notes ?? step.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
                if (isActive && activeStepInfo != null) ...[
                  const SizedBox(height: 8),
                  activeStepInfo!,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
