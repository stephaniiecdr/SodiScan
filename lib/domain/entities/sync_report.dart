import 'food_consumption.dart';

/// Hasil "Kirim ke Server": berapa yang berhasil dan catatan mana yang gagal.
class UploadReport {
  const UploadReport({required this.total, this.failed = const []});

  final int total;
  final List<FoodConsumption> failed;

  int get successCount => total - failed.length;

  bool get hasFailures => failed.isNotEmpty;
}
