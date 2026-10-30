import 'package:flutter/foundation.dart';

import '../../domain/usecases/get_consumption_history.dart';
import 'add_consumption_state.dart';
import 'history_state.dart';

class HistoryNotifier extends ChangeNotifier {
  HistoryNotifier({required GetConsumptionHistory getConsumptionHistory})
      : _getConsumptionHistory = getConsumptionHistory;

  static const String loadErrorText = 'Riwayat tidak dapat dimuat.';

  final GetConsumptionHistory _getConsumptionHistory;

  HistoryState _state = const HistoryState();
  bool _isDisposed = false;

  HistoryState get state => _state;

  Future<void> load() async {
    _emit(const HistoryState());
    try {
      final days = await _getConsumptionHistory();
      _emit(HistoryState(status: days.isEmpty ? LoadStatus.empty : LoadStatus.success, days: days));
    } on Exception {
      _emit(const HistoryState(status: LoadStatus.error, errorMessage: loadErrorText));
    }
  }

  void _emit(HistoryState newState) {
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
