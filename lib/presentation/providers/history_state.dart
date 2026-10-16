import '../../domain/entities/daily_nutrition.dart';
import 'add_consumption_state.dart';

class HistoryState {
  const HistoryState({this.status = LoadStatus.loading, this.days = const [], this.errorMessage});

  final LoadStatus status;
  final List<DailyNutrition> days;
  final String? errorMessage;
}
