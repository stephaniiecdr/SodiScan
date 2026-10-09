import '../entities/food_consumption.dart';

abstract class ConsumptionRepository {
  Future<List<FoodConsumption>> getConsumptionsByDate(DateTime date);

  Future<void> saveConsumption(FoodConsumption consumption);
}
