import '../entities/daily_nutrition.dart';
import '../entities/food_consumption.dart';
import '../repositories/consumption_repository.dart';
import '../repositories/settings_repository.dart';
import 'load_daily_limit.dart';

class GetConsumptionHistory {
  const GetConsumptionHistory(this._repository, {SettingsRepository? settingsRepository})
      : _settingsRepository = settingsRepository;

  final ConsumptionRepository _repository;
  final SettingsRepository? _settingsRepository;

  Future<List<DailyNutrition>> call() async {
    final consumptions = await _repository.getAllConsumptions();
    final limit = await loadDailyLimit(_settingsRepository);
    final byDate = <DateTime, List<FoodConsumption>>{};
    for (final item in consumptions) {
      final local = item.consumedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      byDate.putIfAbsent(day, () => []).add(item);
    }

    final days = byDate.entries
        .map((entry) => DailyNutrition.fromConsumptions(entry.key, entry.value, dailyLimitMg: limit))
        .toList();
    return days..sort((a, b) => b.date.compareTo(a.date));
  }
}
