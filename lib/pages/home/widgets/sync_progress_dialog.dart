import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/sync/sync_progress_manager.dart';

/// Sync Progress Dialog
///
/// Shows real-time progress of multi-step sync operations
/// with detailed information for each step
class SyncProgressDialog extends StatefulWidget {
  final String title;
  final VoidCallback? onClose;

  const SyncProgressDialog({
    super.key,
    this.title = 'Syncing Data',
    this.onClose,
  });

  @override
  State<SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<SyncProgressDialog> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissal
      child: AlertDialog(
        title: Text(widget.title),
        content: Consumer<SyncProgressManager>(
          builder: (context, progressManager, _) {
            final steps = progressManager.steps;
            final overallProgress = progressManager.getOverallProgress();
            final completedCount = progressManager.getCompletedCount();
            final hasError = progressManager.hasFailed;
            final isComplete = progressManager.isComplete;

            return SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Overall progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Overall Progress',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              '$completedCount/${steps.length}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: overallProgress / 100,
                            minHeight: 6,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              hasError ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$overallProgress%',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Individual sync steps
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: steps.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final step = steps[index];
                        return _buildStepCard(context, step);
                      },
                    ),

                    // Error message if any
                    if (progressManager.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  progressManager.errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Completion message
                    if (isComplete && !hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '✅ All sync operations completed successfully!',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          Consumer<SyncProgressManager>(
            builder: (context, progressManager, _) {
              final isComplete = progressManager.isComplete;
              return TextButton(
                onPressed: isComplete
                    ? () {
                        Navigator.pop(context);
                        widget.onClose?.call();
                      }
                    : null,
                child: Text(isComplete ? 'Close' : 'Syncing...'),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build individual step card
  Widget _buildStepCard(BuildContext context, SyncStep step) {
    final statusColor = _getStatusColor(step.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Label + Status
          Row(
            children: [
              // Status indicator
              SizedBox(
                width: 24,
                height: 24,
                child: _buildStatusIndicator(step.status, statusColor),
              ),
              const SizedBox(width: 10),

              // Label and icon
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Item count (if available)
              if (step.itemCount != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${step.itemCount} items',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),

          // Message
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 34),
            child: Text(
              step.message,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),

          // Progress bar (if syncing or completed)
          if (step.progress != null && step.status != SyncStepStatus.waiting)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (step.progress ?? 0) / 100,
                      minHeight: 4,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${step.progress}%',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build status indicator widget
  Widget _buildStatusIndicator(
    SyncStepStatus status,
    Color color,
  ) {
    switch (status) {
      case SyncStepStatus.waiting:
        return Icon(
          Icons.schedule,
          size: 18,
          color: Colors.grey[400],
        );
      case SyncStepStatus.syncing:
        return SizedBox.expand(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      case SyncStepStatus.completed:
        return Icon(
          Icons.check_circle,
          size: 18,
          color: color,
        );
      case SyncStepStatus.failed:
        return Icon(
          Icons.error,
          size: 18,
          color: color,
        );
    }
  }

  /// Get color for status
  Color _getStatusColor(SyncStepStatus status) {
    switch (status) {
      case SyncStepStatus.waiting:
        return Colors.grey;
      case SyncStepStatus.syncing:
        return Colors.blue;
      case SyncStepStatus.completed:
        return Colors.green;
      case SyncStepStatus.failed:
        return Colors.red;
    }
  }
}
