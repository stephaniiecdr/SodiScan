import '../../core/errors/failures.dart';
import '../entities/food_consumption.dart';
import '../entities/product.dart';
import '../repositories/consumption_repository.dart';
import '../repositories/product_repository.dart';
import '../validation/product_rules.dart';

/// Mencari produk berdasarkan barcode.
///
/// Urutan pencarian:
/// 1. Catatan Input Manual di perangkat yang menyimpan barcode yang sama ("ingat produk"),
///    sehingga produk yang tidak ada di Open Food Facts tetap dikenali saat dipindai ulang, juga saat offline.
/// 2. Open Food Facts melalui [ProductRepository].
class GetProductByBarcode {
  const GetProductByBarcode(this._repository, {ConsumptionRepository? history}) : _history = history;

  final ProductRepository _repository;
  final ConsumptionRepository? _history;

  Future<Product?> call(String barcode) {
    final code = barcode.trim();
    if (!isValidBarcode(code)) {
      throw const ValidationFailure('Kode barcode harus 8 sampai 13 digit angka.');
    }
    final history = _history;
    if (history == null) return _repository.getProductByBarcode(code);
    return _lookupWithHistory(code, history);
  }

  Future<Product?> _lookupWithHistory(String code, ConsumptionRepository history) async {
    return await _findInHistory(code, history) ?? await _repository.getProductByBarcode(code);
  }

  /// Hanya catatan Input Manual yang dipakai, karena nilai natriumnya diisi pengguna untuk satu porsi.
  /// Catatan hasil scan menyimpan total natrium untuk jumlah porsi tertentu, jadi tidak bisa dipakai sebagai acuan.
  Future<Product?> _findInHistory(String barcode, ConsumptionRepository history) async {
    final List<FoodConsumption> all;
    try {
      all = await history.getAllConsumptions();
    } on Exception {
      return null; // Penyimpanan lokal bermasalah: tetap lanjut ke Open Food Facts.
    }

    FoodConsumption? latest;
    for (final item in all) {
      if (item.barcode != barcode || item.source != ConsumptionSource.manual) continue;
      if (latest == null || item.lastModifiedAt.isAfter(latest.lastModifiedAt)) latest = item;
    }
    if (latest == null) return null;

    return Product(
      barcode: barcode,
      name: latest.productName,
      servingSize: '1 porsi',
      sodiumPerServingMg: latest.sodiumMg,
      isFromHistory: true,
    );
  }
}
