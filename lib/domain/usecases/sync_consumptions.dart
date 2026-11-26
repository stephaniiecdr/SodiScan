import '../entities/food_consumption.dart';
import '../entities/sync_report.dart';
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

  /// Mengirim semua catatan lokal. Kegagalan satu catatan tidak menghentikan
  /// catatan berikutnya. Jika semua gagal, error pertama dilempar ulang agar UI
  /// dapat menampilkan penyebabnya (misalnya server mati).
  Future<UploadReport> call() async {
    final items = await _localRepository.getAllConsumptions();
    final failed = <FoodConsumption>[];
    Exception? firstError;

    for (final item in items) {
      try {
        await _syncRepository.uploadToServer(item);
      } on Exception catch (error) {
        failed.add(item);
        firstError ??= error;
      }
    }
    if (items.isNotEmpty && failed.length == items.length) throw firstError!;
    return UploadReport(total: items.length, failed: failed);
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
