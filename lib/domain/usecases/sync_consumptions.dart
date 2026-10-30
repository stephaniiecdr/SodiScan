import '../entities/food_consumption.dart';
import '../repositories/consumption_repository.dart';
import '../repositories/consumption_sync_repository.dart';

class GetServerConsumptions {
  const GetServerConsumptions(this._syncRepository);

  final ConsumptionSyncRepository _syncRepository;

  Future<List<FoodConsumption>> call() async {
    final items = await _syncRepository.fetchFromServer();
    return items..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
  }
}

class UploadConsumptions {
  const UploadConsumptions(this._localRepository, this._syncRepository);

  final ConsumptionRepository _localRepository;
  final ConsumptionSyncRepository _syncRepository;

  Future<int> call() async {
    final items = await _localRepository.getAllConsumptions();
    for (final item in items) {
      await _syncRepository.uploadToServer(item);
    }
    return items.length;
  }
}

class RestoreConsumptions {
  const RestoreConsumptions(this._syncRepository, this._localRepository);

  final ConsumptionSyncRepository _syncRepository;
  final ConsumptionRepository _localRepository;

  Future<int> call() async {
    final serverItems = await _syncRepository.fetchFromServer();
    final localIds = (await _localRepository.getAllConsumptions()).map((item) => item.id).toSet();
    for (final item in serverItems) {
      if (localIds.contains(item.id)) {
        await _localRepository.updateConsumption(item);
      } else {
        await _localRepository.saveConsumption(item);
      }
    }
    return serverItems.length;
  }
}
