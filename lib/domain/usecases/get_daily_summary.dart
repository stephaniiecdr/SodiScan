import '../entities/daily_nutrition.dart';
import '../repositories/consumption_repository.dart';

class GetDailySummary {
  const GetDailySummary(this._repository);

  final ConsumptionRepository _repository;

  Future<DailyNutrition> call(DateTime date) async {
    final consumptions = await _repository.getConsumptionsByDate(date);
    return DailyNutrition.fromConsumptions(date, consumptions);
  }
}
