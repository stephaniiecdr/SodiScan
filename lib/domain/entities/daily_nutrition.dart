import '../../core/constants/sodium_constants.dart';
import 'food_consumption.dart';
import 'risk_status.dart';

class DailyNutrition {
  const DailyNutrition({
    required this.date,
    required this.totalSodiumMg,
    required this.dailyLimitMg,
    required this.riskStatus,
    required this.consumptions,
  });

  factory DailyNutrition.fromConsumptions(DateTime date, List<FoodConsumption> consumptions) {
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

  final DateTime date;
  final double totalSodiumMg;
  final double dailyLimitMg;
  final RiskStatus riskStatus;
  final List<FoodConsumption> consumptions;
}
