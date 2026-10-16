import '../entities/daily_nutrition.dart';
import '../entities/food_consumption.dart';
import '../repositories/consumption_repository.dart';

class GetConsumptionHistory {
  const GetConsumptionHistory(this._repository);

  final ConsumptionRepository _repository;

  Future<List<DailyNutrition>> call() async {
    final consumptions = await _repository.getAllConsumptions();
    final byDate = <DateTime, List<FoodConsumption>>{};
    for (final item in consumptions) {
      final day = DateTime(item.consumedAt.year, item.consumedAt.month, item.consumedAt.day);
      byDate.putIfAbsent(day, () => []).add(item);
    }

    final days = byDate.entries.map((entry) => DailyNutrition.fromConsumptions(entry.key, entry.value)).toList();
    return days..sort((a, b) => b.date.compareTo(a.date));
  }
}
