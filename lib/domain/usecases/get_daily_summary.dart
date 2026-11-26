import '../entities/daily_nutrition.dart';
import '../repositories/consumption_repository.dart';
import '../repositories/settings_repository.dart';
import 'load_daily_limit.dart';

class GetDailySummary {
  const GetDailySummary(this._repository, {SettingsRepository? settingsRepository})
      : _settingsRepository = settingsRepository;

  final ConsumptionRepository _repository;
  final SettingsRepository? _settingsRepository;

  Future<DailyNutrition> call(DateTime date) async {
    final consumptions = await _repository.getConsumptionsByDate(date);
    final limit = await loadDailyLimit(_settingsRepository);
    return DailyNutrition.fromConsumptions(date, consumptions, dailyLimitMg: limit);
  }
}
