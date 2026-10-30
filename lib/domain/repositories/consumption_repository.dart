import '../entities/food_consumption.dart';

abstract class ConsumptionRepository {
  Future<List<FoodConsumption>> getConsumptionsByDate(DateTime date);

  Future<List<FoodConsumption>> getAllConsumptions();

  Future<void> saveConsumption(FoodConsumption consumption);

  Future<void> updateConsumption(FoodConsumption consumption);

  Future<void> deleteConsumption(String id);
}
