import '../entities/food_consumption.dart';

abstract class ConsumptionSyncRepository {
  Future<List<FoodConsumption>> fetchFromServer();

  Future<void> uploadToServer(FoodConsumption consumption);

  /// Menghapus catatan di server. Catatan yang sudah tidak ada di server dianggap berhasil.
  Future<void> deleteFromServer(String id);
}
