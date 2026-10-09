import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/daily_nutrition.dart';
import '../../domain/usecases/get_daily_summary.dart';
import '../../domain/usecases/record_consumption.dart';
import 'add_consumption_state.dart';

class AddConsumptionNotifier extends ChangeNotifier {
  AddConsumptionNotifier({
    required GetDailySummary getDailySummary,
    required RecordConsumption recordConsumption,
    DateTime Function()? clock,
  })  : _getDailySummary = getDailySummary,
        _recordConsumption = recordConsumption,
        _clock = clock ?? DateTime.now;

  static const String loadErrorText = 'Data tidak dapat dimuat.';
  static const String submitErrorText = 'Konsumsi gagal disimpan. Silakan coba lagi.';

  final GetDailySummary _getDailySummary;
  final RecordConsumption _recordConsumption;
  final DateTime Function() _clock;

  AddConsumptionState _state = const AddConsumptionState();
  bool _isDisposed = false;

  AddConsumptionState get state => _state;

  Future<void> load() async {
    _emit(_state.copyWith(loadStatus: LoadStatus.loading, clearLoadError: true));
    await _fetchSummary();
  }

  Future<void> retry() => load();

  Future<void> refresh() => _fetchSummary();

  Future<bool> submit({required String productName, required double sodiumMg}) async {
    if (_state.isSubmitting) return false;
    _emit(_state.copyWith(isSubmitting: true, clearSubmitError: true));

    try {
      await _recordConsumption(productName: productName, sodiumMg: sodiumMg);
    } on ValidationFailure catch (failure) {
      _emit(_state.copyWith(isSubmitting: false, submitErrorMessage: failure.message));
      return false;
    } on Exception {
      _emit(_state.copyWith(isSubmitting: false, submitErrorMessage: submitErrorText));
      return false;
    }

    _emit(_state.copyWith(isSubmitting: false));
    await _fetchSummary();
    return true;
  }

  Future<void> _fetchSummary() async {
    try {
      final summary = await _getDailySummary(_clock());
      _emit(_state.copyWith(loadStatus: _statusFor(summary), summary: summary, clearLoadError: true));
    } on Exception {
      _emit(_state.copyWith(loadStatus: LoadStatus.error, loadErrorMessage: loadErrorText));
    }
  }

  LoadStatus _statusFor(DailyNutrition summary) {
    return summary.consumptions.isEmpty ? LoadStatus.empty : LoadStatus.success;
  }

  void _emit(AddConsumptionState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
