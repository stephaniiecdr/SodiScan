import '../repositories/consumption_repository.dart';

class DeleteConsumption {
  const DeleteConsumption(this._repository);

  final ConsumptionRepository _repository;

  Future<void> call(String id) => _repository.deleteConsumption(id);
}
