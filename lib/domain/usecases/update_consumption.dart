import '../entities/food_consumption.dart';
import '../repositories/consumption_repository.dart';
import '../validation/consumption_rules.dart';

class UpdateConsumption {
  UpdateConsumption(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ConsumptionRepository _repository;
  final DateTime Function() _clock;

  Future<FoodConsumption> call(
    FoodConsumption original, {
    required String productName,
    required double sodiumMg,
  }) async {
    final name = validateConsumptionInput(productName: productName, sodiumMg: sodiumMg);
    final updated = original.copyWith(productName: name, sodiumMg: sodiumMg, updatedAt: _clock());
    await _repository.updateConsumption(updated);
    return updated;
  }
}
