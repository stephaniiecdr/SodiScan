import '../entities/food_consumption.dart';

abstract class ConsumptionSyncRepository {
  Future<List<FoodConsumption>> fetchFromServer();

  Future<void> uploadToServer(FoodConsumption consumption);
}
