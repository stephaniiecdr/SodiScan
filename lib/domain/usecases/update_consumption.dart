import '../entities/food_consumption.dart';
import '../repositories/consumption_repository.dart';
import 'record_consumption.dart';

class UpdateConsumption {
  const UpdateConsumption(this._repository);

  final ConsumptionRepository _repository;

  Future<FoodConsumption> call(
    FoodConsumption original, {
    required String productName,
    required double sodiumMg,
  }) async {
    final name = validateConsumptionInput(productName: productName, sodiumMg: sodiumMg);
    final updated = original.copyWith(productName: name, sodiumMg: sodiumMg);
    await _repository.updateConsumption(updated);
    return updated;
  }
}
