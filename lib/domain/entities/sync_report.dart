import 'food_consumption.dart';

/// Hasil "Kirim ke Server": berapa yang berhasil, catatan mana yang gagal, dan
/// berapa penghapusan lokal yang ikut diterapkan di server.
class UploadReport {
  const UploadReport({required this.total, this.failed = const [], this.deleted = 0, this.failedDeletes = 0});

  final int total;
  final List<FoodConsumption> failed;
  final int deleted;
  final int failedDeletes;

  int get successCount => total - failed.length;

  bool get hasFailures => failed.isNotEmpty || failedDeletes > 0;
}

/// Hasil "Ambil ke HP": catatan baru, catatan yang diperbarui, catatan lokal yang
/// dipertahankan karena lebih baru, dan catatan yang tidak dikembalikan karena
/// sudah dihapus di perangkat.
class RestoreReport {
  const RestoreReport({this.added = 0, this.updated = 0, this.keptLocal = 0, this.skippedDeleted = 0});

  final int added;
  final int updated;
  final int keptLocal;
  final int skippedDeleted;

  int get savedCount => added + updated;
}
