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
    final deletedIds = await _localRepository.getDeletedIds();
    final items = await _localRepository.getAllConsumptions();
    final failed = <FoodConsumption>[];
    var deleted = 0;
    var failedDeletes = 0;
    Exception? firstError;

    for (final id in deletedIds) {
      try {
        await _syncRepository.deleteFromServer(id);
        await _localRepository.forgetDeleted(id);
        deleted++;
      } on Exception catch (error) {
        failedDeletes++;
        firstError ??= error;
      }
    }

    for (final item in items) {
      try {
        await _syncRepository.uploadToServer(item);
      } on Exception catch (error) {
        failed.add(item);
        firstError ??= error;
      }
    }
    final operations = items.length + deletedIds.length;
    if (operations > 0 && failed.length + failedDeletes == operations) throw firstError!;
    return UploadReport(total: items.length, failed: failed, deleted: deleted, failedDeletes: failedDeletes);
  }
}

class RestoreConsumptions {
  const RestoreConsumptions(this._syncRepository, this._localRepository);

  final ConsumptionSyncRepository _syncRepository;
  final ConsumptionRepository _localRepository;

  /// Kebijakan konflik: last-modified-wins. Catatan lokal yang diubah lebih
  /// baru daripada versi server tidak ditimpa. Catatan yang sudah dihapus di
  /// perangkat (tombstone) tidak dikembalikan.
  Future<RestoreReport> call() async {
    final serverItems = await _syncRepository.fetchFromServer();
    final localById = {for (final item in await _localRepository.getAllConsumptions()) item.id: item};
    final deletedIds = await _localRepository.getDeletedIds();
    var added = 0;
    var updated = 0;
    var keptLocal = 0;
    var skippedDeleted = 0;
    for (final item in serverItems) {
      final local = localById[item.id];
      if (deletedIds.contains(item.id)) {
        skippedDeleted++;
      } else if (local == null) {
        await _localRepository.saveConsumption(item);
        added++;
      } else if (local.lastModifiedAt.isAfter(item.lastModifiedAt)) {
        keptLocal++;
      } else {
        await _localRepository.updateConsumption(item);
        updated++;
      }
    }
    return RestoreReport(added: added, updated: updated, keptLocal: keptLocal, skippedDeleted: skippedDeleted);
  }
}
