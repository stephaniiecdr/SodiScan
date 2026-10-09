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

  final DateTime date;
  final double totalSodiumMg;
  final double dailyLimitMg;
  final RiskStatus riskStatus;
  final List<FoodConsumption> consumptions;
}
