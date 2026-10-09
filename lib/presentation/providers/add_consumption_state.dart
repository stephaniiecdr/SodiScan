import '../../domain/entities/daily_nutrition.dart';

enum LoadStatus { loading, success, empty, error }

class AddConsumptionState {
  const AddConsumptionState({
    this.loadStatus = LoadStatus.loading,
    this.summary,
    this.loadErrorMessage,
    this.isSubmitting = false,
    this.submitErrorMessage,
  });

  final LoadStatus loadStatus;
  final DailyNutrition? summary;
  final String? loadErrorMessage;
  final bool isSubmitting;
  final String? submitErrorMessage;

  AddConsumptionState copyWith({
    LoadStatus? loadStatus,
    DailyNutrition? summary,
    String? loadErrorMessage,
    bool? isSubmitting,
    String? submitErrorMessage,
    bool clearLoadError = false,
    bool clearSubmitError = false,
  }) {
    return AddConsumptionState(
      loadStatus: loadStatus ?? this.loadStatus,
      summary: summary ?? this.summary,
      loadErrorMessage: clearLoadError ? null : loadErrorMessage ?? this.loadErrorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitErrorMessage: clearSubmitError ? null : submitErrorMessage ?? this.submitErrorMessage,
    );
  }
}
