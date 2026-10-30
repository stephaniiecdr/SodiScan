import '../../core/constants/sodium_constants.dart';
import '../../core/errors/failures.dart';
import '../entities/food_consumption.dart';
import '../repositories/consumption_repository.dart';

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

String validateConsumptionInput({required String productName, required double sodiumMg}) {
  final name = productName.trim();
  if (name.isEmpty) {
    throw const ValidationFailure('Nama makanan wajib diisi.');
  }
  if (!sodiumMg.isFinite || sodiumMg <= 0) {
    throw const ValidationFailure('Jumlah sodium harus lebih dari 0.');
  }
  if (sodiumMg > maxSodiumPerEntryMg) {
    throw const ValidationFailure('Jumlah sodium maksimal 10000 mg per catatan.');
  }
  return name;
}
