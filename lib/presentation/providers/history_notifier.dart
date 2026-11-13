import '../../domain/usecases/get_consumption_history.dart';
import 'add_consumption_state.dart';
import 'base_notifier.dart';
import 'history_state.dart';

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier({required GetConsumptionHistory getConsumptionHistory})
      : _getConsumptionHistory = getConsumptionHistory,
        super(const HistoryState());

  static const String loadErrorText = 'Riwayat tidak dapat dimuat.';

  final GetConsumptionHistory _getConsumptionHistory;

  Future<void> load() async {
    emit(const HistoryState());
    try {
      final days = await _getConsumptionHistory();
      emit(HistoryState(status: days.isEmpty ? LoadStatus.empty : LoadStatus.success, days: days));
    } on Exception {
      emit(const HistoryState(status: LoadStatus.error, errorMessage: loadErrorText));
    }
  }
}
