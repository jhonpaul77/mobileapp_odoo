import 'package:flutter/foundation.dart';

/// Represents a single sync step
class SyncStep {
  final String id;
  final String label;
  final String icon;
  SyncStepStatus status;
  String message;
  int? progress; // 0-100
  int? itemCount;

  SyncStep({
    required this.id,
    required this.label,
    required this.icon,
    this.status = SyncStepStatus.waiting,
    this.message = 'Waiting...',
    this.progress,
    this.itemCount,
  });

  /// Create a copy with updated fields
  SyncStep copyWith({
    SyncStepStatus? status,
    String? message,
    int? progress,
    int? itemCount,
  }) {
    return SyncStep(
      id: id,
      label: label,
      icon: icon,
      status: status ?? this.status,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      itemCount: itemCount ?? this.itemCount,
    );
  }
}

/// Status of a sync step
enum SyncStepStatus {
  waiting,
  syncing,
  completed,
  failed,
}

/// Manages overall sync progress and communicates with UI
class SyncProgressManager extends ChangeNotifier {
  final List<SyncStep> steps = [];
  bool _isComplete = false;
  String? _errorMessage;

  /// Initialize with a list of steps
  void initialize(List<SyncStep> initialSteps) {
    steps.clear();
    steps.addAll(initialSteps);
    _isComplete = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Update a specific step's status
  void updateStep(
    String stepId, {
    SyncStepStatus? status,
    String? message,
    int? progress,
    int? itemCount,
  }) {
    final index = steps.indexWhere((s) => s.id == stepId);
    if (index != -1) {
      steps[index] = steps[index].copyWith(
        status: status,
        message: message,
        progress: progress,
        itemCount: itemCount,
      );
      notifyListeners();
    }
  }

  /// Mark step as syncing
  void startStep(String stepId, {String? message}) {
    updateStep(
      stepId,
      status: SyncStepStatus.syncing,
      message: message ?? 'Syncing...',
      progress: 0,
    );
  }

  /// Mark step as completed
  void completeStep(String stepId, {String? message, int? itemCount}) {
    updateStep(
      stepId,
      status: SyncStepStatus.completed,
      message: message ?? 'Completed',
      progress: 100,
      itemCount: itemCount,
    );
  }

  /// Mark step as failed
  void failStep(String stepId, {String? message}) {
    updateStep(
      stepId,
      status: SyncStepStatus.failed,
      message: message ?? 'Failed',
      progress: 0,
    );
  }

  /// Update progress for current step
  void updateProgress(String stepId, int progress) {
    updateStep(stepId, progress: progress.clamp(0, 100));
  }

  /// Mark entire sync as complete
  void markComplete() {
    _isComplete = true;
    notifyListeners();
  }

  /// Mark entire sync as failed
  void markFailed(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Get overall progress (0-100)
  int getOverallProgress() {
    if (steps.isEmpty) return 0;
    final totalProgress = steps.fold<int>(
      0,
      (sum, step) {
        if (step.status == SyncStepStatus.completed) return sum + 100;
        return sum + (step.progress ?? 0);
      },
    );
    return (totalProgress / (steps.length * 100) * 100).toInt();
  }

  /// Get count of completed steps
  int getCompletedCount() {
    return steps.where((s) => s.status == SyncStepStatus.completed).length;
  }

  /// Check if sync is complete
  bool get isComplete => _isComplete;

  /// Get error message if any
  String? get errorMessage => _errorMessage;

  /// Check if any step failed
  bool get hasFailed => steps.any((s) => s.status == SyncStepStatus.failed);

  /// Reset everything
  void reset() {
    steps.clear();
    _isComplete = false;
    _errorMessage = null;
    notifyListeners();
  }
}
