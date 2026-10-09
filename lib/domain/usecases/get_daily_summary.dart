import '../../core/constants/sodium_constants.dart';
import '../entities/daily_nutrition.dart';
import '../entities/risk_status.dart';
import '../repositories/consumption_repository.dart';

class GetDailySummary {
  const GetDailySummary(this._repository);

  final ConsumptionRepository _repository;

  Future<DailyNutrition> call(DateTime date) async {
    final consumptions = await _repository.getConsumptionsByDate(date);
    final sorted = [...consumptions]..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
    final total = sorted.fold<double>(0, (sum, item) => sum + item.sodiumMg);

    return DailyNutrition(
      date: DateTime(date.year, date.month, date.day),
      totalSodiumMg: total,
      dailyLimitMg: dailySodiumLimitMg,
      riskStatus: RiskStatus.fromTotal(total),
      consumptions: sorted,
    );
  }
}
