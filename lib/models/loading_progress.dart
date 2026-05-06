/// Represents the progress state during app initialization.
///
/// Tracks multiple stages of loading:
/// - Stage 0 (0-20%): Initialize cache & prepare native bridge
/// - Stage 1 (20-50%): Fetch installed apps from native
/// - Stage 2 (50-75%): Enrich app data (risk analysis, privacy scores)
/// - Stage 3 (75-100%): Cache icons and finalize state
class LoadingProgress {
  /// Current stage (0-3)
  final int stage;

  /// Overall progress percentage (0-100)
  final int percentage;

  /// Human-readable status message
  final String message;

  /// Estimated time remaining (optional)
  final Duration? estimatedTime;

  /// Whether loading has completed
  final bool isComplete;

  const LoadingProgress({
    required this.stage,
    required this.percentage,
    required this.message,
    this.estimatedTime,
    this.isComplete = false,
  }) : assert(stage >= 0 && stage <= 3, 'Stage must be 0-3'),
       assert(percentage >= 0 && percentage <= 100, 'Percentage must be 0-100');

  /// Creates a LoadingProgress for the initial state
  const LoadingProgress.initial()
    : stage = 0,
      percentage = 0,
      message = 'Starting up...',
      estimatedTime = null,
      isComplete = false;

  /// Creates a LoadingProgress for the completed state
  const LoadingProgress.complete()
    : stage = 3,
      percentage = 100,
      message = 'Ready!',
      estimatedTime = null,
      isComplete = true;

  /// Creates a copy with modified fields
  LoadingProgress copyWith({
    int? stage,
    int? percentage,
    String? message,
    Duration? estimatedTime,
    bool? isComplete,
  }) {
    return LoadingProgress(
      stage: stage ?? this.stage,
      percentage: percentage ?? this.percentage,
      message: message ?? this.message,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  String toString() =>
      'LoadingProgress(stage: $stage, percentage: $percentage%, message: "$message")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingProgress &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          percentage == other.percentage &&
          message == other.message &&
          isComplete == other.isComplete;

  @override
  int get hashCode =>
      stage.hashCode ^
      percentage.hashCode ^
      message.hashCode ^
      isComplete.hashCode;
}
