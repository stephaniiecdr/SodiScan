import '../../core/errors/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../validation/product_rules.dart';

class GetProductByBarcode {
  const GetProductByBarcode(this._repository);

  final ProductRepository _repository;

  Future<Product?> call(String barcode) {
    final code = barcode.trim();
    if (!isValidBarcode(code)) {
      throw const ValidationFailure('Kode barcode harus 8 sampai 13 digit angka.');
    }
    return _repository.getProductByBarcode(code);
  }
}
