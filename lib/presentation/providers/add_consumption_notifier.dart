import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/daily_nutrition.dart';
import '../../domain/entities/food_consumption.dart';
import '../../domain/usecases/delete_consumption.dart';
import '../../domain/usecases/get_daily_summary.dart';
import '../../domain/usecases/record_consumption.dart';
import '../../domain/usecases/send_sodium_alert.dart';
import '../../domain/usecases/update_consumption.dart';
import 'add_consumption_state.dart';

class AddConsumptionNotifier extends ChangeNotifier {
  AddConsumptionNotifier({
    required GetDailySummary getDailySummary,
    required RecordConsumption recordConsumption,
    required UpdateConsumption updateConsumption,
    required DeleteConsumption deleteConsumption,
    SendSodiumAlert? sendSodiumAlert,
    DateTime Function()? clock,
  })  : _getDailySummary = getDailySummary,
        _recordConsumption = recordConsumption,
        _updateConsumption = updateConsumption,
        _deleteConsumption = deleteConsumption,
        _sendSodiumAlert = sendSodiumAlert,
        _clock = clock ?? DateTime.now;

  static const String loadErrorText = 'Data tidak dapat dimuat.';
  static const String submitErrorText = 'Konsumsi gagal disimpan. Silakan coba lagi.';
  static const String updateErrorText = 'Perubahan gagal disimpan. Silakan coba lagi.';
  static const String deleteErrorText = 'Konsumsi gagal dihapus. Silakan coba lagi.';

  final GetDailySummary _getDailySummary;
  final RecordConsumption _recordConsumption;
  final UpdateConsumption _updateConsumption;
  final DeleteConsumption _deleteConsumption;
  final SendSodiumAlert? _sendSodiumAlert;
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

  Future<bool> submit({required String productName, required double sodiumMg}) {
    return _write(
      () => _recordConsumption(productName: productName, sodiumMg: sodiumMg),
      errorText: submitErrorText,
    );
  }

  Future<bool> update(FoodConsumption original, {required String productName, required double sodiumMg}) {
    return _write(
      () => _updateConsumption(original, productName: productName, sodiumMg: sodiumMg),
      errorText: updateErrorText,
    );
  }

  void clearSubmitError() => _emit(_state.copyWith(clearSubmitError: true));

  Future<bool> delete(String id) async {
    try {
      await _deleteConsumption(id);
    } on Exception {
      return false;
    }
    await _fetchSummary();
    return true;
  }

  Future<bool> _write(Future<void> Function() action, {required String errorText}) async {
    if (_state.isSubmitting) return false;
    _emit(_state.copyWith(isSubmitting: true, clearSubmitError: true));

    try {
      await action();
    } on ValidationFailure catch (failure) {
      _emit(_state.copyWith(isSubmitting: false, submitErrorMessage: failure.message));
      return false;
    } on Exception {
      _emit(_state.copyWith(isSubmitting: false, submitErrorMessage: errorText));
      return false;
    }

    _emit(_state.copyWith(isSubmitting: false));
    await _fetchSummary();
    return true;
  }

  Future<void> _fetchSummary() async {
    final previous = _state.summary;
    try {
      final summary = await _getDailySummary(_clock());
      _emit(_state.copyWith(loadStatus: _statusFor(summary), summary: summary, clearLoadError: true));
      await _alertIfNeeded(previous, summary);
    } on Exception {
      _emit(_state.copyWith(loadStatus: LoadStatus.error, loadErrorMessage: loadErrorText));
    }
  }

  Future<void> _alertIfNeeded(DailyNutrition? previous, DailyNutrition current) async {
    try {
      await _sendSodiumAlert?.call(previous: previous, current: current);
    } catch (_) {
      // Notifikasi bersifat tambahan; kegagalannya tidak boleh mengganggu pencatatan.
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
