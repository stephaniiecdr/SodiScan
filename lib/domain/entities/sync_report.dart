import 'food_consumption.dart';

/// Hasil "Kirim ke Server": berapa yang berhasil dan catatan mana yang gagal.
class UploadReport {
  const UploadReport({required this.total, this.failed = const []});

  final int total;
  final List<FoodConsumption> failed;

  int get successCount => total - failed.length;

  bool get hasFailures => failed.isNotEmpty;
}

/// Hasil "Ambil ke HP": catatan baru, catatan yang diperbarui, dan catatan lokal
/// yang dipertahankan karena lebih baru.
class RestoreReport {
  const RestoreReport({this.added = 0, this.updated = 0, this.keptLocal = 0});

  final int added;
  final int updated;
  final int keptLocal;

  int get savedCount => added + updated;
}
