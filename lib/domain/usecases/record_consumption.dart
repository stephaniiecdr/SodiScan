import '../entities/food_consumption.dart';
import '../repositories/consumption_repository.dart';
import '../validation/consumption_rules.dart';

class RecordConsumption {
  RecordConsumption(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ConsumptionRepository _repository;
  final DateTime Function() _clock;

  Future<FoodConsumption> call({
    required String productName,
    required double sodiumMg,
    ConsumptionSource source = ConsumptionSource.manual,
    String? barcode,
  }) async {
    final name = validateConsumptionInput(productName: productName, sodiumMg: sodiumMg);

    final now = _clock();
    final consumption = FoodConsumption(
      id: now.microsecondsSinceEpoch.toString(),
      barcode: barcode,
      productName: name,
      sodiumMg: sodiumMg,
      source: source,
      consumedAt: now,
    );
    await _repository.saveConsumption(consumption);
    return consumption;
  }
}
