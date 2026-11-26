import '../entities/food_consumption.dart';

abstract class ConsumptionRepository {
  Future<List<FoodConsumption>> getConsumptionsByDate(DateTime date);

  Future<List<FoodConsumption>> getAllConsumptions();

  Future<void> saveConsumption(FoodConsumption consumption);

  Future<void> updateConsumption(FoodConsumption consumption);

  /// Menghapus catatan dan mengingat id-nya (tombstone) agar penghapusan bisa
  /// dikirim ke server dan catatan tidak dikembalikan saat "Ambil ke HP".
  Future<void> deleteConsumption(String id);

  /// Id catatan yang dihapus di perangkat tetapi belum dihapus di server.
  Future<Set<String>> getDeletedIds();

  /// Dipanggil setelah penghapusan berhasil dikirim ke server.
  Future<void> forgetDeleted(String id);
}
