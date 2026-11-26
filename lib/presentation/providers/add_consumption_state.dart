import '../../domain/entities/daily_nutrition.dart';

enum LoadStatus { loading, success, empty, error }

class AddConsumptionState {
  const AddConsumptionState({
    this.loadStatus = LoadStatus.loading,
    this.summary,
    this.loadErrorMessage,
    this.isSubmitting = false,
    this.submitErrorMessage,
    this.deletingId,
    this.deleteErrorMessage,
  });

  final LoadStatus loadStatus;
  final DailyNutrition? summary;
  final String? loadErrorMessage;
  final bool isSubmitting;
  final String? submitErrorMessage;
  final String? deletingId;
  final String? deleteErrorMessage;

  bool get isDeleting => deletingId != null;

  AddConsumptionState copyWith({
    LoadStatus? loadStatus,
    DailyNutrition? summary,
    String? loadErrorMessage,
    bool? isSubmitting,
    String? submitErrorMessage,
    String? deletingId,
    String? deleteErrorMessage,
    bool clearLoadError = false,
    bool clearSubmitError = false,
    bool clearDeleting = false,
    bool clearDeleteError = false,
  }) {
    return AddConsumptionState(
      loadStatus: loadStatus ?? this.loadStatus,
      summary: summary ?? this.summary,
      loadErrorMessage: clearLoadError ? null : loadErrorMessage ?? this.loadErrorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitErrorMessage: clearSubmitError ? null : submitErrorMessage ?? this.submitErrorMessage,
      deletingId: clearDeleting ? null : deletingId ?? this.deletingId,
      deleteErrorMessage: clearDeleteError ? null : deleteErrorMessage ?? this.deleteErrorMessage,
    );
  }
}
